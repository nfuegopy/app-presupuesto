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
  final TextEditingController _searchController = TextEditingController();
  List<ClientModel> _filteredClients = [];
  ClientModel? _selectedClient;

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.clients;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    widget.onSearchChanged(query);
    setState(() {
      _filteredClients = widget.clients.where((client) {
        final razonSocial = client.razonSocial.toLowerCase();
        final ruc = client.ruc.toLowerCase();
        return razonSocial.contains(query) || ruc.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar Cliente (Razón Social o RUC)',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButton<ClientModel>(
          value: _selectedClient,
          hint: const Text('Seleccionar Cliente'),
          isExpanded: true,
          items: _filteredClients.map((client) {
            return DropdownMenuItem<ClientModel>(
              value: client,
              child: Text('${client.razonSocial} (${client.ruc})'),
            );
          }).toList(),
          onChanged: (client) {
            setState(() {
              _selectedClient = client;
            });
            widget.onClientSelected(client);
          },
        ),
      ],
    );
  }
}
