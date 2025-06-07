import '../entities/budget.dart';

import '../repositories/budget_repository.dart';
class CreateBudget {
  final BudgetRepository repository;

  CreateBudget(this.repository);

  Future<void> call(Budget budget) async {
    await repository.createBudget(budget);
  }
}
