import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../../../products/domain/entities/product.dart';

class BudgetFormScreen extends StatefulWidget {
  final Product product;

  const BudgetFormScreen({super.key, required this.product});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _razonSocialController = TextEditingController();
  final _rucController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _numberOfInstallmentsController = TextEditingController();
  final _numberOfReinforcementsController = TextEditingController();
  final _reinforcementAmountController = TextEditingController();
  String? _ciudad;
  String? _departamento;
  String? _currency;
  String? _paymentMethod;
  String? _financingType;
  String? _paymentFrequency;
  bool? _hasReinforcements;
  String? _reinforcementFrequency;

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
  void initState() {
    super.initState();
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    budgetProvider.updateProduct(widget.product);
    _priceController.text = widget.product.price.toString();
    _currency = widget.product.currency;
  }

  @override
  void dispose() {
    _razonSocialController.dispose();
    _rucController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _priceController.dispose();
    _deliveryController.dispose();
    _numberOfInstallmentsController.dispose();
    _numberOfReinforcementsController.dispose();
    _reinforcementAmountController.dispose();
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
            Text('Datos del Cliente',
                style: Theme.of(context).textTheme.titleLarge),
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
              isRequired: true,
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
            Text('Datos de la Máquina',
                style: Theme.of(context).textTheme.titleLarge),
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
                    Text(
                        'Precio: ${widget.product.price} ${widget.product.currency}'),
                    if (widget.product.imageUrl != null)
                      Image.network(widget.product.imageUrl!,
                          width: 100, height: 100),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Propuesta de Pago',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currency,
              hint: const Text('Moneda'),
              items: ['USD', 'GS'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _currency = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Moneda',
              ),
              validator: (value) => value == null ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              label: 'Precio',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              hint: const Text('Forma de Pago'),
              items: ['Contado', 'Financiado'].map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Forma de Pago',
              ),
              validator: (value) => value == null ? 'Campo obligatorio' : null,
            ),
            if (_paymentMethod == 'Financiado') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _financingType,
                hint: const Text('Tipo de Financiamiento'),
                items: ['Propia', 'Bancaria'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _financingType = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Tipo de Financiamiento',
                ),
                validator: (value) =>
                    value == null ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _deliveryController,
                label: 'Entrega',
                isRequired: _financingType == 'Propia',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentFrequency,
                hint: const Text('Frecuencia de Pago'),
                items: ['Mensual', 'Trimestral', 'Semestral'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentFrequency = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Frecuencia de Pago',
                ),
                validator: (value) =>
                    value == null ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _numberOfInstallmentsController,
                label: 'Cantidad de Cuotas',
                isRequired: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool>(
                value: _hasReinforcements,
                hint: const Text('Refuerzos'),
                items: [
                  const DropdownMenuItem(value: false, child: Text('No')),
                  const DropdownMenuItem(value: true, child: Text('Sí')),
                ],
                onChanged: (value) {
                  setState(() {
                    _hasReinforcements = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Refuerzos',
                ),
              ),
              if (_hasReinforcements == true) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _reinforcementFrequency,
                  hint: const Text('Frecuencia de Refuerzos'),
                  items: ['Trimestral', 'Semestral', 'Anual'].map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _reinforcementFrequency = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Frecuencia de Refuerzos',
                  ),
                  validator: (value) =>
                      value == null ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _numberOfReinforcementsController,
                  label: 'Cantidad de Refuerzos',
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _reinforcementAmountController,
                  label: 'Monto de Refuerzos',
                  isRequired: true,
                ),
              ],
            ],
            const SizedBox(height: 32),
            if (budgetProvider.error != null)
              Text(
                budgetProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Guardar y Generar Presupuesto',
              onPressed: () async {
                budgetProvider.updateClient(
                  razonSocial: _razonSocialController.text.trim(),
                  ruc: _rucController.text.trim(),
                  email: _emailController.text.trim(),
                  telefono: _telefonoController.text.trim(),
                  ciudad: _ciudad,
                  departamento: _departamento,
                );

                if (budgetProvider.error != null) return;

                budgetProvider.updatePaymentDetails(
                  currency: _currency ?? widget.product.currency,
                  price: double.tryParse(_priceController.text) ??
                      widget.product.price,
                  paymentMethod: _paymentMethod ?? 'Contado',
                  financingType: _financingType,
                  delivery: _deliveryController.text.isNotEmpty
                      ? double.parse(_deliveryController.text)
                      : null,
                  paymentFrequency: _paymentFrequency,
                  numberOfInstallments:
                      _numberOfInstallmentsController.text.isNotEmpty
                          ? int.parse(_numberOfInstallmentsController.text)
                          : null,
                  hasReinforcements: _hasReinforcements,
                  reinforcementFrequency: _reinforcementFrequency,
                  numberOfReinforcements:
                      _numberOfReinforcementsController.text.isNotEmpty
                          ? int.parse(_numberOfReinforcementsController.text)
                          : null,
                  reinforcementAmount:
                      _reinforcementAmountController.text.isNotEmpty
                          ? double.parse(_reinforcementAmountController.text)
                          : null,
                );

                if (budgetProvider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(budgetProvider.error!)),
                  );
                  return;
                }

                await budgetProvider.createBudget();
                if (budgetProvider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(budgetProvider.error!)),
                  );
                  return;
                }

                await budgetProvider.saveAndSharePdf();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Presupuesto generado y guardado')),
                );
                budgetProvider.clear();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
