import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../providers/budget_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/custom_dropdown.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../widgets/client_search_select.dart';
import '../../data/models/client_model.dart';
import '../utils/financing_schedule.dart';
import 'pdf_preview_screen.dart';

class BudgetFormScreen extends StatefulWidget {
  final Product product;

  const BudgetFormScreen({super.key, required this.product});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  // Los presupuestos nuevos se cotizan siempre en dólares (AMIN-07)
  static const String _currency = 'USD';

  // --- CONTROLADORES ---
  final _razonSocialController = TextEditingController();
  final _rucController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _deliveryVehicleController = TextEditingController();
  final _numberOfInstallmentsController = TextEditingController();
  final _numberOfReinforcementsController = TextEditingController();
  final _reinforcementAmountController = TextEditingController();
  final _validityOfferController =
      TextEditingController(text: 'Válido 15 días');
  final _commercialConditionsController =
      TextEditingController(text: 'Plazo de Entrega 10 días');

  // Descuento
  bool _hasDiscount = false;
  // Se elige de 1 al tope definido por el administrador (AMIN-09)
  double? _discountPercentage;

  // Opciones 1%, 2%, ... hasta el tope; si el tope tiene decimales (4,5) se
  // agrega como última opción para poder usarlo completo.
  static List<double> _discountOptions(double? max) {
    if (max == null || max <= 0) return [];
    final options = [for (var i = 1; i <= max.floor(); i++) i.toDouble()];
    if (max > max.floor()) options.add(max);
    return options;
  }

  static String _percentLabel(double value) =>
      '${_plainNumber(value).replaceAll('.', ',')}%';

