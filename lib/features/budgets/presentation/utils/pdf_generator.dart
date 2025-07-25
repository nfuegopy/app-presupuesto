// File: nfuegopy/app-presupuesto/app-presupuesto-da449cfc3e7d0ae6b62ba849dde1f34919f41601/lib/features/budgets/presentation/utils/pdf_generator.dart
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
import 'package:flutter/services.dart' show rootBundle; // Import for rootBundle

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
    String? reinforcementMonth,
    List<Map<String, dynamic>>? amortizationSchedule,
    String? validityOffer,
    String? benefits,
    double? lifeInsuranceAmount, // Nuevo: Monto del seguro de vida
  }) async {
    final Uint8List logoData = await DefaultAssetBundle.of(context)
        .load('assets/images/logo.png')
        .then((byteData) => byteData.buffer.asUint8List());

    // START MODIFICATION: Load Poppins fonts
    final fontData = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final fontBoldData = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBoldData);
    // END MODIFICATION

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
        debugPrint('Error downloading main image: $e');
      }
    }

    Uint8List? descriptionImageData;
    if (product.imageDescriptionUrl != null &&
        product.imageDescriptionUrl!.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(product.imageDescriptionUrl!))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          descriptionImageData = response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Error downloading description image: $e');
      }
    }

    final pdf = pw.Document();

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

    List<List<String>> financingPlans = [];
    List<Map<String, dynamic>> schedule = amortizationSchedule ?? [];
    double generatedMonthlyPayment = 0.0;
    double generatedTotalToPay = 0.0;

    if (paymentMethod == 'Financiado' &&
        currency != null &&
        paymentFrequency != null &&
        numberOfInstallments != null) {
      double capital = price - (delivery ?? 0);
      int effectiveInstallments = numberOfInstallments;

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

      // Usar el cronograma proporcionado si está disponible
      if (schedule.isEmpty) {
        schedule = AmortizationCalculator.calculateFrenchAmortization(
          capital: capital,
          numberOfInstallments: effectiveInstallments,
          reinforcements: reinforcements,
          reinforcementMonth: reinforcementMonth,
          paymentFrequency: paymentFrequency,
          annualNominalRate: 0.095,
        );
      }

      generatedMonthlyPayment =
          schedule.isNotEmpty ? (schedule[0]['pago_total'] as double) : 0.0;
      generatedTotalToPay = schedule.fold(
              0.0, (sum, item) => sum + (item['pago_total'] as double)) +
          (delivery ?? 0);

      String planName = '';
      switch (paymentFrequency) {
        case 'Mensual':
          planName = delivery != null && delivery > 0
              ? 'Plan mensual con entrega'
              : 'Plan mensual sin entrega';
          break;
        case 'Semestral':
          planName = delivery != null && delivery > 0
              ? 'Plan semestral con entrega'
              : 'Plan semestral sin entrega';
          break;
        case 'Trimestral':
          planName = delivery != null && delivery > 0
              ? 'Plan trimestral con entrega'
              : 'Plan trimestral sin entrega';
          break;
        case 'Anual':
          planName = delivery != null && delivery > 0
              ? 'Plan anual con entrega'
              : 'Plan anual sin entrega';
          break;
      }

      financingPlans = [
        [
          planName,
          delivery != null && delivery > 0
              ? '$currency ${delivery.toStringAsFixed(2)}.-'
              : '-',
          '$currency ${generatedMonthlyPayment.toStringAsFixed(2)}',
          '$numberOfInstallments',
          hasReinforcements == true && numberOfReinforcements != null
              ? '$numberOfReinforcements'
              : '-',
          hasReinforcements == true && reinforcementAmount != null
              ? '$currency ${reinforcementAmount.toStringAsFixed(2)}.-'
              : '-',
        ],
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        // START MODIFICATION: Set default font for the document using pw.ThemeData.withFont
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        // END MODIFICATION
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Image(pw.MemoryImage(logoData), width: 100, height: 100),
              pw.SizedBox(height: 12),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Text(formattedDate,
                    style:
                        pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
              ),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Column(
              children: [
                pw.Text('www.enginepy.com',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text('Cel. (0985) 242811',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          double totalToPay = price;
          double? monthlyPayment;

          if (paymentMethod == 'Financiado' && schedule.isNotEmpty) {
            totalToPay = schedule.fold(
                    0.0, (sum, item) => sum + (item['pago_total'] as double)) +
                (delivery ?? 0);
            monthlyPayment = schedule[0]['pago_total'] as double;
          } else if (paymentMethod == 'Financiado' && delivery != null) {
            totalToPay += (delivery ?? 0);
          }

          // Preparar las cuotas en columnas (máximo 24 cuotas por columna)
          List<List<List<String>>> scheduleColumns = [];
          const int maxRowsPerColumn = 24;
          int numberOfColumns = (schedule.length / maxRowsPerColumn).ceil();
          for (int col = 0; col < numberOfColumns; col++) {
            List<List<String>> columnData = [];
            int startIndex = col * maxRowsPerColumn;
            int endIndex = min(startIndex + maxRowsPerColumn, schedule.length);
            for (int i = startIndex; i < endIndex; i++) {
              var installment = schedule[i];
              columnData.add([
                installment['cuota'].toString(),
                installment['month'] as String,
                '$currency ${installment['pago_total'].toStringAsFixed(2)}.-',
              ]);
            }
            scheduleColumns.add(columnData);
          }

          return [
            pw.Text('Señor',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800)),
            pw.Text(client.razonSocial,
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black)),
            pw.SizedBox(height: 16),
            pw.Text(
              'Por el presente nos dirigimos a usted a modo de presentar la cotización por el siguiente producto: (1) Una ${product.name}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 16),
            pw.Text('MAQUINARIA',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800)),
            pw.SizedBox(height: 8),
            pw.Text('Retropala ${product.name}',
                style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 8),
            if (descriptionImageData != null) ...[
              pw.Image(pw.MemoryImage(descriptionImageData),
                  width: 400, height: 300, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 12),
            ],
            pw.Text('Precio Unitario: $currency ${price.toStringAsFixed(2)}.-',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.black)),
            pw.SizedBox(height: 16),
            if (financingPlans.isNotEmpty) ...[
              pw.Text('FINANCIACIÓN',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800)),
              pw.SizedBox(height: 8),
              pw.Text('PLAN DE FINANCIACIÓN $currency',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: [
                  'Forma de pago',
                  'Entrega',
                  'Monto de cuota',
                  'Cantidad de cuotas',
                  'Cantidad de refuerzos',
                  'Monto de refuerzos',
                ],
                data: financingPlans,
                headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.all(4),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue800),
                cellDecoration: (index, data, rowNum) => const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300))),
                columnWidths: {
                  0: pw.FixedColumnWidth(90),
                  1: pw.FixedColumnWidth(70),
                  2: pw.FixedColumnWidth(70),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FixedColumnWidth(60),
                  5: pw.FixedColumnWidth(70),
                },
              ),
              pw.SizedBox(height: 16),
            ],
            if (paymentMethod == 'Financiado' && schedule.isNotEmpty) ...[
              pw.Text('CRONOGRAMA DE CUOTAS',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800)),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: scheduleColumns.map((columnData) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 10),
                    child: pw.Table.fromTextArray(
                      headers: ['Cuota', 'Mes', 'Monto'],
                      data: columnData,
                      headerStyle: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white),
                      cellStyle:
                          pw.TextStyle(fontSize: 9, color: PdfColors.black),
                      cellAlignment: pw.Alignment.center,
                      cellPadding: const pw.EdgeInsets.all(4),
                      headerDecoration:
                          const pw.BoxDecoration(color: PdfColors.blue800),
                      cellDecoration: (index, data, rowNum) =>
                          const pw.BoxDecoration(
                              border: pw.Border(
                                  bottom:
                                      pw.BorderSide(color: PdfColors.grey300))),
                      columnWidths: {
                        0: pw.FixedColumnWidth(40),
                        1: pw.FixedColumnWidth(60),
                        2: pw.FixedColumnWidth(70),
                      },
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 16),
            ],
            // if (lifeInsuranceAmount != null && lifeInsuranceAmount > 0) ...[
            //   pw.Text(
            //     'Seguro de Vida: $currency ${lifeInsuranceAmount.toStringAsFixed(2)}.-',
            //     style: pw.TextStyle(
            //       fontSize: 14,
            //       fontWeight: pw.FontWeight.bold,
            //       color: PdfColors.red700,
            //     ),
            //   ),
            //   pw.SizedBox(height: 16),
            // ],
            if (paymentMethod != 'Financiado') ...[
              pw.Text(
                  'Total a Abonar: $currency ${totalToPay.toStringAsFixed(2)}.-',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black)),
              pw.SizedBox(height: 16),
            ],
            if (productImageData != null) ...[
              pw.Image(pw.MemoryImage(productImageData),
                  width: 400, height: 200, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 16),
            ],
            if (validityOffer != null && validityOffer.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Validez de la Oferta',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text(validityOffer,
                        style: pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey800)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],
            if (benefits != null && benefits.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Beneficios',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text(benefits,
                        style: pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey800)),
                  ],
                ),
              ),
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
    String? reinforcementMonth,
    List<Map<String, dynamic>>? amortizationSchedule,
    String? validityOffer,
    String? benefits,
    double? lifeInsuranceAmount,
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
      reinforcementMonth: reinforcementMonth,
      amortizationSchedule: amortizationSchedule,
      validityOffer: validityOffer,
      benefits: benefits,
      lifeInsuranceAmount: lifeInsuranceAmount,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'presupuesto_${client.razonSocial}_${DateTime.now().toIso8601String()}.pdf',
    );
  }
}
