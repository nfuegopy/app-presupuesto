import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/client.dart';
import '../../domain/usecases/create_budget.dart';
import '../../../products/domain/entities/product.dart';
import '../../data/models/client_model.dart';
import '../utils/pdf_generator.dart';
import '../utils/amortization_calculator.dart';
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
  String? _validityOffer;
  String? _benefits;
  List<Map<String, dynamic>>? _amortizationSchedule;
  List<ClientModel> _clients = [];

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
  String? get benefits => _benefits;
  List<Map<String, dynamic>>? get amortizationSchedule => _amortizationSchedule;
  List<ClientModel> get clients => _clients;

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
    String? selectedClientId,
  }) {
    debugPrint(
        '[BudgetProvider] updateClient: razonSocial=$razonSocial, ruc=$ruc, selectedClientId=$selectedClientId');
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
      email: email != null && email.isNotEmpty ? email : null,
      telefono: telefono != null && telefono.isNotEmpty ? telefono : null,
      ciudad: ciudad != null && ciudad.isNotEmpty ? ciudad : null,
      departamento:
          departamento != null && departamento.isNotEmpty ? departamento : null,
    );
    _selectedClientId = selectedClientId;
    _error = null;
    notifyListeners();
  }

  void updateProduct(Product product) {
    debugPrint(
        '[BudgetProvider] updateProduct: name=${product.name}, price=${product.price}');
    _product = product;
    _price = product.price;
    _currency = product.currency;
    notifyListeners();
  }

  void updatePaymentDetails({
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
    String? validityOffer,
    String? benefits,
  }) {
    debugPrint('[BudgetProvider] updatePaymentDetails: '
        'currency=$currency, '
        'price=$price, '
        'capital=${price - (delivery ?? 0)}, '
        'delivery=$delivery, '
        'numberOfInstallments=$numberOfInstallments, '
        'paymentMethod=$paymentMethod, '
        'financingType=$financingType, '
        'paymentFrequency=$paymentFrequency, '
        'hasReinforcements=$hasReinforcements, '
        'reinforcementFrequency=$reinforcementFrequency, '
        'numberOfReinforcements=$numberOfReinforcements, '
        'reinforcementAmount=$reinforcementAmount, '
        'reinforcementMonth=$reinforcementMonth');

    if (price <= 0) {
      _error = 'El precio debe ser mayor a 0.';
      notifyListeners();
      return;
    }
    if (paymentMethod == 'Financiado') {
      if (financingType == null ||
          paymentFrequency == null ||
          numberOfInstallments == null) {
        _error = 'Complete todos los campos obligatorios para financiamiento.';
        notifyListeners();
        return;
      }
      if (financingType == 'Propia' && (delivery == null || delivery <= 0)) {
        _error = 'La entrega es obligatoria para financiación propia.';
        notifyListeners();
        return;
      }
      if (hasReinforcements == true &&
          (reinforcementFrequency == null ||
              numberOfReinforcements == null ||
              reinforcementAmount == null)) {
        _error = 'Complete los campos de refuerzos.';
        notifyListeners();
        return;
      }
      if (hasReinforcements == true &&
          reinforcementFrequency == 'Anual' &&
          reinforcementMonth == null) {
        _error = 'Seleccione el mes de abono anual.';
        notifyListeners();
        return;
      }
    }

    _currency = currency;
    _price = price;
    debugPrint('[BudgetProvider] Precio almacenado: $_price');
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
    _validityOffer = validityOffer;
    _benefits = benefits;
    _error = null;

    if (paymentMethod == 'Financiado' &&
        numberOfInstallments != null &&
        delivery != null) {
      double capital = price - delivery;

      debugPrint(
          '[BudgetProvider] Calculando amortización: capital=$capital, numberOfInstallments=$numberOfInstallments');

      _amortizationSchedule =
          AmortizationCalculator.calculateFrenchAmortization(
        capital: capital,
        numberOfInstallments: numberOfInstallments,
        reinforcements: hasReinforcements == true &&
                numberOfReinforcements != null &&
                reinforcementAmount != null
            ? _generateReinforcements(numberOfReinforcements,
                reinforcementAmount, reinforcementFrequency!)
            : null,
        reinforcementMonth: reinforcementMonth,
        paymentFrequency: paymentFrequency ?? 'Mensual',
        annualNominalRate: 0.095,
      );

      debugPrint(
          '[BudgetProvider] Amortización generada: ${_amortizationSchedule!.length} cuotas');
    } else {
      _amortizationSchedule = null;
    }

    notifyListeners();
  }

  Map<int, double> _generateReinforcements(int numberOfReinforcements,
      double reinforcementAmount, String frequency) {
    Map<int, double> reinforcements = {};
    int interval;
    switch (frequency) {
      case 'Trimestral':
        interval = 3;
        break;
      case 'Semestral':
        interval = 6;
        break;
      case 'Anual':
        interval = 12;
        break;
      default:
        interval = 3;
    }
    for (int i = 1; i <= numberOfReinforcements; i++) {
      reinforcements[i * interval] = reinforcementAmount;
    }
    debugPrint('[BudgetProvider] Refuerzos generados: $reinforcements');
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
      debugPrint(
          '[BudgetProvider] Creando presupuesto: clientId=$_clientId, product=${_product!.name}');
      if (_selectedClientId != null) {
        _clientId = _selectedClientId;
        final clientDocRef =
            FirebaseFirestore.instance.collection('clients').doc(_clientId);
        final clientSnapshot = await clientDocRef.get();
        if (clientSnapshot.exists) {
          final existingClientData =
              clientSnapshot.data() as Map<String, dynamic>;
          final updatedClientModel = ClientModel(
            id: _clientId!,
            razonSocial: _client!.razonSocial,
            ruc: _client!.ruc,
            email: _client!.email,
            telefono: _client!.telefono,
            ciudad: _client!.ciudad,
            departamento: _client!.departamento,
            createdBy: existingClientData['createdBy'],
          );
          await clientDocRef.update(updatedClientModel.toMap());
        }
      } else {
        final rucQuery = await FirebaseFirestore.instance
            .collection('clients')
            .where('ruc', isEqualTo: _client!.ruc)
            .limit(1)
            .get();

        if (rucQuery.docs.isNotEmpty) {
          final existingClientDoc = rucQuery.docs.first;
          _clientId = existingClientDoc.id;
          final existingClientData = existingClientDoc.data();

          final updatedClientModel = ClientModel(
            id: _clientId!,
            razonSocial: _client!.razonSocial,
            ruc: _client!.ruc,
            email: _client!.email,
            telefono: _client!.telefono,
            ciudad: _client!.ciudad,
            departamento: _client!.departamento,
            createdBy: existingClientData['createdBy'],
          );
          await FirebaseFirestore.instance
              .collection('clients')
              .doc(_clientId)
              .update(updatedClientModel.toMap());
          _error = null;
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
        paymentFrequency: _paymentFrequency,
        numberOfInstallments: _numberOfInstallments,
        hasReinforcements: _hasReinforcements,
        reinforcementFrequency: _reinforcementFrequency,
        numberOfReinforcements: _numberOfReinforcements,
        reinforcementAmount: _reinforcementAmount,
        validityOffer: _validityOffer,
        benefits: _benefits,
        createdBy: user.uid,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _createBudget(budget);
      _error = null;
    } catch (e) {
      _error = 'Error al guardar el presupuesto: $e';
      notifyListeners();
      return;
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

  Future<void> saveAndSharePdf(BuildContext context) async {
    try {
      if (_clientId == null) {
        _error = 'No se ha seleccionado o creado un cliente.';
        notifyListeners();
        return;
      }
      final client = await getClient(_clientId!);
      if (client == null) {
        _error = 'No se pudo cargar los datos del cliente.';
        notifyListeners();
        return;
      }
      if (!context.mounted) return;

      debugPrint('[BudgetProvider] saveAndSharePdf: '
          'client=${client.razonSocial}, '
          'product=${_product!.name}, '
          'currency=$_currency, '
          'price=$_price, '
          'capital=${_price! - (_delivery ?? 0)}, '
          'numberOfInstallments=$_numberOfInstallments, '
          'amortizationScheduleLength=${_amortizationSchedule?.length}');

      await _pdfGenerator.saveAndSharePdf(
        context: context,
        client: client,
        product: _product!,
        currency: _currency!,
        price: _price!,
        paymentMethod: _paymentMethod!,
        financingType: _financingType,
        delivery: _delivery,
        paymentFrequency: _paymentFrequency,
        numberOfInstallments: _numberOfInstallments,
        hasReinforcements: _hasReinforcements,
        reinforcementFrequency: _reinforcementFrequency,
        numberOfReinforcements: _numberOfReinforcements,
        reinforcementAmount: _reinforcementAmount,
        reinforcementMonth: _reinforcementMonth,
        amortizationSchedule: _amortizationSchedule,
        validityOffer: _validityOffer,
        benefits: _benefits,
      );
      _error = null;
    } catch (e) {
      _error = 'Error al generar o compartir el PDF: $e';
      debugPrint('PDF Error: $e');
      notifyListeners();
    }
    notifyListeners();
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
    _paymentFrequency = null;
    _numberOfInstallments = null;
    _hasReinforcements = null;
    _reinforcementFrequency = null;
    _numberOfReinforcements = null;
    _reinforcementAmount = null;
    _reinforcementMonth = null;
    _validityOffer = null;
    _benefits = null;
    _amortizationSchedule = null;
    _error = null;
    _clients = [];
    notifyListeners();
  }
}
