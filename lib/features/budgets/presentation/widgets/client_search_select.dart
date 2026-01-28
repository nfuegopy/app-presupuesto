import 'package:flutter/material.dart';
import '../../data/models/client_model.dart';

class ClientSearchSelect extends StatefulWidget {
  final List<ClientModel> clients;
  final ValueChanged<ClientModel?> onClientSelected;
  final ValueChanged<String> onSearchChanged;

  const ClientSearchSelect({
    super.key,
    required this.clients,
    required this.onClientSelected,
    required this.onSearchChanged,
  });

  @override
  State<ClientSearchSelect> createState() => _ClientSearchSelectState();
}

class _ClientSearchSelectState extends State<ClientSearchSelect> {
  // ignore: unused_field
  ClientModel? _selectedClient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Colores modernos
    final fillColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final iconColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Autocomplete<ClientModel>(
      displayStringForOption: (ClientModel option) =>
          '${option.razonSocial} (${option.ruc})',

      optionsBuilder: (TextEditingValue textEditingValue) {
        widget.onSearchChanged(textEditingValue.text);
        if (textEditingValue.text.isEmpty) {
          return const Iterable<ClientModel>.empty();
        }
        return widget.clients.where((ClientModel client) {
          final query = textEditingValue.text.toLowerCase();
          final razonSocial = client.razonSocial.toLowerCase();
          final ruc = client.ruc.toLowerCase();
          return razonSocial.contains(query) || ruc.contains(query);
        });
      },

      onSelected: (ClientModel selection) {
        setState(() {
          _selectedClient = selection;
        });
        widget.onClientSelected(selection);
      },

      // --- CAMPO DE TEXTO MODERNO ---
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          style: TextStyle(
              fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Buscar Cliente (Razón Social o RUC)',
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            hintText: 'Escribe para buscar...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            prefixIcon: Icon(Icons.search_rounded, color: iconColor),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: iconColor, size: 20),
                    onPressed: () {
                      textEditingController.clear();
                      widget.onSearchChanged('');
                      setState(() {
                        _selectedClient = null;
                      });
                      widget.onClientSelected(null);
                    },
                  )
                : null,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },

      // --- LISTA DE OPCIONES FLOTANTE (CORREGIDA) ---
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<ClientModel> onSelected,
          Iterable<ClientModel> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              // Ancho dinámico ajustado al padding de la pantalla (24px a cada lado = 48px)
              width: MediaQuery.of(context).size.width - 48,

              // --- CORRECCIÓN CLAVE ---
              // Aumentamos el margen superior para que la lista baje y no tape el campo de texto.
              // El campo mide aprox 60px de alto, así que usamos 70px para dar espacio.
              margin: const EdgeInsets.only(top: 70),

              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 250),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ClientModel option = options.elementAt(index);
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          title: Text(
                            option.razonSocial,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'RUC: ${option.ruc}',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                          ),
                          onTap: () {
                            onSelected(option);
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        if (index < options.length - 1)
                          Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.1)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
