// lib/features/budgets/presentation/providers/budget_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart' show Printing;
import 'package:uuid/uuid.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/client.dart';
import '../../domain/usecases/create_budget.dart';
import '../../../products/domain/entities/product.dart';
import '../../data/models/client_model.dart';
import '../utils/pdf_generator.dart';
import '../utils/amortization_calculator.dart';
import '../utils/financing_schedule.dart';
import 'dart:typed_data';

class BudgetProvider with ChangeNotifier {
  Client? _client;
  String? _clientId;
  String? _selectedClientId;
  Product? _product;
  String? _error;
  String? _currency;
  double? _price;
  String? _paymentMethod;
  String? _financingType;
  double? _delivery;
  String? _paymentFrequency;
  int? _numberOfInstallments;
  bool? _hasReinforcements;
  String? _reinforcementFrequency;
  int? _numberOfReinforcements;
  double? _reinforcementAmount;
  String? _reinforcementMonth;
  int? _reinforcementYear;
  String? _validityOffer;
  String? _commercialConditions;
  String? _benefits;
  double? _lifeInsuranceAmount;
  double? _deliveryVehicle;
  List<Map<String, dynamic>>? _amortizationSchedule;
  List<ClientModel> _clients = [];

  // --- CAMBIO: Campos de Descuento ---
  bool _hasDiscount = false;
  double? _realPrice;
  double? _discountPercentage;

  Client? get client => _client;
  String? get clientId => _clientId;
  Product? get product => _product;
  String? get error => _error;
  String? get currency => _currency;
  double? get price => _price;
  String? get paymentMethod => _paymentMethod;
  String? get financingType => _financingType;
  double? get delivery => _delivery;
  String? get paymentFrequency => _paymentFrequency;
  int? get numberOfInstallments => _numberOfInstallments;
  bool? get hasReinforcements => _hasReinforcements;
  String? get reinforcementFrequency => _reinforcementFrequency;
  int? get numberOfReinforcements => _numberOfReinforcements;
  double? get reinforcementAmount => _reinforcementAmount;
  String? get reinforcementMonth => _reinforcementMonth;
  String? get validityOffer => _validityOffer;
  String? get commercialConditions => _commercialConditions;
  String? get benefits => _benefits;
  double? get lifeInsuranceAmount => _lifeInsuranceAmount;
  double? get lifeInsurancePercentage =>
      _lifeInsuranceAmount == null ? null : _lifeInsuranceRate;
  double? get deliveryVehicle => _deliveryVehicle;
  List<Map<String, dynamic>>? get amortizationSchedule => _amortizationSchedule;
  List<ClientModel> get clients => _clients;

  // Tope de descuento definido por el administrador (config/descuentos).
  // null mientras no se cargó o si el admin no lo definió.
  double? _maxDiscountPercentage;
  bool _isLoadingDiscountConfig = false;
  double? get maxDiscountPercentage => _maxDiscountPercentage;
  bool get isLoadingDiscountConfig => _isLoadingDiscountConfig;

  // --- CAMBIO: Getters de Descuento ---
  bool get hasDiscount => _hasDiscount;
  double? get realPrice => _realPrice;
  double? get discountPercentage => _discountPercentage;

  final CreateBudget _createBudget;
  final PdfGenerator _pdfGenerator;

  BudgetProvider({
    required CreateBudget createBudget,
    PdfGenerator? pdfGenerator,
  })  : _createBudget = createBudget,
        _pdfGenerator = pdfGenerator ?? PdfGenerator();

