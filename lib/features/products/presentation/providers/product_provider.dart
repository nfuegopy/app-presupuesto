import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final GetProducts getProductsUseCase;

  ProductProvider(this.getProductsUseCase) {
    loadProducts(); // Cargar productos al inicializar
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
    } catch (e) {
      print('Error al cargar productos: $e');
      _errorMessage = 'Error al cargar productos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}