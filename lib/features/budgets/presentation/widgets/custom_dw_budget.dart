import 'package:flutter/material.dart';

class CustomDwBudget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) itemToString;
  final ValueChanged<Map<String, dynamic>?>? onChanged; // Cambiado a nullable

  const CustomDwBudget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemToString,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: items.firstWhere(
            (item) => item['value'] == value,
            orElse: () => {}, // Mapa vacío si no hay coincidencia
          ),
          hint: Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.primary,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          dropdownColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          items: items.map((item) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: item,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 64,
                ),
                child: Text(
                  itemToString(item),
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
