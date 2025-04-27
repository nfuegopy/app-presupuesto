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
    return GestureDetector(
      onTapDown: isLoading
          ? null
          : (_) {
              // Feedback visual al presionar
            },
      onTapUp: isLoading
          ? null
          : (_) {
              onPressed();
            },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: isLoading ? 1.0 : 1.0, // Escala no cambia mientras está cargando
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.primary, // Fondo neón
            foregroundColor: Theme.of(context).colorScheme.onPrimary, // Texto
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
              : Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
        ),
      ),
    );
  }
}
