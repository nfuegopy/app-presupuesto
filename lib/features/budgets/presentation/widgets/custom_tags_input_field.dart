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
    _customBenefitController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final iconColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: RichText(
            text: TextSpan(
              text: widget.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                  ),
              children: [
                if (widget.isRequired)
                  TextSpan(
                    text: ' *',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
        ),

        // Autocomplete Field
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
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: selectedTags.isEmpty
                    ? 'Seleccionar de la lista...'
                    : 'Añadir otro...',
                hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4)),
                filled: true,
                fillColor: fillColor,
                prefixIcon:
                    Icon(Icons.sell_outlined, color: iconColor, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Campo personalizado
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Otro Beneficio (Personalizado)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.7),
                ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customBenefitController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Escribe y presiona +',
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4)),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: Icon(Icons.add_rounded,
                    color: Theme.of(context).colorScheme.primary),
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
            ),
          ],
        ),

        // Chips
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1)),
                ),
                deleteIcon:
                    Icon(Icons.close_rounded, size: 16, color: Colors.grey),
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
