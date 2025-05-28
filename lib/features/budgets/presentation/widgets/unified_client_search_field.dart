import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../data/models/client_model.dart';
import '../providers/budget_provider.dart'; // Import BudgetProvider

class UnifiedClientSearchField extends StatefulWidget {
  final Function(ClientModel) onClientSelected;
  final Function(String) onNewClientTyped; // Callback for new client input
  // final List<ClientModel> suggestions; // Will be fetched from BudgetProvider
  final String? initialValue;

  const UnifiedClientSearchField({
    Key? key,
    required this.onClientSelected,
    required this.onNewClientTyped,
    // this.suggestions = const [], // Removed: will use provider
    this.initialValue,
  }) : super(key: key);

  @override
  _UnifiedClientSearchFieldState createState() =>
      _UnifiedClientSearchFieldState();
}

class _UnifiedClientSearchFieldState extends State<UnifiedClientSearchField> {
  // TextEditingController is managed by Autocomplete or passed to fieldViewBuilder
  // final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);

    return Autocomplete<ClientModel>(
      displayStringForOption: (ClientModel option) =>
          '${option.razonSocial} (${option.ruc})',
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          // Clear previous search results when input is empty
          if (budgetProvider.clientSearchResults.isNotEmpty) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                budgetProvider.fetchClientSuggestions(''); // Clears results in provider
             });
          }
          return const Iterable<ClientModel>.empty();
        }
        // Fetch suggestions using the provider
        // The actual list building will happen in optionsViewBuilder based on provider's state
        await budgetProvider.fetchClientSuggestions(textEditingValue.text);
        return budgetProvider.clientSearchResults;
      },
      onSelected: (ClientModel selection) {
        widget.onClientSelected(selection);
        // The text field will be updated by Autocomplete itself using displayStringForOption
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        
        // Set initial value if provided
        if (widget.initialValue != null && fieldTextEditingController.text.isEmpty) {
            fieldTextEditingController.text = widget.initialValue!;
        }

        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: const InputDecoration(
            labelText: 'Buscar Cliente (Razón Social / RUC)',
            hintText: 'Escriba para buscar o ingresar nuevo cliente',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            // This callback is important for the parent to know the text content
            // for new client detection or clearing selection.
            widget.onNewClientTyped(value);
          },
          // onFieldSubmitted is handled by Autocomplete's onSelected,
          // or if user presses enter without selection, it's a new client.
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
              // Constrain height if necessary, or let it size by content
              // height: 200.0, 
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final ClientModel option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text('${option.razonSocial} (${option.ruc})'),
                      // subtitle: Text(option.ruc), // Already in title
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