  Future<void> loadClientsByVendor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'Usuario no autenticado.';
      notifyListeners();
      return;
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .where('createdBy', isEqualTo: user.uid)
          .get();
      _clients = querySnapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
          .toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar clientes: $e';
    }
    notifyListeners();
  }

  // 10.0 -> "10", 4.5 -> "4,5"
  static String _formatPercent(double value) =>
      (value == value.roundToDouble() ? value.toInt().toString() : '$value')
          .replaceAll('.', ',');

  Future<void> loadDiscountConfig() async {
    // Sin notifyListeners aquí: se llama desde initState del formulario
    _isLoadingDiscountConfig = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('descuentos')
          .get();
      final value = doc.data()?['max_discount_percentage'];
      _maxDiscountPercentage = value is num ? value.toDouble() : null;
    } catch (e) {
      debugPrint('[BudgetProvider] Error al cargar el descuento máximo: $e');
      _maxDiscountPercentage = null;
    } finally {
      _isLoadingDiscountConfig = false;
      notifyListeners();
    }
  }

  // Tasa de descuento bancaria anual, en % (campo `interes` de la colección
  // `interes` del admin, texto con coma decimal: "9,5"), y margen para cargos
  // bancarios en % (campo `margen_cargos`). Si no están cargados o no son
  // válidos se usan 9,5% (Sudameris, el banco más caro) y 2%.
  static const double _defaultAnnualInterestRate = 9.5;
  static const double _defaultMarginPercentage = 2;
  double _annualInterestRate = _defaultAnnualInterestRate;
  double _marginPercentage = _defaultMarginPercentage;
  double get annualInterestRate => _annualInterestRate;
  double get marginPercentage => _marginPercentage;

  // Seguro de vida: solo Persona Física y solo Financiado. Se activa y se fija
  // el porcentaje desde el admin (campos `seguro_vida_activo` y
  // `seguro_vida_porcentaje` de la colección `interes`). Se calcula sobre el
  // saldo a financiar y se suma a ese saldo. Si no está cargado, no se cobra.
  static const String lifeInsuranceClientType = 'Persona Física';
  bool _lifeInsuranceEnabled = false;
  double _lifeInsuranceRate = 0;
  bool get lifeInsuranceEnabled => _lifeInsuranceEnabled;
  double get lifeInsuranceRate => _lifeInsuranceRate;

  /// Monto del seguro de vida para un saldo y tipo de cliente, o null si no
  /// corresponde (inactivo, 0%, persona jurídica o saldo no positivo).
  double? lifeInsuranceFor({required String? clientType, required double balance}) {
    if (!_lifeInsuranceEnabled ||
        _lifeInsuranceRate <= 0 ||
        clientType != lifeInsuranceClientType ||
        balance <= 0) {
      return null;
    }
    return (balance * _lifeInsuranceRate / 100 * 100).roundToDouble() / 100;
  }

  static double? _parsePercent(Object? raw) {
    final value = raw is num
        ? raw.toDouble()
        : double.tryParse('${raw ?? ''}'.trim().replaceAll(',', '.'));
    return value != null && value >= 0 && value < 100 ? value : null;
  }

  Future<void> loadInterestRate() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('interes').limit(1).get();
      final data = snapshot.docs.isEmpty ? null : snapshot.docs.first.data();
      _annualInterestRate =
          _parsePercent(data?['interes']) ?? _defaultAnnualInterestRate;
      _marginPercentage =
          _parsePercent(data?['margen_cargos']) ?? _defaultMarginPercentage;
      _lifeInsuranceEnabled = data?['seguro_vida_activo'] == true;
      _lifeInsuranceRate = _parsePercent(data?['seguro_vida_porcentaje']) ?? 0;
    } catch (e) {
      debugPrint('[BudgetProvider] Error al cargar el interés: $e');
      _annualInterestRate = _defaultAnnualInterestRate;
      _marginPercentage = _defaultMarginPercentage;
      _lifeInsuranceEnabled = false;
      _lifeInsuranceRate = 0;
    }
    notifyListeners();
  }

  void updateClient({
    required String razonSocial,
    required String ruc,
    String? email,
    String? telefono,
    String? ciudad,
    String? departamento,
    String? clientType,
    String? selectedClientId,
  }) {
    if (razonSocial.isEmpty || ruc.isEmpty) {
      _error = 'Razón Social y RUC son obligatorios.';
      notifyListeners();
      return;
    }
    _client = Client(
      razonSocial: razonSocial,
      ruc: ruc,
      email: email,
      telefono: telefono,
      ciudad: ciudad,
      departamento: departamento,
      clientType: clientType,
    );
    _selectedClientId = selectedClientId;
    _error = null;
    notifyListeners();
  }

  void updateProduct(Product product) {
    _product = product;
    _price = product.price;
    _currency = product.currency;
    notifyListeners();
  }

  Future<void> updatePaymentDetails({
    required String currency,
    required double price,
    required String paymentMethod,
    String? financingType,
    double? delivery,
    String? paymentFrequency,
    int? numberOfInstallments,
    bool? hasReinforcements,
    String? reinforcementFrequency,
    int? numberOfReinforcements,
    double? reinforcementAmount,
    String? reinforcementMonth,
    int? reinforcementYear,
    // Número de cuota en la que cae el primer refuerzo
    int? firstReinforcementInstallment,
    String? validityOffer,
    String? commercialConditions,
    String? benefits,
    double? deliveryVehicle,
    // --- CAMBIO: Parámetros de Descuento ---
    bool? hasDiscount,
    double? realPrice,
    double? discountPercentage,
  }) async {
    _currency = currency;
    _price = price;
    _paymentMethod = paymentMethod;
    _financingType = financingType;
    _delivery = delivery;
    _paymentFrequency = paymentFrequency;
    _numberOfInstallments = numberOfInstallments;
    _hasReinforcements = hasReinforcements;
    _reinforcementFrequency = reinforcementFrequency;
    _numberOfReinforcements = numberOfReinforcements;
    _reinforcementAmount = reinforcementAmount;
    _reinforcementMonth = reinforcementMonth;
    _reinforcementYear = reinforcementYear;
    _validityOffer = validityOffer;
    _commercialConditions = commercialConditions;
    _benefits = benefits;
    _deliveryVehicle = deliveryVehicle;
    _error = null;

    // --- CAMBIO: Asignación de Descuento ---
    _hasDiscount = hasDiscount ?? false;
    _realPrice = realPrice;
    _discountPercentage = discountPercentage;

    // El descuento nunca puede superar el tope del administrador
    if (_hasDiscount &&
        (discountPercentage == null ||
            _maxDiscountPercentage == null ||
            discountPercentage <= 0 ||
            discountPercentage > _maxDiscountPercentage!)) {
      _error = _maxDiscountPercentage == null
          ? 'El descuento no está habilitado por el administrador.'
          : 'Seleccione un descuento de hasta ${_formatPercent(_maxDiscountPercentage!)}%.';
      notifyListeners();
      return;
    }

    // Seguro de vida: se calcula más abajo, solo si es Financiado
    _lifeInsuranceAmount = null;

    if (paymentMethod == 'Financiado') {
      final planError = FinancingSchedule.validate(
        price: price,
        totalDelivery: (delivery ?? 0.0) + (deliveryVehicle ?? 0.0),
        numberOfInstallments: numberOfInstallments,
        paymentFrequency: paymentFrequency,
        hasReinforcements: hasReinforcements == true,
        reinforcementFrequency: reinforcementFrequency,
        firstInstallment: firstReinforcementInstallment,
        numberOfReinforcements: numberOfReinforcements,
        reinforcementAmount: reinforcementAmount,
      );
      if (planError != null) {
        _error = planError;
        notifyListeners();
        return;
      }
    }

    if (paymentMethod == 'Financiado' && numberOfInstallments != null) {
      final double balance =
          price - (delivery ?? 0.0) - (deliveryVehicle ?? 0.0);
      // Persona Física: el seguro de vida se suma al saldo a financiar
      _lifeInsuranceAmount =
          lifeInsuranceFor(clientType: _client?.clientType, balance: balance);
      final double capitalToFinance = balance + (_lifeInsuranceAmount ?? 0.0);
      // Fecha valor: hoy, sin hora; las cuotas vencen el mismo día del mes
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);

      final termError = AmortizationCalculator.termError(
        start: start,
        dueDates: FinancingSchedule.dueDates(
            start, numberOfInstallments, paymentFrequency!),
        annualRate: _annualInterestRate,
      );
      if (termError != null) {
        _error = termError;
        _amortizationSchedule = null;
        notifyListeners();
        return;
      }

      // Refuerzos: el primero en la cuota elegida y los siguientes cada
      // período de refuerzo (ya validado arriba)
      final reinforcementsMap = hasReinforcements == true
          ? FinancingSchedule.reinforcements(
              paymentFrequency: paymentFrequency,
              reinforcementFrequency: reinforcementFrequency!,
              firstInstallment: firstReinforcementInstallment!,
              numberOfReinforcements: numberOfReinforcements!,
              amount: reinforcementAmount!,
            )
          : null;

      _amortizationSchedule =
          AmortizationCalculator.calculateBankDiscountSchedule(
        capital: capitalToFinance,
        start: start,
        numberOfInstallments: numberOfInstallments,
        annualRate: _annualInterestRate,
        marginPercentage: _marginPercentage,
        reinforcements: reinforcementsMap,
        paymentFrequency: paymentFrequency,
      );
    } else {
      _amortizationSchedule = null;
    }

    notifyListeners();
  }

  Future<void> createBudget() async {
    if (_client == null ||
        _product == null ||
        _currency == null ||
        _price == null ||
        _paymentMethod == null) {
      _error = 'Complete todos los campos obligatorios.';
      notifyListeners();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'Usuario no autenticado.';
      notifyListeners();
      return;
    }

    try {
      // El formulario ya no pide email, teléfono, departamento ni ciudad
      // (AMIN-05/06): solo se actualizan los campos que se cargan, para no
      // borrar los datos de contacto que ya tienen los clientes existentes.
      if (_selectedClientId != null) {
        _clientId = _selectedClientId;
        final clientDocRef =
            FirebaseFirestore.instance.collection('clients').doc(_clientId);
        await clientDocRef.update({
          'razonSocial': _client!.razonSocial,
          'ruc': _client!.ruc,
          'clientType': _client!.clientType,
        });
      } else {
        final rucQuery = await FirebaseFirestore.instance
            .collection('clients')
            .where('ruc', isEqualTo: _client!.ruc)
            .limit(1)
            .get();

        if (rucQuery.docs.isNotEmpty) {
          _clientId = rucQuery.docs.first.id;
          await FirebaseFirestore.instance
              .collection('clients')
              .doc(_clientId)
              .update({
            'razonSocial': _client!.razonSocial,
            'clientType': _client!.clientType,
          });
        } else {
          final newClientId = const Uuid().v4();
          final clientModel = ClientModel(
            id: newClientId,
            razonSocial: _client!.razonSocial,
            ruc: _client!.ruc,
            email: _client!.email,
            telefono: _client!.telefono,
            ciudad: _client!.ciudad,
            departamento: _client!.departamento,
            clientType: _client!.clientType,
            createdBy: user.uid,
          );
          await FirebaseFirestore.instance
              .collection('clients')
              .doc(newClientId)
              .set(clientModel.toMap());
          _clientId = newClientId;
        }
      }

      final budget = Budget(
        id: const Uuid().v4(),
        clientId: _clientId!,
        product: _product!,
        currency: _currency!,
        price: _price!,
        paymentMethod: _paymentMethod!,
        financingType: _financingType,
        delivery: _delivery,
        deliveryVehicle: _deliveryVehicle,
        paymentFrequency: _paymentFrequency,
        numberOfInstallments: _numberOfInstallments,
        hasReinforcements: _hasReinforcements,
        reinforcementFrequency: _reinforcementFrequency,
        numberOfReinforcements: _numberOfReinforcements,
        reinforcementAmount: _reinforcementAmount,
        validityOffer: _validityOffer,
        commercialConditions: _commercialConditions,
        benefits: _benefits,
        lifeInsuranceAmount: _lifeInsuranceAmount,
        createdBy: user.uid,
        createdAt: DateTime.now().toIso8601String(),
        // --- CAMBIO: Campos de Descuento ---
        hasDiscount: _hasDiscount,
        realPrice: _realPrice,
        discountPercentage: _discountPercentage,
      );

      await _createBudget(budget);
      _error = null;
      await loadClientsByVendor();
    } catch (e) {
      _error = 'Error al guardar el presupuesto: $e';
    }
    notifyListeners();
  }

  Future<ClientModel?> getClient(String clientId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .get();
      if (doc.exists) {
        return ClientModel.fromMap(doc.data()!, clientId);
      }
      return null;
    } catch (e) {
      _error = 'Error al obtener datos del cliente: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<Uint8List> generateBudgetPdf(BuildContext context) async {
    if (_clientId == null) {
      final errorMessage = 'No se ha seleccionado o creado un cliente.';
      _error = errorMessage;
      notifyListeners();
      throw Exception(errorMessage);
    }
    final client = await getClient(_clientId!);
    if (client == null) {
      final errorMessage = 'No se pudo cargar los datos del cliente.';
      _error = errorMessage;
      notifyListeners();
      throw Exception(errorMessage);
    }

    try {
      final pdfBytes = await _pdfGenerator.generateBudgetPdf(
        context: context,
        client: client,
        product: _product!,
        currency: _currency!,
        price: _price!,
        paymentMethod: _paymentMethod!,
        financingType: _financingType,
        delivery: _delivery,
        deliveryVehicle: _deliveryVehicle,
        paymentFrequency: _paymentFrequency,
        numberOfInstallments: _numberOfInstallments,
        hasReinforcements: _hasReinforcements,
        reinforcementFrequency: _reinforcementFrequency,
        numberOfReinforcements: _numberOfReinforcements,
        reinforcementAmount: _reinforcementAmount,
        reinforcementMonth: _reinforcementMonth,
        amortizationSchedule: _amortizationSchedule,
        validityOffer: _validityOffer,
        commercialConditions: _commercialConditions,
        benefits: _benefits,
        lifeInsuranceAmount: _lifeInsuranceAmount,
        lifeInsurancePercentage: lifeInsurancePercentage,
        // --- CAMBIO: Campos de Descuento ---
        hasDiscount: _hasDiscount,
        realPrice: _realPrice,
        discountPercentage: _discountPercentage,
      );
      _error = null;
      return pdfBytes;
    } catch (e) {
      _error = 'Error al generar el PDF: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveAndSharePdf(BuildContext context) async {
    try {
      final pdfBytes = await generateBudgetPdf(context);
      final client = await getClient(_clientId!);
      if (client == null) {
        _error = 'No se pudo cargar los datos del cliente.';
        notifyListeners();
        return;
      }
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'presupuesto_${client.razonSocial}_${DateTime.now().toIso8601String()}.pdf',
      );
      _error = null;
    } catch (e) {
      _error = 'Error al generar o compartir el PDF: $e';
      notifyListeners();
    }
  }

  void clear() {
    _client = null;
    _clientId = null;
    _selectedClientId = null;
    _product = null;
    _currency = null;
    _price = null;
    _paymentMethod = null;
    _financingType = null;
    _delivery = null;
    _deliveryVehicle = null;
    _paymentFrequency = null;
    _numberOfInstallments = null;
    _hasReinforcements = null;
    _reinforcementFrequency = null;
    _numberOfReinforcements = null;
    _reinforcementAmount = null;
    _reinforcementMonth = null;
    _reinforcementYear = null;
    _validityOffer = null;
    _commercialConditions = null;
    _benefits = null;
    _lifeInsuranceAmount = null;
    _amortizationSchedule = null;
    _clients = [];
    _error = null;

    // --- CAMBIO: Limpieza de Descuento ---
    _hasDiscount = false;
    _realPrice = null;
    _discountPercentage = null;

    notifyListeners();
  }
}
