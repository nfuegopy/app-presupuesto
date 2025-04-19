import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../../products/domain/entities/product.dart';

class BudgetProvider with ChangeNotifier {
  bool isLoading = false;

  Future<void> createBudget({
    required Product product,
    required String clientName,
    required String clientEmail,
    required String clientPhone,
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
          print('Error al descargar la imagen: $e');
          // Continuar sin la imagen si falla la descarga
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título
                pw.Text(
                  'Presupuesto',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Detalles de la máquina
                pw.Text(
                  'Detalles de la Máquina',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                // Imagen del producto (si existe)
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
                          pw.Text('Nombre: ${product.name}'),
                          pw.Text('Tipo: ${product.type}'),
                          pw.Text(
                              'Precio: ${product.price} ${product.currency}'),
                        ],
                      ),
                    ],
                  )
                else
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Nombre: ${product.name}'),
                      pw.Text('Tipo: ${product.type}'),
                      pw.Text('Precio: ${product.price} ${product.currency}'),
                      pw.Text('Imagen: No disponible'),
                    ],
                  ),
                pw.SizedBox(height: 10),
                pw.Text('Características:', style: pw.TextStyle(fontSize: 14)),
                pw.Text(
                  product.features ?? 'Sin características',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                // Detalles del cliente
                pw.Text(
                  'Detalles del Cliente',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Nombre: $clientName'),
                pw.Text('Correo Electrónico: $clientEmail'),
                pw.Text('Teléfono: $clientPhone'),
                pw.SizedBox(height: 20),

                // Footer
                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                  'Desarrollado por Antonio Barrios',
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
