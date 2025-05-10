import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool isRequired;

  CustomTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: OutlineInputBorder(),
        errorText: isRequired && controller.text.isEmpty
            ? 'Este campo es obligatorio'
            : null,
      ),
    );
  }
}
