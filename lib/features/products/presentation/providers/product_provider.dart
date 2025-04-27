import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedType;

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedBrand => _selectedBrand;
  String? get selectedModel => _selectedModel;
  String? get selectedType => _selectedType;

  List<String> get brands =>
      _products.map((product) => product.brand ?? 'Sin marca').toSet().toList()
        ..sort();
  List<String> get models =>
      _products.map((product) => product.model ?? 'Sin modelo').toSet().toList()
        ..sort();
  List<String> get types =>
      _products.map((product) => product.type).toSet().toList()..sort();

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
      _products = await getProductsUseCase();
      print('Productos cargados: ${_products.length}');
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
    _selectedBrand = brand == 'Sin marca' ? null : brand;
    _filterProducts();
    notifyListeners();
  }

  void setModel(String? model) {
    _selectedModel = model == 'Sin modelo' ? null : model;
    _filterProducts();
    notifyListeners();
  }

  void setType(String? type) {
    _selectedType = type;
    _filterProducts();
    notifyListeners();
  }

  void _filterProducts() {
    _filteredProducts = _products.where((product) {
      final matchesBrand =
          _selectedBrand == null || product.brand == _selectedBrand;
      final matchesModel =
          _selectedModel == null || product.model == _selectedModel;
      final matchesType =
          _selectedType == null || product.type == _selectedType;
      return matchesBrand && matchesModel && matchesType;
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
