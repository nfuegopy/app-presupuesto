import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../providers/budget_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/custom_dropdown.dart';
import '../../../products/domain/entities/product.dart';
import '../widgets/custom_tags_input_field.dart';
import '../widgets/client_search_select.dart';
import '../../data/models/client_model.dart';
import '../../data/models/paraguay_location.dart';
import '../utils/reinforcement_validator.dart';
import 'pdf_preview_screen.dart';

class BudgetFormScreen extends StatefulWidget {
  final Product product;

  const BudgetFormScreen({super.key, required this.product});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  // --- CONTROLADORES ---
  final _razonSocialController = TextEditingController();
  final _rucController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _deliveryVehicleController = TextEditingController();
  final _numberOfInstallmentsController = TextEditingController();
  final _numberOfReinforcementsController = TextEditingController();
  final _reinforcementAmountController = TextEditingController();
  final _validityOfferController =
      TextEditingController(text: 'Válido 15 días');
  final _commercialConditionsController =
      TextEditingController(text: 'Plazo de Entrega 10 días');
  final _benefitsController = TextEditingController();
  final _reinforcementYearController =
      TextEditingController(text: (DateTime.now().year + 1).toString());

  // Descuento
  bool _hasDiscount = false;
  final _realPriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();

  // --- ESTADO ---
  // ignore: unused_field
  String _searchQuery = '';
  bool _isNewClient = false;
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
  String? _clientType;
  bool _isLoading = false;

