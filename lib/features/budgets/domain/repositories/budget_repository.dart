import '../entities/budget.dart';
import '../../data/models/client_model.dart'; // Assuming ClientModel is here or adjust path

abstract class BudgetRepository {
  Future<void> createBudget(Budget budget);
  Future<List<ClientModel>> searchClients(String query);
  Future<List<ClientModel>> getClientsByVendor();
  Future<ClientModel?> getClientByRUC(String ruc); // Added method signature
}
