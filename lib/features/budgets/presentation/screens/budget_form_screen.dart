import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/custom_dropdown.dart';
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

    // Obtener el padding inferior del sistema (para la barra de navegación)
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Formulario de Presupuesto')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          16.0 + bottomPadding + 16.0, // Añadir padding adicional para la barra de navegación
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos del Cliente',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
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
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              label: 'Departamento',
              value: _departamento,
              items: departamentos,
              onChanged: (value) {
                setState(() {
                  _departamento = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              label: 'Ciudad',
              value: _ciudad,
              items: ciudades,
              onChanged: (value) {
                setState(() {
                  _ciudad = value;
                });
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Datos de la Máquina',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Máquina Seleccionada: ${widget.product.name}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tipo: ${widget.product.type}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Precio: ${widget.product.price} ${widget.product.currency}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (widget.product.imageUrl != null)
                      Image.network(
                        widget.product.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Propuesta de Pago',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              label: 'Moneda',
              value: _currency,
              items: const ['USD', 'GS'],
              onChanged: (value) {
                setState(() {
                  _currency = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              label: 'Precio',
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              label: 'Forma de Pago',
              value: _paymentMethod,
              items: const ['Contado', 'Financiado'],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value;
                });
              },
            ),
            if (_paymentMethod == 'Financiado') ...[
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'Tipo de Financiamiento',
                value: _financingType,
                items: const ['Propia', 'Bancaria'],
                onChanged: (value) {
                  setState(() {
                    _financingType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _deliveryController,
                label: 'Entrega',
                keyboardType: TextInputType.number,
                isRequired: _financingType == 'Propia',
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'Frecuencia de Pago',
                value: _paymentFrequency,
                items: const ['Mensual', 'Trimestral', 'Semestral'],
                onChanged: (value) {
                  setState(() {
                    _paymentFrequency = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _numberOfInstallmentsController,
                label: 'Cantidad de Cuotas',
                keyboardType: TextInputType.number,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'Refuerzos',
                value: _hasReinforcements?.toString(),
                items: const ['false', 'true'],
                onChanged: (value) {
                  setState(() {
                    _hasReinforcements = value == 'true';
                  });
                },
              ),
              if (_hasReinforcements == true) ...[
                const SizedBox(height: 16),
                CustomDropdown(
                  label: 'Frecuencia de Refuerzos',
                  value: _reinforcementFrequency,
                  items: const ['Trimestral', 'Semestral', 'Anual'],
                  onChanged: (value) {
                    setState(() {
                      _reinforcementFrequency = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _numberOfReinforcementsController,
                  label: 'Cantidad de Refuerzos',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _reinforcementAmountController,
                  label: 'Monto de Refuerzos',
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ],
            ],
            const SizedBox(height: 32),
            if (budgetProvider.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  budgetProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
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

                if (budgetProvider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(budgetProvider.error!)),
                  );
                  return;
                }

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