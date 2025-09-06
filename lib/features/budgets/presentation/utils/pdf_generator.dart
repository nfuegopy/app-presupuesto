// lib/features/budgets/presentation/utils/pdf_generator.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../data/models/client_model.dart';
import '../../../products/domain/entities/product.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

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
    String? commercialConditions,
    double? lifeInsuranceAmount,
  }) async {
    final Uint8List logoData = await DefaultAssetBundle.of(context)
        .load('assets/images/logo.png')
        .then((byteData) => byteData.buffer.asUint8List());

    final fontData = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final fontBoldData = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBoldData);

    Uint8List? productImageData;
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(product.imageUrl!))
            .timeout(const Duration(seconds: 10));
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
            .timeout(const Duration(seconds: 10));
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

    const PdfColor redColor = PdfColor.fromInt(0xffE30613);

    final currencyFormat =
        NumberFormat.currency(locale: 'es_PY', symbol: '', decimalDigits: 0);

    List<List<String>> financingPlans = [];
    double generatedMonthlyPayment = 0.0;

    final schedule = amortizationSchedule ?? [];

    if (paymentMethod == 'Financiado' && schedule.isNotEmpty) {
      generatedMonthlyPayment =
          schedule.isNotEmpty ? (schedule[0]['pago_total'] as double) : 0.0;

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
              ? '$currency ${currencyFormat.format(delivery)}.-'
              : '-',
          '$currency ${currencyFormat.format(generatedMonthlyPayment)}',
          '$numberOfInstallments',
          hasReinforcements == true && numberOfReinforcements != null
              ? '$numberOfReinforcements'
              : '-',
          hasReinforcements == true && reinforcementAmount != null
              ? '$currency ${currencyFormat.format(reinforcementAmount)}.-'
              : '-',
        ],
      ];
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.Container();
          return pw.Column(
            children: [
              pw.Center(
                  child: pw.Image(pw.MemoryImage(logoData),
                      width: 100, height: 100)),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Column(
              children: [
                pw.Text('Tajy, B° Arecaya - Mariano Roque Alonso',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text('www.enginepy.com',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> content = [];

          // ========== PAGE ONE ==========
          content.addAll([
            pw.Center(
                child: pw.Image(pw.MemoryImage(logoData),
                    width: 100, height: 100)),
            pw.SizedBox(height: 12),
            pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Text(formattedDate,
                    style:
                        pw.TextStyle(fontSize: 12, color: PdfColors.grey800))),
            pw.Text('Señor/es:',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800)),
            pw.Text(client.razonSocial,
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black)),
            pw.SizedBox(height: 16),
            pw.Text(
              'Por el presente nos dirigimos a usted a modo de presentar la cotización por el siguiente producto: (1) ${product.name}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 16),
            pw.Text('MAQUINARIA',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: redColor)),
            pw.SizedBox(height: 8),
            pw.Text(product.name, style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 8),
            if (descriptionImageData != null) ...[
              pw.Center(
                  child: pw.Image(pw.MemoryImage(descriptionImageData),
                      width: 400, fit: pw.BoxFit.contain)),
              pw.SizedBox(height: 12),
            ],
            pw.Text(
                'Precio Unitario: $currency ${currencyFormat.format(price)}.-',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.black)),
            pw.SizedBox(height: 16),
            if (financingPlans.isNotEmpty) ...[
              pw.Text('FINANCIACIÓN',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: redColor)),
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
                  'Monto de refuerzos'
                ],
                data: financingPlans,
                headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.all(4),
                headerDecoration: const pw.BoxDecoration(color: redColor),
                cellDecoration: (index, data, rowNum) => const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300))),
                columnWidths: {
                  0: pw.FixedColumnWidth(90),
                  1: pw.FixedColumnWidth(70),
                  2: pw.FixedColumnWidth(70),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FixedColumnWidth(60),
                  5: pw.FixedColumnWidth(70)
                },
              ),
            ],
          ]);

          // ========== PAGE TWO (Amortization) ==========
          if (paymentMethod == 'Financiado' && schedule.isNotEmpty) {
            content.add(pw.NewPage());
            content.add(pw.Text('CRONOGRAMA DE CUOTAS',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: redColor)));
            content.add(pw.SizedBox(height: 8));

            // --- ESTA ES LA LÓGICA MEJORADA ---
            const int maxRowsPerColumn = 24;
            const int maxColumnsPerRow = 3;
            final List<pw.Widget> tableWidgets = [];

            // 1. Convertir los datos de las cuotas en widgets de Tabla
            for (int i = 0;
                i < (schedule.length / maxRowsPerColumn).ceil();
                i++) {
              final int startIndex = i * maxRowsPerColumn;
              final int endIndex =
                  min(startIndex + maxRowsPerColumn, schedule.length);
              final List<List<String>> columnData = [];

              for (int j = startIndex; j < endIndex; j++) {
                var installment = schedule[j];
                columnData.add([
                  installment['cuota'].toString(),
                  installment['month'] as String,
                  '$currency ${currencyFormat.format(installment['pago_total'])}.-',
                ]);
              }

              tableWidgets.add(pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5),
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
                    headerDecoration: const pw.BoxDecoration(color: redColor),
                    cellDecoration: (index, data, rowNum) =>
                        const pw.BoxDecoration(
                            border: pw.Border(
                                bottom:
                                    pw.BorderSide(color: PdfColors.grey300))),
                    columnWidths: {
                      0: pw.FixedColumnWidth(40),
                      1: pw.FixedColumnWidth(60),
                      2: pw.FixedColumnWidth(70)
                    },
                  )));
            }

            // 2. Organizar los widgets de Tabla en filas (Rows)
            for (int i = 0; i < tableWidgets.length; i += maxColumnsPerRow) {
              content.add(pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: tableWidgets.sublist(
                    i, min(i + maxColumnsPerRow, tableWidgets.length)),
              ));
              content.add(pw.SizedBox(height: 10));
            }
          }

          // ========== PAGE THREE (Benefits, etc.) ==========
          if ((benefits != null && benefits.isNotEmpty) ||
              productImageData != null ||
              (commercialConditions != null &&
                  commercialConditions.isNotEmpty) ||
              (validityOffer != null && validityOffer.isNotEmpty)) {
            content.add(pw.NewPage());
            if (benefits != null && benefits.isNotEmpty) {
              content.add(pw.Center(
                  child: pw.Container(
                      width: 400,
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
                                    color: redColor)),
                            pw.SizedBox(height: 4),
                            pw.Text(benefits,
                                style: pw.TextStyle(
                                    fontSize: 12, color: PdfColors.grey800)),
                          ]))));
              content.add(pw.SizedBox(height: 12));
            }

            if (productImageData != null) {
              content.add(pw.Center(
                  child: pw.Image(pw.MemoryImage(productImageData),
                      width: 400, fit: pw.BoxFit.contain)));
              content.add(pw.SizedBox(height: 16));
            }

            if (commercialConditions != null &&
                commercialConditions.isNotEmpty) {
              content.add(pw.Center(
                  child: pw.Container(
                      width: 400,
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
                            pw.Text('Condiciones Comerciales',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: redColor)),
                            pw.SizedBox(height: 4),
                            pw.Text(commercialConditions,
                                style: pw.TextStyle(
                                    fontSize: 12, color: PdfColors.grey800)),
                          ]))));
              content.add(pw.SizedBox(height: 12));
            }

            if (validityOffer != null && validityOffer.isNotEmpty) {
              content.add(pw.Center(
                  child: pw.Container(
                      width: 400,
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
                                    color: redColor)),
                            pw.SizedBox(height: 4),
                            pw.Text(validityOffer,
                                style: pw.TextStyle(
                                    fontSize: 12, color: PdfColors.grey800)),
                          ]))));
              content.add(pw.SizedBox(height: 12));
            }
          }

          return content;
        },
      ),
    );

    return pdf.save();
  }
}