  // 97800.0 -> "97800", 4.5 -> "4.5"
  static String _plainNumber(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  // Beneficios elegidos (productos tipo "beneficio" del admin, AMIN-11), por id
  final Map<String, Product> _selectedBenefits = {};

  double get _benefitsTotal =>
      _selectedBenefits.values.fold(0.0, (sum, b) => sum + b.price);

  // Precio final contado, calculado y no editable por el vendedor (AMIN-10):
  // (precio de lista del producto + beneficios incluidos) menos el descuento
  // elegido, que se aplica sobre ese total; a 2 decimales.
  double get _subtotal => widget.product.price + _benefitsTotal;

  double get _discountAmount => _subtotal - _finalPrice;

  double get _finalPrice {
    final discount = _hasDiscount ? (_discountPercentage ?? 0) : 0;
    return (_subtotal * (1 - discount / 100) * 100).roundToDouble() / 100;
  }

  // --- Plan de cuotas ---
  int? get _numberOfInstallments =>
      int.tryParse(_numberOfInstallmentsController.text.trim());

  double get _totalDelivery =>
      (double.tryParse(_deliveryController.text.trim()) ?? 0) +
      (double.tryParse(_deliveryVehicleController.text.trim()) ?? 0);

  // "12 cuotas mensuales: de Dic 2026 a Nov 2027"
  String? get _installmentsPreview {
    final n = _numberOfInstallments;
    if (n == null || n < 1 || _paymentFrequency == null) return null;
    final months =
        FinancingSchedule.dueMonths(DateTime.now(), n, _paymentFrequency!);
    final kind = '${_paymentFrequency!.toLowerCase()}${n == 1 ? '' : 'es'}';
    return '$n ${n == 1 ? 'cuota' : 'cuotas'} $kind: de '
        '${FinancingSchedule.monthLabel(months.first)} a '
        '${FinancingSchedule.monthLabel(months.last)}';
  }

  void _resetReinforcements() {
    _hasReinforcements = false;
    _reinforcementFrequency = null;
    _firstReinforcementInstallment = null;
  }

  // --- ESTADO ---
  // ignore: unused_field
  String _searchQuery = '';
  bool _isNewClient = false;
  ClientModel? _selectedClient;
  String? _paymentMethod;
  String? _paymentFrequency;
  bool? _hasReinforcements;
  String? _reinforcementFrequency;
  // Cuota en la que cae el primer refuerzo; los siguientes, cada período
  int? _firstReinforcementInstallment;
  String? _clientType;
  bool _isLoading = false;

  // Un producto con precio cargado en guaraníes no se puede cotizar en USD
  bool get _productPricedInGs => widget.product.currency.toUpperCase() != 'USD';

  @override
  void initState() {
    super.initState();
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    budgetProvider.updateProduct(widget.product);
    budgetProvider.loadClientsByVendor();
    budgetProvider.loadDiscountConfig();
    budgetProvider.loadInterestRate();
    _hasReinforcements = false;
    // El resumen del plan y las opciones de refuerzo dependen de estos campos
    for (final c in [
      _numberOfInstallmentsController,
      _deliveryController,
      _deliveryVehicleController,
      _numberOfReinforcementsController,
    ]) {
      c.addListener(_onPlanFieldChanged);
    }
  }

  void _onPlanFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _razonSocialController.dispose();
    _rucController.dispose();
    _deliveryController.dispose();
    _deliveryVehicleController.dispose();
    _numberOfInstallmentsController.dispose();
    _numberOfReinforcementsController.dispose();
    _reinforcementAmountController.dispose();
    _validityOfferController.dispose();
    _commercialConditionsController.dispose();
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
    final maxDiscount = budgetProvider.maxDiscountPercentage;
    final discountValues = _discountOptions(maxDiscount);
    final discountEnabled = discountValues.isNotEmpty;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nuevo Presupuesto',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
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

            if (_productPricedInGs) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Este producto tiene el precio cargado en guaraníes. Los presupuestos '
                  'se emiten solo en USD: pide al administrador que actualice su precio.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],

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
                      _clientType = client.clientType;

                      budgetProvider.updateClient(
                        razonSocial: client.razonSocial,
                        ruc: client.ruc,
                        clientType: client.clientType,
                        selectedClientId: client.id,
                      );
                    } else {
                      // Limpiar si se deselecciona
                      _razonSocialController.clear();
                      _rucController.clear();
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

            const SizedBox(height: 40),
            _buildSectionTitle('Precio'),
            const SizedBox(height: 8),
            Text(
              'Moneda: $_currency',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Orden: beneficios que suman -> descuento sobre el total -> resumen
            _buildBenefitsSelector(),
            const SizedBox(height: 24),

            // --- SECCIÓN DE DESCUENTO ---
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
                    onChanged: discountEnabled
                        ? (value) {
                            setState(() {
                              _hasDiscount = value == 'Sí, aplicar descuento';
                              if (!_hasDiscount) _discountPercentage = null;
                            });
                          }
                        : null,
                  ),
                  if (!discountEnabled &&
                      !budgetProvider.isLoadingDiscountConfig) ...[
                    const SizedBox(height: 8),
                    Text(
                      'El descuento no está habilitado por el administrador.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  if (_hasDiscount && discountEnabled) ...[
                    const SizedBox(height: 16),
                    CustomDropdown(
                      label:
                          'Porcentaje Descuento (máx. ${_percentLabel(maxDiscount!)})',
                      value: discountValues.contains(_discountPercentage)
                          ? _percentLabel(_discountPercentage!)
                          : null,
                      items: discountValues.map(_percentLabel).toList(),
                      onChanged: (value) => setState(() {
                        _discountPercentage = discountValues.firstWhere(
                            (option) => _percentLabel(option) == value);
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Desglose calculado y no editable (AMIN-08/10)
            _buildPriceSummary(),
            const SizedBox(height: 16),
            CustomDropdown(
              label: 'Forma de Pago',
              value: _paymentMethod,
              items: const ['Contado', 'Financiado'],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value;
                  if (_paymentMethod != 'Financiado') _resetReinforcements();
                });
              },
            ),

            if (_paymentMethod == 'Financiado') ...[
              const SizedBox(height: 32),
              _buildSectionTitle('Financiamiento'),
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
                      items: FinancingSchedule.paymentFrequencies,
                      onChanged: (value) {
                        setState(() {
                          _paymentFrequency = value;
                          _resetReinforcements();
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_installmentsPreview != null) ...[
                const SizedBox(height: 8),
                Text(_installmentsPreview!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
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
                            final include = value == 'Sí';
                            _resetReinforcements();
                            _hasReinforcements = include;
                          });
                        },
                      ),
                      if (_hasReinforcements == true) ...[
                        const SizedBox(height: 16),
                        // Solo frecuencias que caen sobre una cuota (con cuotas
                        // semestrales no se ofrece refuerzo trimestral)
                        CustomDropdown(
                          label: 'Frecuencia Refuerzo',
                          value: _reinforcementFrequency,
                          items: FinancingSchedule.reinforcementFrequenciesFor(
                              _paymentFrequency!),
                          onChanged: (value) {
                            setState(() {
                              _reinforcementFrequency = value;
                              // Por defecto, el primer refuerzo cae al cumplirse
                              // su primer período (ej. anual -> cuota 12)
                              _firstReinforcementInstallment =
                                  FinancingSchedule.reinforcementStep(
                                      _paymentFrequency!, value!);
                            });
                          },
                        ),
                        if (_reinforcementFrequency != null) ...[
                          const SizedBox(height: 16),
                          _buildFirstReinforcementSelector(),
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
            _buildSectionTitle('Condiciones'),
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

            const SizedBox(height: 32),

            // --- AVISO JUNTO AL BOTÓN: producto en Gs. no se puede generar ---
            if (_productPricedInGs)
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
                    Icon(Icons.block,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            'No se puede generar: el precio de este producto está en guaraníes.',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  ],
                ),
              ),

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
                if (_productPricedInGs) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      content: const Text(
                          'El producto tiene precio en guaraníes; debe actualizarse a USD')));
                  return;
                }
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

                // --- PRECIOS (calculados, no editables) ---
                final price = _finalPrice;
                // "Monto Real" del PDF: precio de lista más beneficios incluidos
                final realPrice = _hasDiscount ? _subtotal : null;
                final discountPercentage =
                    _hasDiscount ? _discountPercentage : null;
                if (_hasDiscount && discountPercentage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Seleccione el porcentaje de descuento')));
                  return;
                }

                // --- VALIDACIÓN DEL PLAN DE CUOTAS Y REFUERZOS ---
                if (_paymentMethod == 'Financiado') {
                  final planError = FinancingSchedule.validate(
                    price: price,
                    totalDelivery: _totalDelivery,
                    numberOfInstallments: _numberOfInstallments,
                    paymentFrequency: _paymentFrequency,
                    hasReinforcements: _hasReinforcements == true,
                    reinforcementFrequency: _reinforcementFrequency,
                    firstInstallment: _firstReinforcementInstallment,
                    numberOfReinforcements:
                        int.tryParse(_numberOfReinforcementsController.text),
                    reinforcementAmount:
                        double.tryParse(_reinforcementAmountController.text),
                  );
                  if (planError != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(planError)));
                    return;
                  }
                }

                bool confirmed = await _showConfirmationDialog();
                if (!confirmed) return;

                // Mes y año del primer refuerzo, para el registro del presupuesto
                final firstReinforcementMonth = _hasReinforcements == true &&
                        _firstReinforcementInstallment != null
                    ? FinancingSchedule.dueMonths(
                            DateTime.now(),
                            _firstReinforcementInstallment!,
                            _paymentFrequency!)
                        .last
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
                      clientType: _clientType,
                      selectedClientId: null,
                    );
                  } else if (_selectedClient != null) {
                    budgetProvider.updateClient(
                      razonSocial: _razonSocialController.text.trim(),
                      ruc: _rucController.text.trim(),
                      clientType: _selectedClient!.clientType,
                      selectedClientId: _selectedClient!.id,
                    );
                  } else {
                    // Fallback para actualización genérica
                    budgetProvider.updateClient(
                      razonSocial: _razonSocialController.text.trim(),
                      ruc: _rucController.text.trim(),
                      clientType: _clientType,
                      selectedClientId: null,
                    );
                  }

                  if (budgetProvider.error != null) {
                    throw Exception(budgetProvider.error);
                  }

                  // 2. ACTUALIZAR DATOS PAGO
                  await budgetProvider.updatePaymentDetails(
                    currency: _currency,
                    price: price,
                    paymentMethod: _paymentMethod ?? 'Contado',
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
                    firstReinforcementInstallment:
                        _hasReinforcements == true
                            ? _firstReinforcementInstallment
                            : null,
                    reinforcementMonth: firstReinforcementMonth == null
                        ? null
                        : FinancingSchedule
                            .monthNames[firstReinforcementMonth.month - 1],
                    reinforcementYear: firstReinforcementMonth?.year,
                    validityOffer: _validityOfferController.text,
                    commercialConditions: _commercialConditionsController.text,
                    // En el presupuesto van solo los nombres, sin el precio de cada uno
                    benefits: _selectedBenefits.values
                        .map((b) => b.name)
                        .join(', '),
                    hasDiscount: _hasDiscount,
                    realPrice: realPrice,
                    discountPercentage: discountPercentage,
                  );

                  if (budgetProvider.error != null) {
                    throw Exception(budgetProvider.error);
                  }

                  // 3. GUARDAR EN FIREBASE
                  await budgetProvider.createBudget();
                  if (budgetProvider.error != null) {
                    throw Exception(budgetProvider.error);
                  }

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

  // Beneficios cargados en el admin; cada uno elegido suma su precio al
  // precio final. Solo se ofrecen los que están en USD (AMIN-07).
  Widget _buildBenefitsSelector() {
    final productProvider = Provider.of<ProductProvider>(context);
    final benefits = productProvider.benefits
        .where((b) => b.currency.toUpperCase() == _currency)
        .toList();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Beneficios Incluidos',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (productProvider.isLoading)
          const LinearProgressIndicator()
        else if (benefits.isEmpty)
          Text('No hay beneficios cargados por el administrador.',
              style: textTheme.bodySmall)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: benefits.map((benefit) {
              final selected = _selectedBenefits.containsKey(benefit.id);
              return FilterChip(
                label: Text(
                    '${benefit.name} · $_currency ${_plainNumber(benefit.price)}'),
                selected: selected,
                onSelected: (value) => setState(() {
                  if (value) {
                    _selectedBenefits[benefit.id] = benefit;
                  } else {
                    _selectedBenefits.remove(benefit.id);
                  }
                }),
              );
            }).toList(),
          ),
        if (_selectedBenefits.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Suman $_currency ${_plainNumber(_benefitsTotal)} al precio final '
            '(en el PDF se listan sin precio).',
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  // Mismo formato que el PDF: 100.100 (con centavos solo si los hay)
  String _money(double value) {
    final hasCents = (value * 100).round() % 100 != 0;
    final text = NumberFormat.decimalPatternDigits(
            locale: 'es_PY', decimalDigits: hasCents ? 2 : 0)
        .format(value);
    return '$_currency $text';
  }

  // Desglose del precio: máquina + beneficios = subtotal, - descuento = final.
  // Todo calculado; el vendedor solo elige beneficios y porcentaje.
  Widget _buildPriceSummary() {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final benefitsCount = _selectedBenefits.length;

    Widget line(String label, String value,
        {bool bold = false, Color? color, double size = 14}) {
      final style = textTheme.bodyMedium?.copyWith(
        fontSize: size,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style),
          ],
        ),
      );
    }

    final showSubtotal = benefitsCount > 0 || _hasDiscount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line('Precio de la máquina', _money(widget.product.price)),
          if (benefitsCount > 0)
            line('+ Beneficios incluidos ($benefitsCount)',
                _money(_benefitsTotal)),
          if (showSubtotal) ...[
            const Divider(height: 16),
            line('Subtotal', _money(_subtotal), bold: true),
          ],
          if (_hasDiscount && _discountPercentage != null)
            line('− Descuento ${_percentLabel(_discountPercentage!)}',
                _money(_discountAmount),
                color: scheme.error),
          const Divider(height: 20),
          line('Precio Final Contado', _money(_finalPrice),
              bold: true, size: 18, color: scheme.primary),
          const SizedBox(height: 4),
          Text('Calculado automáticamente; no se puede editar.',
              style: textTheme.bodySmall),
        ],
      ),
    );
  }

  // Mes y año de inicio de los refuerzos. Solo se ofrecen años y meses en los
  // que vence una cuota, así el primer refuerzo siempre cae sobre una cuota;
  // los siguientes caen cada período de refuerzo.
  Widget _buildFirstReinforcementSelector() {
    final n = _numberOfInstallments;
    final textTheme = Theme.of(context).textTheme;
    if (n == null || n < 1) {
      return Text('Ingrese la cantidad de cuotas para elegir el mes de inicio.',
          style: textTheme.bodySmall);
    }
    final dueMonths =
        FinancingSchedule.dueMonths(DateTime.now(), n, _paymentFrequency!);
    final selected = _firstReinforcementInstallment;
    final valid = selected != null && selected >= 1 && selected <= n;
    final selectedDate = valid ? dueMonths[selected - 1] : null;

    final years = dueMonths.map((d) => d.year).toSet().toList();
    // Cuotas del año elegido: nombre del mes -> número de cuota
    final monthsInYear = <String, int>{
      for (var i = 0; i < n; i++)
        if (dueMonths[i].year == selectedDate?.year)
          FinancingSchedule.monthNames[dueMonths[i].month - 1]: i + 1,
    };
    final max = valid
        ? FinancingSchedule.maxReinforcements(
            numberOfInstallments: n,
            paymentFrequency: _paymentFrequency!,
            reinforcementFrequency: _reinforcementFrequency!,
            firstInstallment: selected,
          )
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomDropdown(
                label: 'Mes de Inicio',
                value: selectedDate == null
                    ? null
                    : FinancingSchedule.monthNames[selectedDate.month - 1],
                items: monthsInYear.keys.toList(),
                onChanged: (value) => setState(() {
                  _firstReinforcementInstallment = monthsInYear[value];
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDropdown(
                label: 'Año de Inicio',
                value: selectedDate?.year.toString(),
                items: years.map((y) => '$y').toList(),
                onChanged: (value) => setState(() {
                  final year = int.parse(value!);
                  // Se mantiene el mes si ese año tiene cuota en ese mes; si
                  // no, se toma la primera cuota del año
                  final sameMonth = dueMonths.indexWhere((d) =>
                      d.year == year && d.month == selectedDate?.month);
                  final firstOfYear =
                      dueMonths.indexWhere((d) => d.year == year);
                  _firstReinforcementInstallment =
                      (sameMonth >= 0 ? sameMonth : firstOfYear) + 1;
                }),
              ),
            ),
          ],
        ),
        if (valid) ...[
          const SizedBox(height: 8),
          Text(
            'Primer refuerzo en la cuota $selected. Desde ahí entran hasta '
            '$max refuerzos ${_reinforcementFrequency!.toLowerCase()}es.',
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}
