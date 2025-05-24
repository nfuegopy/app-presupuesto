import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final FirebaseFirestore _firestore;

  BudgetRepositoryImpl(this._firestore);

  @override
  Future<void> createBudget(Budget budget) async {
    final budgetModel = BudgetModel(
      id: budget.id,
      clientId: budget.clientId,
      product: ProductModel(
        id: budget.product.id,
        name: budget.product.name,
        type: budget.product.type,
        price: budget.product.price,
        currency: budget.product.currency,
        features: budget.product.features,
        imageUrl: budget.product.imageUrl,
        imageDescriptionUrl: budget.product.imageDescriptionUrl,
        createdAt: budget.product.createdAt,
        brand: budget.product.brand,
        model: budget.product.model,
        fuelType: budget.product.fuelType,
      ),
      currency: budget.currency,
      price: budget.price,
      paymentMethod: budget.paymentMethod,
      financingType: budget.financingType,
      delivery: budget.delivery,
      paymentFrequency: budget.paymentFrequency,
      numberOfInstallments: budget.numberOfInstallments,
      hasReinforcements: budget.hasReinforcements,
      reinforcementFrequency: budget.reinforcementFrequency,
      numberOfReinforcements: budget.numberOfReinforcements,
      reinforcementAmount: budget.reinforcementAmount,
      validityOffer: budget.validityOffer,
      benefits: budget.benefits,
      createdBy: budget.createdBy,
      createdAt: budget.createdAt,
    );

    await _firestore
        .collection('budgets')
        .doc(budget.id)
        .set(budgetModel.toMap());
  }
}
