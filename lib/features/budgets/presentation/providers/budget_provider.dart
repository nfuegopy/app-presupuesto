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
import 'dart:typed_data';
import 'dart:math';

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
  double? get deliveryVehicle => _deliveryVehicle;
  List<Map<String, dynamic>>? get amortizationSchedule => _amortizationSchedule;
  List<ClientModel> get clients => _clients;

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
    if (telefono == null || telefono.isEmpty) {
      _error = 'El número de teléfono es obligatorio.';
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

    // --- SEGURO DE VIDA DESACTIVADO ---
    _lifeInsuranceAmount =
        null; // Se establece a null para omitirlo del cálculo
    // --- FIN DE LA MODIFICACIÓN ---

    if (paymentMethod == 'Financiado' &&
        numberOfInstallments != null &&
        delivery != null) {
      // --- INICIO DE LA MODIFICACIÓN (Lógica Interés Compuesto Escalonado) ---

      // 1. Calcular Años de financiación
      int installmentsPerYear = 12;
      if (paymentFrequency == 'Trimestral') installmentsPerYear = 4;
      if (paymentFrequency == 'Semestral') installmentsPerYear = 2;
      double years = numberOfInstallments / installmentsPerYear;

      // 2. Definir la tasa (1.072)
      const double interestMultiplier = 1.072; // (1 + 0.072)

      // 3. Calcular Años CON Interés (El primer año es gratis)
      final double yearsWithInterest = (years > 1) ? (years - 1) : 0.0;

      // 4. Calcular capital a financiar
      double effectivePrice = price;
      double totalDelivery = (delivery ?? 0.0) + (deliveryVehicle ?? 0.0);
      double capitalToFinance = effectivePrice - totalDelivery;

      // 5. Calcular el Monto Total Financiado (Tasa Compuesta)
      double totalFinanciado =
          capitalToFinance * pow(interestMultiplier, yearsWithInterest);

      // 6. Calcular Coeficiente Total (CON PROTECCIÓN DIVISIÓN CERO)
      double financingCoefficient;
      if (capitalToFinance <= 0) {
        financingCoefficient = 1.0;
      } else {
        financingCoefficient = totalFinanciado / capitalToFinance;
      }

      // --- FIN DE LA MODIFICACIÓN ---

      // Lógica corregida para generar refuerzos alineados a las cuotas
      final reinforcementsMap = hasReinforcements == true &&
              numberOfReinforcements != null &&
              reinforcementAmount != null
          ? _generateReinforcements(
              numberOfReinforcements,
              reinforcementAmount,
              reinforcementFrequency!,
              paymentFrequency ?? 'Mensual', // Pasamos la frecuencia de pago
            )
          : null;

      debugPrint(
          '[BudgetProvider] Calculando amortización INTERÉS COMPUESTO (Calculada): '
          'capital a financiar=${capitalToFinance.toStringAsFixed(2)}, '
          '# de cuotas=$numberOfInstallments, '
          'Años Totales=${years.toStringAsFixed(1)}, '
          'Años CON Interés=${yearsWithInterest.toStringAsFixed(1)}, '
          'Coeficiente Total CALCULADO=${financingCoefficient.toStringAsFixed(4)}');

      _amortizationSchedule =
          AmortizationCalculator.calculateFlatRateAmortization(
        capital: capitalToFinance,
        numberOfInstallments: numberOfInstallments,
        coefficient: financingCoefficient,
        reinforcements: reinforcementsMap,
        paymentFrequency: paymentFrequency ?? 'Mensual',
      );
    } else {
      _amortizationSchedule = null;
    }

    notifyListeners();
  }

  // --- MÉTODO CORREGIDO PARA GENERAR REFUERZOS ---
  Map<int, double> _generateReinforcements(
    int numberOfReinforcements,
    double reinforcementAmount,
    String reinforcementFrequency,
    String paymentFrequency,
  ) {
    Map<int, double> reinforcements = {};

    // 1. Determinar intervalo de meses de la CUOTA (Divisor)
    int paymentInterval;
    switch (paymentFrequency) {
      case 'Trimestral':
        paymentInterval = 3;
        break;
      case 'Semestral':
        paymentInterval = 6;
        break;
      case 'Anual':
        paymentInterval = 12;
        break;
      default:
        paymentInterval = 1; // Mensual
    }

    // 2. Determinar intervalo de meses del REFUERZO (Multiplicador)
    int reinforcementInterval;
    switch (reinforcementFrequency) {
      case 'Trimestral':
        reinforcementInterval = 3;
        break;
      case 'Semestral':
        reinforcementInterval = 6;
        break;
      case 'Anual':
        reinforcementInterval = 12;
        break;
      default:
        reinforcementInterval = 12;
    }

    for (int i = 1; i <= numberOfReinforcements; i++) {
      // Mes absoluto donde cae el refuerzo (ej: Refuerzo anual 1 = Mes 12)
      int monthOfReinforcement = i * reinforcementInterval;

      // Calcular a qué número de CUOTA corresponde ese mes
      // Ejemplo: Mes 12 / Semestral (6) = Cuota #2
      if (monthOfReinforcement % paymentInterval == 0) {
        int installmentIndex = monthOfReinforcement ~/ paymentInterval;
        reinforcements[installmentIndex] = reinforcementAmount;
      } else {
        // Aquí podrías manejar el caso si un refuerzo cae en un mes donde no hay cuota
        // (Por ahora se omite si no coincide exactamente)
        debugPrint(
            '[BudgetProvider] ADVERTENCIA: Refuerzo en mes $monthOfReinforcement no coincide con frecuencia de pago $paymentFrequency');
      }
    }

    debugPrint(
        '[BudgetProvider] Refuerzos generados (Cuota -> Monto): $reinforcements');
    return reinforcements;
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
      if (_selectedClientId != null) {
        _clientId = _selectedClientId;
        final clientDocRef =
            FirebaseFirestore.instance.collection('clients').doc(_clientId);
        await clientDocRef.update({
          'razonSocial': _client!.razonSocial,
          'ruc': _client!.ruc,
          'email': _client!.email,
          'telefono': _client!.telefono,
          'ciudad': _client!.ciudad,
          'departamento': _client!.departamento,
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
            'email': _client!.email,
            'telefono': _client!.telefono,
            'ciudad': _client!.ciudad,
            'departamento': _client!.departamento,
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
