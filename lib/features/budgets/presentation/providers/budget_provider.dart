import 'dart:typed_data';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/client.dart';
import '../../domain/usecases/create_budget.dart';
import '../../../products/domain/entities/product.dart';
import '../../data/models/client_model.dart'; // Importar ClientModel para mapear los datos

class BudgetProvider with ChangeNotifier {
  Client? _client; // Almacenar temporalmente los datos del cliente
  String? _clientId; // Almacenar el ID del cliente después de crearlo
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
  List<Map<String, dynamic>>? _amortizationSchedule;

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
  List<Map<String, dynamic>>? get amortizationSchedule => _amortizationSchedule;

  final CreateBudget _createBudget;

  BudgetProvider({required CreateBudget createBudget})
      : _createBudget = createBudget;

  void updateClient({
    required String razonSocial,
    required String ruc,
    String? email,
    String? telefono,
    String? ciudad,
    String? departamento,
  }) {
    if (razonSocial.isEmpty || ruc.isEmpty) {
      _error = 'Razón Social y RUC son obligatorios.';
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
    _error = null;
    notifyListeners();
  }

  void updateProduct(Product product) {
    _product = product;
    _price = product.price; // Precio inicial desde el producto
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
  }) {
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
    }

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
    _error = null;

    // Calcular tabla de amortización si es financiado
    if (paymentMethod == 'Financiado' &&
        numberOfInstallments != null &&
        delivery != null) {
      _amortizationSchedule =
          AmortizationCalculator.calculateFrenchAmortization(
        capital: price - delivery,
        monthlyRate:
            currency == 'USD' ? 0.015 : 0.018, // Ejemplo: tasas según moneda
        numberOfInstallments: numberOfInstallments,
        reinforcements: hasReinforcements == true &&
                numberOfReinforcements != null &&
                reinforcementAmount != null
            ? _generateReinforcements(numberOfReinforcements,
                reinforcementAmount, reinforcementFrequency!)
            : null,
      );
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
    return reinforcements;
  }

  Future<void> createBudget() async {
    // Verificar que los campos obligatorios no sean nulos
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

    // Crear el cliente en Firestore
    final clientId = const Uuid().v4();
    final clientModel = ClientModel(
      id: clientId,
      razonSocial: _client!.razonSocial,
      ruc: _client!.ruc,
      email: _client!.email,
      telefono: _client!.telefono,
      ciudad: _client!.ciudad,
      departamento: _client!.departamento,
      createdBy: user.uid,
    );

    try {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .set(clientModel.toMap());

      _clientId = clientId; // Almacenar el clientId para usar en el PDF

      final budget = Budget(
        id: const Uuid().v4(),
        clientId: clientId, // Usar clientId en lugar de client
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
        createdBy: user.uid,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _createBudget(budget);
      _error = null;
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

  Future<Uint8List> generateBudgetPdf() async {
    if (_clientId == null ||
        _product == null ||
        _currency == null ||
        _price == null ||
        _paymentMethod == null) {
      throw Exception('Datos incompletos para generar el PDF.');
    }

    // Obtener los datos del cliente desde Firestore
    final client = await getClient(_clientId!);
    if (client == null) {
      throw Exception('No se pudo cargar los datos del cliente.');
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text('Presupuesto', style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 20),
          pw.Text('Cliente: ${client.razonSocial}'),
          pw.Text('RUC: ${client.ruc}'),
          if (client.email != null) pw.Text('E-mail: ${client.email}'),
          if (client.ciudad != null) pw.Text('Ciudad: ${client.ciudad}'),
          if (client.departamento != null)
            pw.Text('Departamento: ${client.departamento}'),
          pw.SizedBox(height: 20),
          pw.Text('Máquina: ${_product!.name}'),
          pw.Text('Tipo: ${_product!.type}'),
          pw.Text('Precio: $_price $_currency'),
          pw.SizedBox(height: 20),
          pw.Text('Forma de Pago: $_paymentMethod'),
          if (_paymentMethod == 'Financiado') ...[
            if (_financingType != null)
              pw.Text('Tipo de Financiamiento: $_financingType'),
            if (_delivery != null) pw.Text('Entrega: $_delivery $_currency'),
            if (_paymentFrequency != null)
              pw.Text('Frecuencia de Pago: $_paymentFrequency'),
            if (_numberOfInstallments != null)
              pw.Text('Cantidad de Cuotas: $_numberOfInstallments'),
            if (_hasReinforcements == true) ...[
              pw.Text('Refuerzos: Sí'),
              if (_reinforcementFrequency != null)
                pw.Text('Frecuencia de Refuerzos: $_reinforcementFrequency'),
              if (_numberOfReinforcements != null)
                pw.Text('Cantidad de Refuerzos: $_numberOfReinforcements'),
              if (_reinforcementAmount != null)
                pw.Text('Monto de Refuerzos: $_reinforcementAmount $_currency'),
            ],
            if (_amortizationSchedule != null) ...[
              pw.SizedBox(height: 20),
              pw.Text('Tabla de Amortización',
                  style: pw.TextStyle(fontSize: 18)),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Cuota',
                  'Capital',
                  'Intereses',
                  'Pago Total',
                  'Capital Pendiente'
                ],
                data: _amortizationSchedule!
                    .map((e) => [
                          e['cuota'].toString(),
                          e['capital'].toStringAsFixed(2),
                          e['intereses'].toStringAsFixed(2),
                          e['pago_total'].toStringAsFixed(2),
                          e['capital_pendiente'].toStringAsFixed(2),
                        ])
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> saveAndSharePdf() async {
    final pdfBytes = await generateBudgetPdf();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'presupuesto_${_client!.razonSocial}_${DateTime.now().toIso8601String()}.pdf',
    );
  }

  void clear() {
    _client = null;
    _clientId = null;
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
    _amortizationSchedule = null;
    _error = null;
    notifyListeners();
  }
}

class AmortizationCalculator {
  static List<Map<String, dynamic>> calculateFrenchAmortization({
    required double capital,
    required double monthlyRate,
    required int numberOfInstallments,
    Map<int, double>? reinforcements,
  }) {
    List<Map<String, dynamic>> schedule = [];
    double remainingCapital = capital;
    double monthlyPayment =
        (capital * monthlyRate * pow(1 + monthlyRate, numberOfInstallments)) /
            (pow(1 + monthlyRate, numberOfInstallments) - 1);

    for (int i = 1; i <= numberOfInstallments; i++) {
      double interest = remainingCapital * monthlyRate;
      double principal = monthlyPayment - interest;
      remainingCapital -= principal;

      // Aplicar Refuerzos
      double reinforcement =
          reinforcements != null && reinforcements.containsKey(i)
              ? reinforcements[i]!
              : 0;
      if (reinforcement > 0) {
        remainingCapital -= reinforcement;
        // Recalcular cuota si es necesario
        if (remainingCapital > 0 && i < numberOfInstallments) {
          monthlyPayment = (remainingCapital *
                  monthlyRate *
                  pow(1 + monthlyRate, numberOfInstallments - i)) /
              (pow(1 + monthlyRate, numberOfInstallments - i) - 1);
        }
      }

      schedule.add({
        'cuota': i,
        'capital': principal,
        'intereses': interest,
        'pago_total': monthlyPayment + reinforcement,
        'capital_pendiente': remainingCapital > 0 ? remainingCapital : 0,
      });

      if (remainingCapital <= 0) break;
    }

    return schedule;
  }
}
