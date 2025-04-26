import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/budget_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../../../products/domain/entities/product.dart';

class BudgetFormScreen extends StatefulWidget {
  final Product product;

  const BudgetFormScreen({super.key, required this.product});

  @override
  _BudgetFormScreenState createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _razonSocialController = TextEditingController();
  final _rucController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  String? _ciudad;
  String? _departamento;

  // Listas de ejemplo para departamentos y ciudades
  final List<String> departamentos = [
    'Central',
    'Alto Paraná',
    'Asunción',
    'Cordillera',
    'Itapúa',
  ];
  final List<String> ciudades = [
    'Asunción',
    'Ciudad del Este',
    'Encarnación',
    'Luque',
    'San Lorenzo',
  ];

  @override
  void dispose() {
    _razonSocialController.dispose();
    _rucController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Formulario de Presupuesto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datos del Cliente', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _razonSocialController,
              label: 'Razón Social',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _rucController,
              label: 'RUC',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'E-mail',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _telefonoController,
              label: 'Teléfono',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _departamento,
              hint: const Text('Departamento'),
              items: departamentos.map((departamento) {
                return DropdownMenuItem(
                  value: departamento,
                  child: Text(departamento),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _departamento = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _ciudad,
              hint: const Text('Ciudad'),
              items: ciudades.map((ciudad) {
                return DropdownMenuItem(
                  value: ciudad,
                  child: Text(ciudad),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _ciudad = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            Text('Datos de la Máquina', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Máquina Seleccionada: ${widget.product.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Tipo: ${widget.product.type}'),
                    Text('Precio: ${widget.product.price} ${widget.product.currency}'),
                    if (widget.product.imageUrl != null)
                      Image.network(widget.product.imageUrl!, width: 100, height: 100),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Propuesta de Pago', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('Próximamente: Detalles de pago'),
            const SizedBox(height: 16),
            if (budgetProvider.error != null)
              Text(
                budgetProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Guardar Datos del Cliente',
              onPressed: () {
                budgetProvider.updateClient(
                  razonSocial: _razonSocialController.text.trim(),
                  ruc: _rucController.text.trim(),
                  email: _emailController.text.trim(),
                  telefono: _telefonoController.text.trim(),
                  ciudad: _ciudad,
                  departamento: _departamento,
                );
                if (budgetProvider.error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos del cliente guardados')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}