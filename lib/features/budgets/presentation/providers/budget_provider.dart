import 'package:flutter/material.dart';
import '../../../products/domain/entities/product.dart';

class BudgetProvider with ChangeNotifier {
  bool isLoading = false;

  Future<void> createBudget({
    required Product product,
    required String clientName,
    required String clientEmail,
    required String clientPhone,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      // TODO: Implementar lógica de generación de PDF
      // - Crear el PDF con los datos de product, clientName, clientEmail, clientPhone
      // - Guardar el PDF localmente
      // - Opcionalmente, guardar el presupuesto en Firestore (colección 'budgets')
      await Future.delayed(const Duration(seconds: 2)); // Simulación
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
