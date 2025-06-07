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
                _focusNode.unfocus(); // Perder el foco tras seleccionar
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
                    ? 'Seleccione beneficios'
                    : selectedTags.join(', '),
                errorText: widget.isRequired && selectedTags.isEmpty
                    ? 'Este campo es obligatorio'
                    : null,
              ),
              onChanged: (value) {
                if (value.endsWith(',') || value.endsWith(', ')) {
                  final newTag = value
                      .substring(
                          0, value.length - (value.endsWith(', ') ? 2 : 1))
                      .trim();
                  if (newTag.isNotEmpty &&
                      widget.options.contains(newTag) &&
                      !selectedTags.contains(newTag)) {
                    setState(() {
                      selectedTags.add(newTag);
                      widget.controller.text = selectedTags.join(', ');
                      controller.clear();
                      _focusNode.unfocus(); // Perder el foco tras añadir
                    });
                  }
                }
              },
              onSubmitted: (value) {
                final newTag = value.trim();
                if (newTag.isNotEmpty &&
                    widget.options.contains(newTag) &&
                    !selectedTags.contains(newTag)) {
                  setState(() {
                    selectedTags.add(newTag);
                    widget.controller.text = selectedTags.join(', ');
                    controller.clear();
                    _focusNode.unfocus(); // Perder el foco tras submit
                  });
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
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
