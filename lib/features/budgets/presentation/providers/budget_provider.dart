import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../products/domain/entities/product.dart';
import 'dart:math';

class BudgetProvider with ChangeNotifier {
  bool isLoading = false;
  final logger = Logger();

  // Función para calcular una cuota usando amortización francesa
  double calculateFrenchAmortization({
    required double principal,
    required double annualRate,
    required int periodsPerYear,
    required int totalPeriods,
  }) {
    double ratePerPeriod = annualRate / periodsPerYear;
    double factor =
        pow(1 + ratePerPeriod, totalPeriods).toDouble(); // Casteo a double
    return principal * (ratePerPeriod * factor) / (factor - 1);
  }

  // Función para formatear números como moneda
  String formatCurrency(double amount, String currency) {
    return '${currency == 'USD' ? 'US\$' : 'Gs.'} ${amount.toStringAsFixed(2)}.-';
  }

  Future<void> createBudget({
    required Product product,
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    required pw.MemoryImage logoImage, // Nuevo parámetro para el logo
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // Crear el documento PDF
      final pdf = pw.Document();

      // Descargar la imagen del producto si existe
      pw.MemoryImage? productImage;
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(product.imageUrl!));
          if (response.statusCode == 200) {
            productImage = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          logger.e(
              'Error al descargar la imagen: $e'); // Usamos logger en lugar de print
        }
      }

      // Obtener la fecha actual
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

      // Calcular planes de financiación
      const double annualRate = 0.13; // 13% anual en dólares
      final double price = product.price;
      const double delivery = 5000.0; // Entrega inicial

      // Plan mensual con entrega
      double monthlyWithDeliveryPrincipal = price - delivery;
      double monthlyWithDeliveryPayment = calculateFrenchAmortization(
        principal: monthlyWithDeliveryPrincipal,
        annualRate: annualRate,
        periodsPerYear: 12,
        totalPeriods: 60,
      );
      double monthlyWithDeliveryTotal = (monthlyWithDeliveryPayment * 60) +
          delivery +
          (5000 * 5); // 5 refuerzos de US$ 5,000

      // Plan mensual sin entrega
      double monthlyWithoutDeliveryPayment = calculateFrenchAmortization(
        principal: price,
        annualRate: annualRate,
        periodsPerYear: 12,
        totalPeriods: 60,
      );
      double monthlyWithoutDeliveryTotal = monthlyWithoutDeliveryPayment * 60;

      // Plan semestral sin entrega
      double semiannualWithoutDeliveryPayment = calculateFrenchAmortization(
        principal: price,
        annualRate: annualRate,
        periodsPerYear: 2,
        totalPeriods: 10,
      );
      double semiannualWithoutDeliveryTotal =
          semiannualWithoutDeliveryPayment * 10;

