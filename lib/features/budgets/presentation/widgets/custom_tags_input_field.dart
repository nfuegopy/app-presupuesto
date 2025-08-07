import 'package:flutter/material.dart';

class CustomTagsInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final List<String> options;
  final bool isRequired;

  const CustomTagsInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.options,
    this.isRequired = false,
  });

  @override
  State<CustomTagsInputField> createState() => _CustomTagsInputFieldState();
}

class _CustomTagsInputFieldState extends State<CustomTagsInputField> {
  List<String> selectedTags = [];
  late TextEditingController _internalController;
  // Controlador para el nuevo campo de texto de beneficios personalizados
  final _customBenefitController = TextEditingController();
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    if (widget.controller.text.isNotEmpty) {
      selectedTags =
          widget.controller.text.split(', ').map((tag) => tag.trim()).toList();
    }
    widget.controller.addListener(_updateSelectedTags);
  }

  void _updateSelectedTags() {
    final text = widget.controller.text;
    if (text.isNotEmpty) {
      setState(() {
        selectedTags = text
            .split(', ')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
      });
    } else {
      setState(() {
        selectedTags = [];
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSelectedTags);
    _internalController.dispose();
    _customBenefitController
        .dispose(); // No olvides liberar el controlador nuevo
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.isRequired)
              const Text(
                '*',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Widget de autocompletado para las opciones predefinidas
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return widget.options
                  .where((option) => !selectedTags.contains(option));
            }
            return widget.options.where((option) =>
                option
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()) &&
                !selectedTags.contains(option));
          },
          onSelected: (String selection) {
            setState(() {
              if (!selectedTags.contains(selection)) {
                selectedTags.add(selection);
                widget.controller.text = selectedTags.join(', ');
                _internalController.clear();
                _focusNode.unfocus();
              }
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _internalController = controller;
            _focusNode = focusNode;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: selectedTags.isEmpty
                    ? 'Seleccione o busque beneficios'
                    : 'Añadir más beneficios...',
                errorText: widget.isRequired && selectedTags.isEmpty
                    ? 'Este campo es obligatorio'
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // NUEVA SECCIÓN: Campo de texto para beneficios personalizados
        Text(
          'Otro Beneficio (Opcional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customBenefitController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Escriba un beneficio y presione +',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () {
                final newTag = _customBenefitController.text.trim();
                if (newTag.isNotEmpty && !selectedTags.contains(newTag)) {
                  setState(() {
                    selectedTags.add(newTag);
                    widget.controller.text = selectedTags.join(', ');
                    _customBenefitController.clear();
                  });
                }
              },
            ),
          ],
        ),
        // FIN DE LA NUEVA SECCIÓN
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          // El `Wrap` con los `Chip` mostrará todos los beneficios
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    selectedTags.remove(tag);
                    widget.controller.text = selectedTags.join(', ');
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
