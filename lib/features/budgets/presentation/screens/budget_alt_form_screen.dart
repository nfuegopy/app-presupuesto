import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/custom_dropdown.dart';
import '../widgets/custom_dw_budget.dart';
import '../../../products/domain/entities/product.dart';
import '../widgets/custom_tags_input_field.dart';
// import '../widgets/client_search_select.dart'; // Removed
import '../widgets/unified_client_search_field.dart'; // Added
import '../../data/models/client_model.dart';
import '../../data/models/paraguay_location.dart';
import '../utils/reinforcement_validator.dart';
import '../widgets/custom_enabled_dropdown.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class BudgetAltFormScreen extends StatefulWidget {
  const BudgetAltFormScreen({super.key});

  @override
  State<BudgetAltFormScreen> createState() => _BudgetAltFormScreenState();
}

class _BudgetAltFormScreenState extends State<BudgetAltFormScreen> {
  final _razonSocialController = TextEditingController();
  final _rucController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _numberOfInstallmentsController = TextEditingController();
  final _numberOfReinforcementsController = TextEditingController();
  final _reinforcementAmountController = TextEditingController();
  final _validityOfferController =
      TextEditingController(text: 'Valido 15 dias');
  final _benefitsController = TextEditingController();
  // String _searchQuery = ''; // To be managed by or within UnifiedClientSearchField
  bool _isNewClient = true; // Default to new client, will change on selection
  ClientModel? _selectedClient;

  String? _ciudad;
  String? _departamento;
  String? _currency;
  String? _paymentMethod;
  String? _financingType;
  String? _paymentFrequency;
  bool? _hasReinforcements;
  String? _reinforcementFrequency;
  String? _reinforcementMonth;
  Product? _selectedProduct;

  final _formKey = GlobalKey<FormState>(); // Added form key
  List<ParaguayLocation> _locations = [];
  List<String> _departamentos = [];
  List<String> _ciudades = [];

  final List<String> months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  final List<String> benefitOptions = [
    'Transferencia',
    'Flete',
    'Primer Mantenimiento',
    '500 Horas de Mantenimiento',
    '1000 Horas de Mantenimiento',
    'Protecciones Completas de cabina',
    'Rastrillo',
    'Tumbador',
    'Garra Forestal',
    'Tercera Via Hidraulica',
  ];

