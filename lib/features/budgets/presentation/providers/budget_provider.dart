import 'package:flutter/material.dart';
import '../../domain/entities/client.dart';
import '../../../products/domain/entities/product.dart';

class BudgetProvider with ChangeNotifier {
  Client? _client;
  Product? _product;
  String? _error;

  Client? get client => _client;
  Product? get product => _product;
  String? get error => _error;

  void updateClient({
    required String razonSocial,
    required String ruc,
    String? email,
    String? telefono,
    String? ciudad,
    String? departamento,
  }) {
    if (razonSocial.isEmpty || ruc.isEmpty) {
      _error = 'Razón Social y RUC son obligatorios.';
      notifyListeners();
      return;
    }

    _client = Client(
      razonSocial: razonSocial,
      ruc: ruc,
      email: email?.isEmpty ?? true ? null : email,
      telefono: telefono?.isEmpty ?? true ? null : telefono,
      ciudad: ciudad?.isEmpty ?? true ? null : ciudad,
      departamento: departamento?.isEmpty ?? true ? null : departamento,
    );
    _error = null;
    notifyListeners();
  }

  void updateProduct(Product product) {
    _product = product;
    notifyListeners();
  }

  void clear() {
    _client = null;
    _product = null;
    _error = null;
    notifyListeners();
  }
}
