import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cotizacion_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/custom_dropdown.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_provider.dart';

class CotizacionFormScreen extends StatefulWidget {
  const CotizacionFormScreen({super.key});

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen> {
  Product? _selectedProduct;
  final _razonSocialController = TextEditingController();
  final _rucController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _numberOfInstallmentsController = TextEditingController();
  final _numberOfReinforcementsController = TextEditingController();
  final _reinforcementAmountController = TextEditingController();
  final _offerController = TextEditingController();
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
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cotizacionProvider = Provider.of<CotizacionProvider>(context);

    // Obtener el padding inferior del sistema (para la barra de navegación)
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Formulario de Presupuesto')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          16.0 + bottomPadding + 16.0,
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
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (productProvider.errorMessage != null) {
                  return Text(
                    productProvider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  );
                }
                final products = productProvider.products;
                final productNames = products.map((p) => p.name).toList();
                return CustomDropdown(
                  label: 'Seleccionar Máquina',
                  value: _selectedProduct?.name,
                  items: productNames,
                  onChanged: (value) {
                    setState(() {
                      _selectedProduct = products.firstWhere((p) => p.name == value);
                      final cotizacionProvider = Provider.of<CotizacionProvider>(context, listen: false);
                      cotizacionProvider.updateProduct(_selectedProduct!);
                      _priceController.text = _selectedProduct!.price.toString();
                      _currency = _selectedProduct!.currency;
                    });
                  },
                );
              },
            ),
            if (_selectedProduct != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Máquina Seleccionada: ${_selectedProduct!.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo: ${_selectedProduct!.type}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Precio: ${_selectedProduct!.price} ${_selectedProduct!.currency}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_selectedProduct!.imageUrl != null)
                        Image.network(
                          _selectedProduct!.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
            const SizedBox(height: 16),
            CustomTextField(
              controller: _offerController,
              label: 'Ofrecemos',
              keyboardType: TextInputType.multiline,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            if (cotizacionProvider.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cotizacionProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Guardar y Generar Presupuesto',
              onPressed: () async {
                if (_selectedProduct == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, seleccione una máquina.')),
                  );
                  return;
                }
                cotizacionProvider.updateClient(
                  razonSocial: _razonSocialController.text.trim(),
                  ruc: _rucController.text.trim(),
                  email: _emailController.text.trim(),
                  telefono: _telefonoController.text.trim(),
                  ciudad: _ciudad,
                  departamento: _departamento,
                );

                if (cotizacionProvider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(cotizacionProvider.error!)),
                  );
                  return;
                }

                cotizacionProvider.updatePaymentDetails(
                  currency: _currency ?? _selectedProduct!.currency,
                  price: double.tryParse(_priceController.text) ?? _selectedProduct!.price,
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
                  offer: _offerController.text.trim(),
                );

                if (cotizacionProvider.error != null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(cotizacionProvider.error!)),
                  );
                  return;
                }

                await cotizacionProvider.createCotizacion();
                if (cotizacionProvider.error != null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(cotizacionProvider.error!)),
                  );
                  return;
                }

                await cotizacionProvider.saveAndSharePdf(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Presupuesto generado y guardado')),
                );
                cotizacionProvider.clear();
                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}