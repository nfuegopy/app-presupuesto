import '../entities/budget.dart';

//entities/budget.dart
abstract class BudgetRepository {
  Future<void> createBudget(Budget budget);
}
