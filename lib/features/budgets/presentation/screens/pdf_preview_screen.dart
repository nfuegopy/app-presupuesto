// File: nfuegopy/app-presupuesto/app-presupuesto-da449cfc3e7d0ae6b62ba849dde1f34919f41601/lib/features/budgets/presentation/screens/pdf_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final VoidCallback onShare;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.onShare,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica si los bytes del PDF están vacíos o son nulos, mostrando un mensaje de error si es así.
    if (pdfBytes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error de Previsualización'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Volver',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 80),
              SizedBox(height: 16),
              Text(
                'No se pudo generar el documento PDF.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Por favor, revise los datos ingresados y vuelva a intentarlo.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      // START MODIFICATION: Se añade un bloque 'else' explícito.
      return Scaffold(
        appBar: AppBar(
          title: const Text('Previsualización del Presupuesto'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: PdfPreview(
          build: (format) => pdfBytes,
          allowPrinting: false,
          allowSharing: true,
          canChangePageFormat: false,
          canDebug: false,
          onError: (context, error) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al renderizar PDF: ${error.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            });
            debugPrint('PdfPreview onError: $error');
            return Center(
              child: Text(
                'Error al renderizar PDF.',
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            onShare();
            Navigator.pop(context);
          },
          label: const Text('Compartir'),
          icon: const Icon(Icons.share),
        ),
      );
    } // END MODIFICATION
  }
}