  @override
  void initState() {
    super.initState();
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    budgetProvider.loadClientsByVendor();
    _hasReinforcements = false;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final String response = await rootBundle.loadString('assets/paraguay.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _locations = data.map((json) => ParaguayLocation.fromJson(json)).toList();
      _departamentos = _locations.map((loc) => loc.departamento).toList();
    });
  }

  void _updateCiudades(String? departamento) {
    setState(() {
      _departamento = departamento;
      _ciudad = null; // Resetear ciudad al cambiar departamento
      if (departamento != null) {
        final selectedLocation = _locations.firstWhere(
          (loc) => loc.departamento == departamento,
          orElse: () => ParaguayLocation(departamento: '', ciudades: []),
        );
        _ciudades = selectedLocation.ciudades;
      } else {
        _ciudades = [];
      }
    });
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
    _validityOfferController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmación'),
            content: const Text(
              '¿Confirmas que realizaste el cálculo del presupuesto incluyendo los costos de beneficios y otros conceptos?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulario de Presupuesto Alternativo'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Volver',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          16.0 + bottomPadding + 16.0,
        ),
        child: Form( // Added Form widget
          key: _formKey, // Assign form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
              'Seleccionar Producto',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              label: 'Producto',
              value: _selectedProduct?.name,
              items: productProvider.products.map((p) => p.name).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProduct = productProvider.products
                      .firstWhere((p) => p.name == value);
                  budgetProvider.updateProduct(_selectedProduct!);
                  _priceController.text = _selectedProduct!.price.toString();
                  _currency = _selectedProduct!.currency;
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
            if (_selectedProduct != null)
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
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Por favor, seleccione un producto para continuar.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
            const SizedBox(height: 32),
            Text(
              'Datos del Cliente',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            UnifiedClientSearchField(
              suggestions: budgetProvider.clients,
              onClientSelected: (client) {
                setState(() {
                  _selectedClient = client;
                  _isNewClient = false;
                  _razonSocialController.text = client.razonSocial;
                  _rucController.text = client.ruc;
                  _emailController.text = client.email ?? '';
                  _telefonoController.text = client.telefono ?? '';
                  _departamento = client.departamento;
                  _ciudad = client.ciudad;
                  _updateCiudades(client.departamento);

                  budgetProvider.updateClient(
                    razonSocial: client.razonSocial,
                    ruc: client.ruc,
                    email: client.email,
                    telefono: client.telefono,
                    ciudad: client.ciudad,
                    departamento: client.departamento,
                    selectedClientId: client.id,
                  );
                });
              },
              onNewClientTyped: (value) {
                setState(() {
                  if (_selectedClient != null && value != '${_selectedClient!.razonSocial} (${_selectedClient!.ruc})') {
                    _selectedClient = null;
                    _isNewClient = true;
                    _razonSocialController.text = value;
                    _rucController.clear();
                    _emailController.clear();
                    _telefonoController.clear();
                    _departamento = null;
                    _ciudad = null;
                    _updateCiudades(null);
                  } else if (_selectedClient == null) {
                    _isNewClient = true;
                    _razonSocialController.text = value;
                     if (value.isEmpty) { // Reset other fields if main field is cleared
                        _rucController.clear();
                        _emailController.clear();
                        _telefonoController.clear();
                        _departamento = null;
                        _ciudad = null;
                        _updateCiudades(null);
                    }
                  }
                });
              },
              initialValue: _selectedClient != null
                  ? '${_selectedClient!.razonSocial} (${_selectedClient!.ruc})'
                  : _razonSocialController.text,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _razonSocialController,
              label: 'Razón Social (Autocompletado o Nuevo)',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _rucController,
              label: 'RUC (Autocompletado o Nuevo)',
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController, // Populated by onClientSelected or manual
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
              isRequired: true, // Set isRequired to true
            ),
            const SizedBox(height: 16),
            CustomEnabledDropdown(
              label: 'Departamento',
              value: _departamento,
              items: _departamentos,
              onChanged: _updateCiudades,
            ),
            const SizedBox(height: 16),
            CustomEnabledDropdown(
              label: 'Ciudad',
              value: _ciudad,
              items: _ciudades,
              onChanged: (value) {
                setState(() {
                  _ciudad = value;
                });
              },
              enabled: _departamento != null, // Deshabilitar si no hay departamento
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
            Text(
              'Datos del Préstamo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                  if (_paymentMethod != 'Financiado') {
                    _hasReinforcements = false;
                    _reinforcementFrequency = null;
                    _reinforcementMonth = null;
                  }
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
                isRequired: false,
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
                label: 'Frecuencia de Cuotas',
                value: _paymentFrequency,
                items: const ['Mensual', 'Trimestral', 'Semestral'],
                onChanged: (value) {
                  setState(() {
                    _paymentFrequency = value;
                    _hasReinforcements = false;
                    _reinforcementFrequency = null;
                    _reinforcementMonth = null;
                  });
                },
              ),
              if (_paymentFrequency != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Datos de Refuerzos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                CustomDwBudget<bool>(
                  label: 'Refuerzos',
                  value: _hasReinforcements,
                  items: const [
                    {'value': false, 'label': 'No'},
                    {'value': true, 'label': 'Sí'},
                  ],
                  itemToString: (item) => item['label'] as String,
                  onChanged: (item) {
                    setState(() {
                      _hasReinforcements =
                          item != null ? item['value'] as bool : false;
                      if (!_hasReinforcements!) {
                        _reinforcementFrequency = null;
                        _reinforcementMonth = null;
                      }
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
                        _reinforcementMonth = null;
                      });
                    },
                  ),
                  if (_reinforcementFrequency == 'Anual') ...[
                    const SizedBox(height: 16),
                    CustomDropdown(
                      label: 'Mes de Abono Anual',
                      value: _reinforcementMonth,
                      items: months,
                      onChanged: (value) {
                        setState(() {
                          _reinforcementMonth = value;
                        });
                      },
                    ),
                  ],
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
            ],
            const SizedBox(height: 16),
            CustomTextField(
              controller: _validityOfferController,
              label: 'Validez de la Oferta',
              isRequired: false,
            ),
            const SizedBox(height: 16),
            CustomTagsInputField(
              controller: _benefitsController,
              label: 'Beneficios',
              options: benefitOptions,
              isRequired: false,
            ),
            const SizedBox(height: 32),
            if (budgetProvider.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withOpacity(0.2),
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
                // Validate form
                if (!_formKey.currentState!.validate()) {
                  return; // If form is not valid, do not proceed
                }

                if (_selectedProduct == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, seleccione un producto')),
                  );
                  return;
                }

                if (_hasReinforcements == null && _paymentFrequency != null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Por favor, seleccione si incluye refuerzos')),
                  );
                  return;
                }

                bool confirmed = await _showConfirmationDialog();
                if (!confirmed) return;

                if (_hasReinforcements == true &&
                    _numberOfInstallmentsController.text.isNotEmpty &&
                    _paymentFrequency != null) {
                  final reinforcementError = validateReinforcements(
                    numberOfInstallments:
                        int.tryParse(_numberOfInstallmentsController.text) ?? 0,
                    paymentFrequency: _paymentFrequency!,
                    reinforcementFrequency: _reinforcementFrequency,
                    numberOfReinforcements: _numberOfReinforcementsController
                            .text.isNotEmpty
                        ? int.tryParse(_numberOfReinforcementsController.text)
                        : null,
                  );
                  if (reinforcementError != null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(reinforcementError)),
                    );
                    return;
                  }
                  if (_reinforcementFrequency == 'Anual' &&
                      _reinforcementMonth == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Por favor, seleccione el mes de abono anual')),
                    );
                    return;
                  }
                }

                // Determine if it's a new client based on _selectedClient being null
                if (_selectedClient == null) { // Implies new client
                  budgetProvider.updateClient(
                    razonSocial: _razonSocialController.text.trim(), // Values from the text fields
                    ruc: _rucController.text.trim(), // Values from the text fields
                    email: _emailController.text.trim(),
                    telefono: _telefonoController.text.trim(),
                    ciudad: _ciudad,
                    departamento: _departamento,
                    selectedClientId: null, // This will be updated/created
                  );
                } else { // Existing client selected
                  budgetProvider.updateClient(
                    razonSocial: _selectedClient!.razonSocial,
                    ruc: _selectedClient!.ruc,
                    email: _emailController.text.trim(), // Allow editing email
                    telefono: _telefonoController.text.trim(), // Allow editing phone
                    ciudad: _ciudad, // Allow editing location
                    departamento: _departamento, // Allow editing location
                    selectedClientId: _selectedClient!.id,
                  );
                }
                // Removed the third 'else' block as it's redundant with _selectedClient == null

                if (budgetProvider.error != null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(budgetProvider.error!)),
                  );
                  return;
                }

                budgetProvider.updatePaymentDetails(
                  currency: _currency ?? _selectedProduct!.currency,
                  price: double.tryParse(_priceController.text) ??
                      _selectedProduct!.price,
                  paymentMethod: _paymentMethod ?? 'Contado',
                  financingType: _financingType,
                  delivery: _deliveryController.text.isNotEmpty
                      ? double.parse(_deliveryController.text)
                      : 0,
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
                  reinforcementMonth: _reinforcementMonth,
                  validityOffer: _validityOfferController.text.trim(),
                  benefits: _benefitsController.text.trim(),
                );

                if (budgetProvider.error != null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(budgetProvider.error!)),
                  );
                  return;
                }

                await budgetProvider.createBudget();
                if (budgetProvider.error != null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(budgetProvider.error!)),
                  );
                  return;
                }

                await budgetProvider.saveAndSharePdf(context);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Presupuesto generado y guardado')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}