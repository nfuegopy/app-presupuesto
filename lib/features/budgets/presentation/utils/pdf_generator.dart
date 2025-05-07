import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../data/models/client_model.dart';
import '../../../products/domain/entities/product.dart';
import '../utils/amortization_calculator.dart';
import 'dart:math';

class PdfGenerator {
  Future<Uint8List> generateBudgetPdf({
    required BuildContext context,
    required ClientModel client,
    required Product product,
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
    List<Map<String, dynamic>>? amortizationSchedule,
    String? offer, // Parámetro para "Ofrecemos"
  }) async {
    // Cargar el logo desde los assets
    final Uint8List logoData = await DefaultAssetBundle.of(context)
        .load('assets/images/logo.png')
        .then((byteData) => byteData.buffer.asUint8List());

    // Cargar la imagen del producto desde imageUrl si está disponible
    Uint8List? productImageData;
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(product.imageUrl!))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          productImageData = response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Error downloading image: $e');
      }
    }

    final pdf = pw.Document();

    // Formatear la fecha actual
    final now = DateTime.now();
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final formattedDate =
        'Asunción, ${now.day} de ${months[now.month - 1]} del ${now.year}';

    // Determinar el plan seleccionado y usar los valores de amortizationSchedule
    List<List<String>> financingPlans = [];
    if (paymentMethod == 'Financiado' &&
        currency != null &&
        paymentFrequency != null &&
        numberOfInstallments != null) {
      double capital = price - (delivery ?? 0);
      double monthlyRate = currency == 'USD' ? 0.0085 : 0.018;
      int effectiveInstallments;
      double adjustedRate = monthlyRate;

      // Ajustar número de cuotas y tasa según la frecuencia
      if (paymentFrequency == 'Mensual') {
        effectiveInstallments = numberOfInstallments;
      } else if (paymentFrequency == 'Semestral') {
        effectiveInstallments = numberOfInstallments ~/ 6;
        adjustedRate = pow(1 + monthlyRate, 6) - 1; // Tasa para 6 meses
      } else if (paymentFrequency == 'Trimestral') {
        effectiveInstallments = numberOfInstallments ~/ 3;
        adjustedRate = pow(1 + monthlyRate, 3) - 1; // Tasa para 3 meses
      } else if (paymentFrequency == 'Anual') {
        effectiveInstallments = numberOfInstallments ~/ 12;
        adjustedRate = pow(1 + monthlyRate, 12) - 1; // Tasa para 12 meses
      } else {
        effectiveInstallments = numberOfInstallments;
      }

      // Generar refuerzos si aplica
      Map<int, double>? reinforcements;
      if (hasReinforcements == true &&
          numberOfReinforcements != null &&
          reinforcementAmount != null &&
          reinforcementFrequency != null) {
        int interval;
        switch (reinforcementFrequency) {
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
        reinforcements = {};
        for (int i = 1; i <= numberOfReinforcements; i++) {
          reinforcements[i * interval] = reinforcementAmount;
        }
      }

      // Calcular la cuota fija usando el método francés
      double fixedPayment = (capital *
              adjustedRate *
              pow(1 + adjustedRate, effectiveInstallments)) /
          (pow(1 + adjustedRate, effectiveInstallments) - 1);

      // Generar la tabla de amortización
      var schedule = AmortizationCalculator.calculateFrenchAmortization(
        capital: capital,
        monthlyRate: adjustedRate,
        numberOfInstallments: effectiveInstallments,
        fixedMonthlyPayment: fixedPayment,
        reinforcements: reinforcements,
      );

      // Obtener el pago de la primera cuota (sin refuerzos)
      double monthlyPayment =
          schedule.isNotEmpty ? (schedule[0]['pago_total'] as double) : 0;
      // Calcular el total sumando todos los pagos más la entrega
      double totalToPay = schedule.fold(
              0.0, (sum, item) => sum + (item['pago_total'] as double)) +
          (delivery ?? 0);

      // Ajustar el nombre del plan según las selecciones
      String planName = '';
      if (paymentFrequency == 'Mensual') {
        if (hasReinforcements == true && delivery != null && delivery > 0) {
          planName = 'Plan mensual con entrega';
        } else if (hasReinforcements != true &&
            (delivery == null || delivery == 0)) {
          planName = 'Plan mensual sin entrega';
        }
      } else if (paymentFrequency == 'Semestral') {
        if (hasReinforcements != true && (delivery == null || delivery == 0)) {
          planName = 'Plan semestral sin entrega';
        } else if (hasReinforcements != true &&
            delivery != null &&
            delivery > 0) {
          planName = 'Plan semestral con entrega';
        }
      } else if (paymentFrequency == 'Trimestral') {
        if (hasReinforcements == true && delivery != null && delivery > 0) {
          planName = 'Plan trimestral con entrega';
        } else if (hasReinforcements != true &&
            (delivery == null || delivery == 0)) {
          planName = 'Plan trimestral sin entrega';
        }
      } else if (paymentFrequency == 'Anual') {
        if (hasReinforcements == true && delivery != null && delivery > 0) {
          planName = 'Plan anual con entrega';
        } else if (hasReinforcements != true &&
            (delivery == null || delivery == 0)) {
          planName = 'Plan anual sin entrega';
        }
      }

      // Generar la fila del plan seleccionado
      if (planName.isNotEmpty) {
        financingPlans = [
          [
            planName,
            delivery != null && delivery > 0
                ? '$currency ${delivery.toStringAsFixed(2)}.-'
                : '-',
            '$currency ${monthlyPayment.toStringAsFixed(2)}',
            '$numberOfInstallments',
            hasReinforcements == true && numberOfReinforcements != null
                ? '$numberOfReinforcements'
                : '-',
            hasReinforcements == true && reinforcementAmount != null
                ? '$currency ${reinforcementAmount.toStringAsFixed(2)}.-'
                : '-',
            '$currency ${totalToPay.toStringAsFixed(2)}.-',
          ],
        ];
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Image(pw.MemoryImage(logoData), width: 100, height: 100),
              pw.SizedBox(height: 10),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 20),
                child:
                    pw.Text(formattedDate, style: pw.TextStyle(fontSize: 12)),
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
                pw.Text('www.enginepy.com',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                pw.Text('Cel. (0985) 242811',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          // Calcular el total a abonar
          double totalToPay = price;
          if (amortizationSchedule != null && amortizationSchedule.isNotEmpty) {
            totalToPay = amortizationSchedule.fold(
                    0.0, (sum, item) => sum + (item['pago_total'] as double)) +
                (delivery ?? 0);
          } else if (paymentMethod == 'Financiado' && delivery != null) {
            totalToPay += (delivery ?? 0);
          }

          // Obtener el pago mensual para mostrar
          double? monthlyPayment;
          if (amortizationSchedule != null && amortizationSchedule.isNotEmpty) {
            monthlyPayment = amortizationSchedule[0]['pago_total'] as double;
            if (hasReinforcements == true &&
                numberOfInstallments != null &&
                reinforcementAmount != null) {
              // No ajustamos monthlyPayment aquí, lo mostramos tal como viene
            }
          }

          return [
            pw.Text('Señor', style: pw.TextStyle(fontSize: 14)),
            pw.Text(client.razonSocial,
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text(
              'Por el presente nos dirigimos a usted a modo de presentar la cotización por el siguiente producto: (1) Una ${product.name}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            pw.Text('MAQUINARIA',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Retropala ${product.name}'),
            pw.SizedBox(height: 10),
            if (product.brand != null) pw.Text('Marca: ${product.brand}'),
            if (product.model != null) pw.Text('Modelo: ${product.model}'),
            if (product.fuelType != null)
              pw.Text('Tipo de Combustible: ${product.fuelType}'),
            if (product.features != null && product.features!.isNotEmpty)
              pw.Text('Descripción: ${product.features}'),
            pw.SizedBox(height: 10),
            if (productImageData != null) ...[
              pw.Image(pw.MemoryImage(productImageData),
                  width: 100, height: 100),
              pw.SizedBox(height: 10),
            ],
            pw.Text('Precio Unitario: $currency ${price.toStringAsFixed(2)}.-'),
            pw.SizedBox(height: 20),
            if (financingPlans.isNotEmpty) ...[
              pw.Text('FINANCIACIÓN',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('PLAN DE FINANCIACIÓN $currency'),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: [
                  'Forma de pago',
                  'Entrega',
                  'Monto de cuota',
                  'Cantidad de cuotas',
                  'Cantidad de refuerzos',
                  'Monto de refuerzos',
                  'TOTAL',
                ],
                data: financingPlans,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
              pw.SizedBox(height: 20),
            ],
            pw.Text('DETALLES DE LOS PAGOS',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Forma de Pago: $paymentMethod'),
            if (paymentMethod == 'Financiado') ...[
              if (financingType != null)
                pw.Text('Tipo de Financiamiento: $financingType'),
              if (delivery != null)
                pw.Text('Entrega: $currency ${delivery.toStringAsFixed(2)}.-'),
              if (paymentFrequency != null)
                pw.Text('Frecuencia de Pago: $paymentFrequency'),
              if (numberOfInstallments != null)
                pw.Text('Cantidad de Cuotas: $numberOfInstallments'),
              if (hasReinforcements == true) ...[
                pw.Text('Refuerzos: Sí'),
                if (reinforcementFrequency != null)
                  pw.Text('Frecuencia de Refuerzos: $reinforcementFrequency'),
                if (numberOfReinforcements != null)
                  pw.Text('Cantidad de Refuerzos: $numberOfReinforcements'),
                if (reinforcementAmount != null)
                  pw.Text(
                      'Monto de Refuerzos: $currency ${reinforcementAmount.toStringAsFixed(2)}.-'),
              ] else ...[
                pw.Text('Refuerzos: No'),
              ],
              if (monthlyPayment != null)
                pw.Text(
                    'Monto de Cuota: $currency ${monthlyPayment.toStringAsFixed(2)}'),
              if (hasReinforcements == true && reinforcementAmount != null)
                pw.Text(
                    'Monto de Refuerzo: $currency ${reinforcementAmount.toStringAsFixed(2)}.-'),
              if (hasReinforcements == true && numberOfReinforcements != null)
                pw.Text('Cantidad de Refuerzos: $numberOfReinforcements'),
              pw.Text(
                  'Total a Abonar: $currency ${totalToPay.toStringAsFixed(2)}.-'),
            ] else ...[
              pw.Text(
                  'Total a Abonar: $currency ${totalToPay.toStringAsFixed(2)}.-'),
            ],
            if (offer != null && offer.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('OFRECEMOS',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(offer, style: pw.TextStyle(fontSize: 14)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> saveAndSharePdf({
    required BuildContext context,
    required ClientModel client,
    required Product product,
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
    List<Map<String, dynamic>>? amortizationSchedule,
    String? offer, // Parámetro para "Ofrecemos"
  }) async {
    final pdfBytes = await generateBudgetPdf(
      context: context,
      client: client,
      product: product,
      currency: currency,
      price: price,
      paymentMethod: paymentMethod,
      financingType: financingType,
      delivery: delivery,
      paymentFrequency: paymentFrequency,
      numberOfInstallments: numberOfInstallments,
      hasReinforcements: hasReinforcements,
      reinforcementFrequency: reinforcementFrequency,
      numberOfReinforcements: numberOfReinforcements,
      reinforcementAmount: reinforcementAmount,
      amortizationSchedule: amortizationSchedule,
      offer: offer,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'presupuesto_${client.razonSocial}_${DateTime.now().toIso8601String()}.pdf',
    );
  }
}
