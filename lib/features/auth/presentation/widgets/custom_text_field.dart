import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool isRequired;
  // final String? errorText; // errorText will be handled by the validator
  final IconData? prefixIcon;
  final int? maxLines;
  final String? Function(String?)? validator; // Added validator property

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.isRequired = false,
    // this.errorText,
    this.prefixIcon,
    this.maxLines = 1,
    this.validator, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField( // Changed from TextField to TextFormField
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Theme.of(context).colorScheme.primary)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, // Borde neón
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF00E5FF), // Borde neón más brillante al enfocar
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        // errorText: errorText, // Handled by validator
        errorStyle: TextStyle(color: Theme.of(context).colorScheme.error),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ?? // Use provided validator or default if isRequired
          (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
      autovalidateMode: AutovalidateMode.onUserInteraction, // Optional: validate as user types
    );
  }
}
