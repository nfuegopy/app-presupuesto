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
        allowSharing: false,
        canChangePageFormat: false,
        canDebug: false,
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
  }
}
