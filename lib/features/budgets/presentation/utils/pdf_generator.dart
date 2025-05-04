import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../data/models/client_model.dart';
import '../../../products/domain/entities/product.dart';
import '../utils/amortization_calculator.dart';

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
        numberOfInstallments != null &&
        amortizationSchedule != null &&
        amortizationSchedule.isNotEmpty) {
      // Usar los valores de amortizationSchedule
      double monthlyPayment = amortizationSchedule[0]['pago_total'] as double;
      double totalToPay = amortizationSchedule.fold(
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
          // Usar los valores de amortizationSchedule para los detalles de pago
          double totalToPay = price;
          if (amortizationSchedule != null && amortizationSchedule.isNotEmpty) {
            totalToPay = amortizationSchedule.fold(
                    0.0, (sum, item) => sum + (item['pago_total'] as double)) +
                (delivery ?? 0);
          } else if (paymentMethod == 'Financiado' && delivery != null) {
            totalToPay += (delivery ?? 0);
          }

          // Calcular el pago mensual para mostrar
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
            pw.Text('Señor', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Presente', style: pw.TextStyle(fontSize: 14)),
            pw.Text(
              client.razonSocial,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Por el presente nos dirigimos a usted a modo de presentar la cotización por el siguiente producto: (1) Una ${product.name}',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'MAQUINARIA',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
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
              pw.Image(
                pw.MemoryImage(productImageData),
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 10),
            ],
            pw.Text('Precio Unitario: $currency ${price.toStringAsFixed(2)}.-'),
            pw.SizedBox(height: 20),
            if (financingPlans.isNotEmpty) ...[
              pw.Text(
                'FINANCIACIÓN',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
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
            pw.Text(
              'DETALLES DE LOS PAGOS',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
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
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'presupuesto_${client.razonSocial}_${DateTime.now().toIso8601String()}.pdf',
    );
  }
}
