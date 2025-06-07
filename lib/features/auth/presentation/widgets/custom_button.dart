import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed:
          isLoading ? null : onPressed, // Deshabilitar cuando está cargando
      style: ElevatedButton.styleFrom(
        minimumSize:
            const Size(double.infinity, 50), // Ancho completo, altura 50
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 12), // Más padding
        backgroundColor: Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.8), // Fondo translúcido
        foregroundColor: Colors.white, // Color del texto/iconos
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bordes redondeados
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.5), // Borde neón
            width: 1,
          ),
        ),
        elevation: 4, // Sombra sutil
        shadowColor: Colors.black.withOpacity(0.2), // Color de la sombra
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold, // Texto más destacado
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(text),
    );
  }
}
