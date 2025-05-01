import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/budget.dart';
import '../../domain/entities/client.dart';
import '../../domain/usecases/create_budget.dart';
import '../../../products/domain/entities/product.dart';
import '../../data/models/client_model.dart';

class BudgetProvider with ChangeNotifier {
  Client? _client;
  String? _clientId;
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

    if (paymentMethod == 'Financiado' &&
        numberOfInstallments != null &&
        delivery != null) {
      _amortizationSchedule =
          AmortizationCalculator.calculateFrenchAmortization(
        capital: price - delivery,
        monthlyRate:
            currency == 'USD' ? 0.015 : 0.018,
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

      _clientId = clientId;

      final budget = Budget(
        id: const Uuid().v4(),
        clientId: clientId,
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

  Future<Uint8List> generateBudgetPdf(BuildContext context) async {
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

    // Cargar el logo desde los assets antes de cualquier operación asíncrona
    final Uint8List logoData = await DefaultAssetBundle.of(context)
        .load('assets/images/logo.png')
        .then((byteData) => byteData.buffer.asUint8List());

    // Cargar la imagen del producto desde imageUrl si está disponible
    Uint8List? productImageData;
    if (_product!.imageUrl != null && _product!.imageUrl!.isNotEmpty) {
      final response = await http.get(Uri.parse(_product!.imageUrl!));
      if (response.statusCode == 200) {
        productImageData = response.bodyBytes;
      }
    }

    final pdf = pw.Document();

    // Formatear la fecha actual como "Asunción, [día] de [mes] del [año]"
    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final formattedDate = 'Asunción, ${now.day} de ${months[now.month - 1]} del ${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Column(
            children: [
              // Logo en la parte superior
              pw.Image(
                pw.MemoryImage(logoData),
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Text(
                  formattedDate,
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              children: [
                pw.Text(
                  'www.enginepy.com',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.Text(
                  'Cel. (0985) 242811',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          // Calcular valores para los detalles de los pagos
          double? monthlyPayment;
          double? totalToPay;

          if (_amortizationSchedule != null && _amortizationSchedule!.isNotEmpty) {
            monthlyPayment = _amortizationSchedule![0]['pago_total'] as double;
            totalToPay = _amortizationSchedule!.fold(
                    0.0,
                    (sum, item) => sum + (item['pago_total'] as double)) +
                (_delivery ?? 0.0);
          } else if (_paymentMethod == 'Financiado') {
            totalToPay = (_price ?? 0.0) +
                (_delivery ?? 0.0) +
                ((_reinforcementAmount ?? 0.0) * (_numberOfReinforcements ?? 0));
          } else {
            totalToPay = _price ?? 0.0;
          }

          return [
            // Destinatario
            pw.Text(
              'Señor',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              client.razonSocial,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Presente',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),

            // Introducción
            pw.Text(
              'Por el presente nos dirigimos a usted a modo de presentar la cotización por el siguiente producto: ${_product!.name}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),

            // Detalles del Producto
            pw.Text(
              'Detalles del Producto',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Máquina: ${_product!.name}'),
            pw.Text('Tipo: ${_product!.type}'),
            if (_product!.brand != null) pw.Text('Marca: ${_product!.brand}'),
            if (_product!.model != null) pw.Text('Modelo: ${_product!.model}'),
            if (_product!.fuelType != null) pw.Text('Tipo de Combustible: ${_product!.fuelType}'),
            if (_product!.features != null && _product!.features!.isNotEmpty)
              pw.Text('Descripción: ${_product!.features}'),
            pw.SizedBox(height: 10),

            // Imagen del Producto
            if (productImageData != null) ...[
              pw.Image(
                pw.MemoryImage(productImageData),
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 10),
            ],

            // Precio Unitario
            pw.Text('Precio Unitario: $_price $_currency'),
            pw.SizedBox(height: 20),

            // Detalles de los Pagos
            pw.Text(
              'Detalles de los Pagos',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
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
              if (_amortizationSchedule != null && _amortizationSchedule!.isNotEmpty) ...[
                pw.Text('Monto de Cuota: ${monthlyPayment!.toStringAsFixed(2)} $_currency'),
                if (_hasReinforcements == true && _reinforcementAmount != null)
                  pw.Text('Monto de Refuerzo: $_reinforcementAmount $_currency'),
                if (_hasReinforcements == true && _numberOfReinforcements != null)
                  pw.Text('Cantidad de Refuerzos: $_numberOfReinforcements'),
                pw.Text('Total a Abonar: ${totalToPay!.toStringAsFixed(2)} $_currency'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Tabla de Amortización',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table.fromTextArray(
                  headers: [
                    'Cuota',
                    'Capital',
                    'Intereses',
                    'Pago Total',
                    'Capital Pendiente',
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
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.center,
                  cellPadding: const pw.EdgeInsets.all(5),
                ),
              ] else ...[
                pw.Text('Total a Abonar: ${totalToPay!.toStringAsFixed(2)} $_currency'),
              ],
            ] else ...[
              pw.Text('Total a Abonar: ${totalToPay!.toStringAsFixed(2)} $_currency'),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> saveAndSharePdf(BuildContext context) async {
    final pdfBytes = await generateBudgetPdf(context);
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

      double reinforcement =
          reinforcements != null && reinforcements.containsKey(i)
              ? reinforcements[i]!
              : 0;
      if (reinforcement > 0) {
        remainingCapital -= reinforcement;
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