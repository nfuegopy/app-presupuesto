import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  // CAMBIO: Ahora es 'nullable' (?) para permitir pasar null y deshabilitarlo
  final ValueChanged<String?>? onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged, // Ya no es 'required' estricto, puede ser null
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Detectamos si está habilitado
    final isEnabled = onChanged != null;

    // Colores dinámicos según estado (Habilitado / Deshabilitado)
    final baseFillColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final fillColor =
        isEnabled ? baseFillColor : baseFillColor.withOpacity(0.5);

    final baseIconColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final iconColor =
        isEnabled ? baseIconColor : baseIconColor!.withOpacity(0.3);

    final labelOpacity = isEnabled ? 0.7 : 0.4;
    final textOpacity = isEnabled ? 1.0 : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(labelOpacity),
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Seleccionar',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(textOpacity * 0.4)),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: iconColor,
              ),
              // Si onChanged es null, Flutter deshabilita el dropdown automáticamente
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(textOpacity),
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
