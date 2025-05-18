import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool isRequired;
  final IconData? prefixIcon;

  const EmailTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.isRequired = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.emailAddress,
      inputFormatters: [EmailPrefixFormatter()],
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        errorText: isRequired && controller.text.isEmpty
            ? 'Este campo es obligatorio'
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      ),
    );
  }
}

class EmailPrefixFormatter extends TextInputFormatter {
  final String fixedDomain = '@enginepy.com';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newPrefix = newValue.text.startsWith(fixedDomain)
        ? ''
        : newValue.text.replaceAll(fixedDomain, '');

    // Filtrar caracteres no válidos para el prefijo
    newPrefix = newPrefix.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '');

    // Combinar prefijo con dominio
    String newText = newPrefix + fixedDomain;

    // Mantener el cursor antes del dominio
    int cursorPosition = newPrefix.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
