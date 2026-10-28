import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';

class ProductProvider with ChangeNotifier {
  // Los beneficios (AMIN-11) se cargan en el admin como productos con tipo
  // "beneficio": no forman parte del catálogo, se eligen en el presupuesto.
  static const String benefitType = 'beneficio';
  static bool isBenefit(Product p) => _key(p.type) == benefitType;

  List<Product> _products = [];
  List<Product> _benefits = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedType;

  List<Product> get products => _filteredProducts;
  List<Product> get benefits => _benefits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedBrand => _selectedBrand;
  String? get selectedModel => _selectedModel;
  String? get selectedType => _selectedType;

  // Filtros en cascada Marca -> Tipo -> Modelo. No hay tablas relacionadas:
  // cada producto ya trae su marca, tipo y modelo, así que las opciones de cada
  // desplegable salen de los productos que cumplen las selecciones anteriores.
  List<String> get brands => _options(_products, (p) => p.brand);
  List<String> get types => _options(
      _products.where((p) => _matches(p.brand, _selectedBrand)), (p) => p.type);
  List<String> get models => _options(
      _products.where((p) =>
          _matches(p.brand, _selectedBrand) && _matches(p.type, _selectedType)),
      (p) => p.model);

  // Compara sin distinguir mayúsculas ni espacios sobrantes ("E100/4 " == "e100/4")
  static String _key(String? value) => (value ?? '').trim().toLowerCase();

  static bool _matches(String? value, String? selected) =>
      selected == null || _key(value) == _key(selected);

  // Valores únicos (por clave normalizada), mostrando el texto ya recortado
  static List<String> _options(
      Iterable<Product> products, String? Function(Product) field) {
    final byKey = <String, String>{};
    for (final product in products) {
      final value = field(product)?.trim() ?? '';
      if (value.isNotEmpty) byKey.putIfAbsent(_key(value), () => value);
    }
    return byKey.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  final GetProducts getProductsUseCase;

  ProductProvider(this.getProductsUseCase) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Cargando productos desde Firestore...');
      final all = await getProductsUseCase();
      _products = all.where((p) => !isBenefit(p)).toList();
      _benefits = all.where(isBenefit).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      print(
          'Productos cargados: ${_products.length} (+${_benefits.length} beneficios)');
      if (_products.isEmpty) {
        print('No se encontraron productos en Firestore.');
      }
      _filteredProducts = _products;
    } catch (e) {
      print('Error al cargar productos: $e');
      _errorMessage = 'Error al cargar productos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setBrand(String? brand) {
    _selectedBrand = brand;
    _clearInvalidSelections();
    _filterProducts();
    notifyListeners();
  }

  void setType(String? type) {
    _selectedType = type;
    _clearInvalidSelections();
    _filterProducts();
    notifyListeners();
  }

  void setModel(String? model) {
    _selectedModel = model;
    _filterProducts();
    notifyListeners();
  }

  // Al cambiar marca o tipo, se limpian las selecciones que ya no corresponden.
  // Las que siguen valiendo se alinean al texto exacto de la opción, porque el
  // DropdownButton exige que el valor coincida con uno de sus items.
  void _clearInvalidSelections() {
    _selectedType = _optionFor(types, _selectedType);
    _selectedModel = _optionFor(models, _selectedModel);
  }

  static String? _optionFor(List<String> options, String? selected) {
    if (selected == null) return null;
    for (final option in options) {
      if (_key(option) == _key(selected)) return option;
    }
    return null;
  }

  void _filterProducts() {
    _filteredProducts = _products.where((product) {
      return _matches(product.brand, _selectedBrand) &&
          _matches(product.type, _selectedType) &&
          _matches(product.model, _selectedModel);
    }).toList();
  }

  void resetFilters() {
    _selectedBrand = null;
    _selectedModel = null;
    _selectedType = null;
    _filteredProducts = _products;
    notifyListeners();
  }
}
