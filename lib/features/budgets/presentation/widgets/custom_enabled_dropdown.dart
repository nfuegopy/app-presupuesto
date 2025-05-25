import 'package:flutter/material.dart';

class CustomEnabledDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?)? onChanged;
  final bool enabled;

  const CustomEnabledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Seleccione $label',
            filled: true,
            fillColor: enabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          dropdownColor: Theme.of(context).colorScheme.surface,
          isExpanded: true,
        ),
      ],
    );
  }
}