      // Plan semestral con entrega
      double semiannualWithDeliveryPrincipal = price - delivery;
      double semiannualWithDeliveryPayment = calculateFrenchAmortization(
        principal: semiannualWithDeliveryPrincipal,
        annualRate: annualRate,
        periodsPerYear: 2,
        totalPeriods: 10,
      );
      double semiannualWithDeliveryTotal =
          (semiannualWithDeliveryPayment * 10) + delivery;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo
                pw.Center(
                  child: pw.Image(
                    logoImage,
                    width: 100,
                    height: 100,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Fecha y destinatario
                pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Text('Señor'),
                pw.Text('Presente'),
                pw.Text(clientName),
                pw.SizedBox(height: 20),

                // Introducción
                pw.Text(
                  'Por el presente nos dirigimos a usted a modo de presentar la cotización por el siguiente producto: (1) ${product.name}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                // Especificaciones del producto
                pw.Text(
                  'Especificaciones Técnicas',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                if (product.features != null && product.features!.isNotEmpty)
                  pw.Text(
                    product.features!,
                    style: const pw.TextStyle(fontSize: 12),
                  )
                else
                  pw.Text(
                    'No especificado',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                pw.SizedBox(height: 20),

                // Imagen del producto
                if (productImage != null)
                  pw.Row(
                    children: [
                      pw.Image(
                        productImage,
                        width: 100,
                        height: 100,
                        fit: pw.BoxFit.cover,
                      ),
                      pw.SizedBox(width: 20),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Producto: ${product.name}'),
                          pw.Text('Tipo: ${product.type}'),
                          pw.Text(
                              'Precio: ${formatCurrency(product.price, product.currency)}'),
                        ],
                      ),
                    ],
                  )
                else
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Producto: ${product.name}'),
                      pw.Text('Tipo: ${product.type}'),
                      pw.Text(
                          'Precio: ${formatCurrency(product.price, product.currency)}'),
                      pw.Text('Imagen: No disponible'),
                    ],
                  ),
                pw.SizedBox(height: 20),

                // Detalles del cliente
                pw.Text(
                  'Detalles del Cliente',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Nombre: $clientName'),
                pw.Text('Correo Electrónico: $clientEmail'),
                pw.Text('Teléfono: $clientPhone'),
                pw.SizedBox(height: 20),

                // Precio y financiación
                pw.Text(
                  'MAQUINARIA Precio Unitario',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${product.name} ${formatCurrency(product.price, product.currency)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                pw.Text(
                  'Financiación',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Plan de Financiación US\$',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1),
                    6: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Encabezado de la tabla
                    pw.TableRow(
                      children: [
                        pw.Text('Forma de pago',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Entrega',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Monto de cuota',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Cantidad de cuotas',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Monto de refuerzos',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Cantidad de refuerzos',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Total',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    // Plan mensual con entrega
                    pw.TableRow(
                      children: [
                        pw.Text('Plan mensual con entrega'),
                        pw.Text(formatCurrency(delivery, 'USD')),
                        pw.Text(
                            formatCurrency(monthlyWithDeliveryPayment, 'USD')),
                        pw.Text('60'),
                        pw.Text(formatCurrency(5000.0, 'USD')),
                        pw.Text('5'),
                        pw.Text(
                            formatCurrency(monthlyWithDeliveryTotal, 'USD')),
                      ],
                    ),
                    // Plan mensual sin entrega
                    pw.TableRow(
                      children: [
                        pw.Text('Plan mensual sin entrega'),
                        pw.Text('-'),
                        pw.Text(formatCurrency(
                            monthlyWithoutDeliveryPayment, 'USD')),
                        pw.Text('60'),
                        pw.Text('-'),
                        pw.Text('-'),
                        pw.Text(
                            formatCurrency(monthlyWithoutDeliveryTotal, 'USD')),
                      ],
                    ),
                    // Plan semestral sin entrega
                    pw.TableRow(
                      children: [
                        pw.Text('Plan semestral sin entrega'),
                        pw.Text('-'),
                        pw.Text(formatCurrency(
                            semiannualWithoutDeliveryPayment, 'USD')),
                        pw.Text('10'),
                        pw.Text('-'),
                        pw.Text('-'),
                        pw.Text(formatCurrency(
                            semiannualWithoutDeliveryTotal, 'USD')),
                      ],
                    ),
                    // Plan semestral con entrega
                    pw.TableRow(
                      children: [
                        pw.Text('Plan semestral con entrega'),
                        pw.Text(formatCurrency(delivery, 'USD')),
                        pw.Text(formatCurrency(
                            semiannualWithDeliveryPayment, 'USD')),
                        pw.Text('10'),
                        pw.Text('-'),
                        pw.Text('-'),
                        pw.Text(
                            formatCurrency(semiannualWithDeliveryTotal, 'USD')),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Footer
                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                  'www.enginepy.com\nCel. (0985) 2428 11\nDesarrollado por Antonio Barrios',
                  style:
                      const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Compartir el PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'presupuesto_${product.name}.pdf',
      );
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
