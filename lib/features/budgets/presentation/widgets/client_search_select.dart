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
  ClientModel? _selectedClient;

  @override
  Widget build(BuildContext context) {
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
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Buscar Cliente (Razón Social o RUC)',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          onSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<ClientModel> onSelected,
          Iterable<ClientModel> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200.0, // Adjust height as needed
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final ClientModel option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${option.razonSocial} (${option.ruc})'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