  // Datos Geográficos
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
    'Garantía: 12 meses o 2.000 horas',
    'Transferencia',
    'Flete',
    'Primer Mantenimiento',
    '500 Horas de Mantenimiento',
    '1000 Horas de Mantenimiento',
    'Protecciones Completas de cabina',
    'Rastrillo',
    'Tumbador',
    'Garra Forestal',
    'Tercera Vía Hidráulica',
  ];

  @override
  void initState() {
    super.initState();
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    budgetProvider.updateProduct(widget.product);
    budgetProvider.loadClientsByVendor();
    _priceController.text = widget.product.price.toString();
    _currency = widget.product.currency;
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
      _ciudad = null;
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
    _deliveryVehicleController.dispose();
    _numberOfInstallmentsController.dispose();
    _numberOfReinforcementsController.dispose();
    _reinforcementAmountController.dispose();
    _validityOfferController.dispose();
    _commercialConditionsController.dispose();
    _benefitsController.dispose();
    _reinforcementYearController.dispose();
    _realPriceController.dispose();
    _discountPercentageController.dispose();
    super.dispose();
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Confirmar Presupuesto'),
            content: const Text(
              '¿Has verificado todos los costos, incluyendo beneficios y descuentos?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Revisar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nuevo Presupuesto',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 10, 24, 24 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER DE MÁQUINA (DISEÑO ULTRA-MINIMALISTA) ---
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    // Imagen pequeña
                    if (widget.product.imageUrl != null)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(widget.product.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(Icons.construction, color: Colors.grey[400]),
                      ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.product.price} ${widget.product.currency}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Datos del Cliente'),
            const SizedBox(height: 16),

            // --- SELECCIÓN DE CLIENTE ---
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _isNewClient,
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    onChanged: (value) {
                      setState(() {
                        _isNewClient = value ?? false;
                        _selectedClient = null;
                        if (_isNewClient) {
                          // Limpiar formulario para nuevo cliente
                          _razonSocialController.clear();
                          _rucController.clear();
                          _emailController.clear();
                          _telefonoController.clear();
                          _ciudad = null;
                          _departamento = null;
                          _updateCiudades(null);
                          _clientType = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Es Cliente Nuevo',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Si NO es nuevo, mostrar buscador
            if (!_isNewClient)
              ClientSearchSelect(
                clients: budgetProvider.clients,
                onClientSelected: (client) {
                  setState(() {
                    _selectedClient = client;
                    if (client != null) {
                      // Autocompletar datos
                      _razonSocialController.text = client.razonSocial;
                      _rucController.text = client.ruc;
                      _emailController.text = client.email ?? '';
                      _telefonoController.text = client.telefono ?? '';
                      _ciudad = client.ciudad;
                      _departamento = client.departamento;
                      _updateCiudades(_departamento);
                      _clientType = client.clientType;

                      budgetProvider.updateClient(
                        razonSocial: client.razonSocial,
                        ruc: client.ruc,
                        email: client.email,
                        telefono: client.telefono,
                        ciudad: client.ciudad,
                        departamento: client.departamento,
                        clientType: client.clientType,
                        selectedClientId: client.id,
                      );
                    } else {
                      // Limpiar si se deselecciona
                      _razonSocialController.clear();
                      _rucController.clear();
                      _emailController.clear();
                      _telefonoController.clear();
                      _ciudad = null;
                      _departamento = null;
                      _updateCiudades(null);
                      _clientType = null;

                      budgetProvider.updateClient(
                        razonSocial: '',
                        ruc: '',
                        selectedClientId: null,
                      );
                    }
                  });
                },
                onSearchChanged: (query) => _searchQuery = query,
              ),

            // Si ES nuevo, mostrar campos obligatorios extra
            if (_isNewClient) ...[
              CustomDropdown(
                label: 'Tipo de Cliente',
                value: _clientType,
                items: const ['Persona Física', 'Persona Jurídica'],
                onChanged: (value) => setState(() => _clientType = value),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _razonSocialController,
                label: 'Razón Social',
                isRequired: true,
                prefixIcon: Icons.business,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _rucController,
                label: 'RUC',
                isRequired: true,
                prefixIcon: Icons.badge_outlined,
              ),
            ],

            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: 'Departamento',
                    value: _departamento,
                    items: _departamentos,
                    onChanged: _updateCiudades,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown(
                    label: 'Ciudad',
                    value: _ciudad,
                    items: _ciudades,
                    onChanged: _departamento != null
                        ? (value) => setState(() => _ciudad = value)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            _buildSectionTitle('Plan Financiero'),
            const SizedBox(height: 20),

            // --- MONEDA ---
            CustomDropdown(
              label: 'Moneda',
              value: _currency,
              items: const ['USD', 'GS'],
              onChanged: (value) => setState(() => _currency = value),
            ),
            const SizedBox(height: 24),

            // --- SECCIÓN DE DESCUENTO (REDITADA PARA CLARIDAD) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aquí aplicamos el cambio solicitado: Título claro y opciones explícitas
                  CustomDropdown(
                    label: '¿Aplicar Descuento?',
                    value: _hasDiscount ? 'Sí, aplicar descuento' : 'No',
                    items: const ['No', 'Sí, aplicar descuento'],
                    onChanged: (value) {
                      setState(() {
                        _hasDiscount = value == 'Sí, aplicar descuento';
                      });
                    },
                  ),

                  if (_hasDiscount) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _realPriceController,
                            label: 'Precio Lista (Original)',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.money_off,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _discountPercentageController,
                      label: 'Porcentaje Descuento (%)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.percent,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ---------------------------------------------

            CustomTextField(
              controller: _priceController,
              label: _hasDiscount
                  ? 'Precio Final (Con Descuento)'
                  : 'Precio de Venta',
              keyboardType: TextInputType.number,
              isRequired: true,
              prefixIcon: Icons.attach_money,
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
              const SizedBox(height: 32),
              _buildSectionTitle('Financiamiento'),
              const SizedBox(height: 16),
              CustomDropdown(
                label: 'Tipo',
                value: _financingType,
                items: const ['Propia', 'Bancaria'],
                onChanged: (value) => setState(() => _financingType = value),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _deliveryController,
                label: 'Entrega Efectivo',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _deliveryVehicleController,
                label: 'Entrega de Usado',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _numberOfInstallmentsController,
                      label: 'Cant. Cuotas',
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown(
                      label: 'Frecuencia',
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
                  ),
                ],
              ),
              if (_paymentFrequency != null) ...[
                const SizedBox(height: 24),
                // Sección Refuerzos
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      CustomDropdown(
                        label: '¿Incluir Refuerzos?',
                        value: (_hasReinforcements ?? false) ? 'Sí' : 'No',
                        items: const ['No', 'Sí'],
                        onChanged: (value) {
                          setState(() {
                            _hasReinforcements = value == 'Sí';
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
                          label: 'Frecuencia Refuerzo',
                          value: _reinforcementFrequency,
                          items: const ['Trimestral', 'Semestral', 'Anual'],
                          onChanged: (value) {
                            setState(() {
                              _reinforcementFrequency = value;
                              _reinforcementMonth = null;
                            });
                          },
                        ),
                        if (_reinforcementFrequency == 'Anual' ||
                            _reinforcementFrequency == 'Semestral') ...[
                          const SizedBox(height: 16),
                          CustomDropdown(
                            label: 'Mes de Inicio',
                            value: _reinforcementMonth,
                            items: months,
                            onChanged: (value) =>
                                setState(() => _reinforcementMonth = value),
                          ),
                        ],
                        if (_reinforcementFrequency == 'Anual') ...[
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _reinforcementYearController,
                            label: 'Año de Inicio',
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _numberOfReinforcementsController,
                                label: 'Cant. Refuerzos',
                                keyboardType: TextInputType.number,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _reinforcementAmountController,
                                label: 'Monto',
                                keyboardType: TextInputType.number,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 40),
            _buildSectionTitle('Condiciones & Beneficios'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _commercialConditionsController,
              label: 'Condiciones Comerciales',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _validityOfferController,
              label: 'Validez de Oferta',
            ),
            const SizedBox(height: 16),
            CustomTagsInputField(
              controller: _benefitsController,
              label: 'Beneficios Incluidos',
              options: benefitOptions,
            ),

            const SizedBox(height: 32),

            // --- MENSAJE DE ERROR ---
            if (budgetProvider.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(budgetProvider.error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  ],
                ),
              ),

            // --- BOTÓN FINAL ---
            CustomButton(
              text: 'Generar Presupuesto PDF',
              onPressed: () async {
                if (_isLoading) return;

                // --- VALIDACIONES RÁPIDAS ---
                if (_hasReinforcements == null && _paymentFrequency != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Seleccione si incluye refuerzos')));
                  return;
                }
                if (_isNewClient && _clientType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Seleccione el tipo de cliente')));
                  return;
                }

                bool confirmed = await _showConfirmationDialog();
                if (!confirmed) return;

                // --- VALIDACIÓN DE REFUERZOS ---
                if (_hasReinforcements == true &&
                    _numberOfInstallmentsController.text.isNotEmpty &&
                    _paymentFrequency != null) {
                  final reinforcementError = validateReinforcements(
                    numberOfInstallments:
                        int.tryParse(_numberOfInstallmentsController.text) ?? 0,
                    paymentFrequency: _paymentFrequency!,
                    reinforcementFrequency: _reinforcementFrequency,
                    numberOfReinforcements:
                        int.tryParse(_numberOfReinforcementsController.text),
                  );
                  if (reinforcementError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(reinforcementError)));
                    return;
                  }
                  if ((_reinforcementFrequency == 'Anual' ||
                          _reinforcementFrequency == 'Semestral') &&
                      _reinforcementMonth == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Seleccione el mes de inicio de refuerzos')));
                    return;
                  }
                }

                // --- PARSEO DE PRECIOS ---
                final priceText = _priceController.text.trim();
                double? price;
                if (priceText.isNotEmpty) {
                  price = double.tryParse(priceText.replaceAll(',', '.'));
                  if (price == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Precio inválido')));
                    return;
                  }
                } else {
                  price = widget.product.price;
                }

                final realPrice = _realPriceController.text.isNotEmpty
                    ? double.tryParse(
                        _realPriceController.text.replaceAll(',', '.'))
                    : null;
                final discountPercentage = _discountPercentageController
                        .text.isNotEmpty
                    ? double.tryParse(
                        _discountPercentageController.text.replaceAll(',', '.'))
                    : null;

                // --- INICIO PROCESO ---
                setState(() => _isLoading = true);

                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  // 1. ACTUALIZAR CLIENTE
                  if (_isNewClient) {
                    budgetProvider.updateClient(
                      razonSocial: _razonSocialController.text.trim(),
                      ruc: _rucController.text.trim(),
                      email: _emailController.text.trim(),
                      telefono: _telefonoController.text.trim(),
                      ciudad: _ciudad,
                      departamento: _departamento,
                      clientType: _clientType,
                      selectedClientId: null,
                    );
                  } else if (_selectedClient != null) {
                    budgetProvider.updateClient(
                      razonSocial: _razonSocialController.text.trim(),
                      ruc: _rucController.text.trim(),
                      email: _emailController.text.trim(),
                      telefono: _telefonoController.text.trim(),
                      ciudad: _ciudad,
                      departamento: _departamento,
                      clientType: _selectedClient!.clientType,
                      selectedClientId: _selectedClient!.id,
                    );
                  } else {
                    // Fallback para actualización genérica
                    budgetProvider.updateClient(
                      razonSocial: _razonSocialController.text.trim(),
                      ruc: _rucController.text.trim(),
                      email: _emailController.text.trim(),
                      telefono: _telefonoController.text.trim(),
                      ciudad: _ciudad,
                      departamento: _departamento,
                      clientType: _clientType,
                      selectedClientId: null,
                    );
                  }

                  if (budgetProvider.error != null)
                    throw Exception(budgetProvider.error);

                  // 2. ACTUALIZAR DATOS PAGO
                  await budgetProvider.updatePaymentDetails(
                    currency: _currency ?? widget.product.currency,
                    price: price,
                    paymentMethod: _paymentMethod ?? 'Contado',
                    financingType: _financingType,
                    delivery: double.tryParse(_deliveryController.text) ?? 0.0,
                    deliveryVehicle:
                        double.tryParse(_deliveryVehicleController.text) ?? 0.0,
                    paymentFrequency: _paymentFrequency,
                    numberOfInstallments:
                        int.tryParse(_numberOfInstallmentsController.text),
                    hasReinforcements: _hasReinforcements,
                    reinforcementFrequency: _reinforcementFrequency,
                    numberOfReinforcements:
                        int.tryParse(_numberOfReinforcementsController.text),
                    reinforcementAmount:
                        double.tryParse(_reinforcementAmountController.text),
                    reinforcementMonth: _reinforcementMonth,
                    reinforcementYear:
                        int.tryParse(_reinforcementYearController.text),
                    validityOffer: _validityOfferController.text,
                    commercialConditions: _commercialConditionsController.text,
                    benefits: _benefitsController.text,
                    hasDiscount: _hasDiscount,
                    realPrice: realPrice,
                    discountPercentage: discountPercentage,
                  );

                  if (budgetProvider.error != null)
                    throw Exception(budgetProvider.error);

                  // 3. GUARDAR EN FIREBASE
                  await budgetProvider.createBudget();
                  if (budgetProvider.error != null)
                    throw Exception(budgetProvider.error);

                  // 4. GENERAR PDF
                  if (!context.mounted) return;
                  final pdfBytes =
                      await budgetProvider.generateBudgetPdf(context);

                  // 5. NAVEGAR A PREVIEW
                  if (context.mounted) {
                    Navigator.pop(context); // Cerrar loading
                    final clientName = _razonSocialController.text.isNotEmpty
                        ? _razonSocialController.text
                        : "cliente";
                    final fileName =
                        'presupuesto_${clientName}_${DateTime.now().millisecondsSinceEpoch}.pdf';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPreviewScreen(
                          pdfBytes: pdfBytes,
                          fileName: fileName,
                          onShare: () => Printing.sharePdf(
                              bytes: pdfBytes, filename: fileName),
                        ),
                      ),
                    ).then((_) => Navigator.pop(
                        context)); // Volver al inicio al cerrar preview
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Cerrar loading
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Error: ${e.toString().replaceAll("Exception:", "")}')));
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  // Helper para títulos de sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
    );
  }
}
