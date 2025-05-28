import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/client_model.dart'; // Ensure ClientModel is imported
import '../../../products/data/models/product_model.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import 'package.firebase_auth/firebase_auth.dart'; // For current user

class BudgetRepositoryImpl implements BudgetRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth; // To get current user for vendorId

  BudgetRepositoryImpl(this._firestore, this._firebaseAuth); // Updated constructor

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

  @override
  Future<List<ClientModel>> searchClients(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final vendorId = currentUser.uid;

    // Query by razonSocial
    final razonSocialQuery = _firestore
        .collection('clients')
        .where('vendorId', isEqualTo: vendorId) // Filter by vendorId
        .where('razonSocial', isGreaterThanOrEqualTo: query)
        .where('razonSocial', isLessThanOrEqualTo: '$query\uf8ff');

    // Query by RUC
    final rucQuery = _firestore
        .collection('clients')
        .where('vendorId', isEqualTo: vendorId) // Filter by vendorId
        .where('ruc', isGreaterThanOrEqualTo: query)
        .where('ruc', isLessThanOrEqualTo: '$query\uf8ff');

    try {
      final razonSocialSnapshot = await razonSocialQuery.get();
      final rucSnapshot = await rucQuery.get();

      final clientsMap = <String, ClientModel>{};

      for (var doc in razonSocialSnapshot.docs) {
        final client = ClientModel.fromFirestore(doc.data(), doc.id);
        clientsMap[client.id] = client;
      }

      for (var doc in rucSnapshot.docs) {
        final client = ClientModel.fromFirestore(doc.data(), doc.id);
        clientsMap[client.id] = client; // Overwrites if already present, effectively merging
      }
      
      return clientsMap.values.toList();
    } catch (e) {
      // Log error or handle as needed
      print('Error searching clients: $e');
      return []; // Return empty list on error
    }
  }

  @override
  Future<List<ClientModel>> getClientsByVendor() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final vendorId = currentUser.uid;

    try {
      final snapshot = await _firestore
          .collection('clients')
          .where('vendorId', isEqualTo: vendorId)
          .get();
      
      return snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting clients by vendor: $e');
      return [];
    }
  }

  @override
  Future<ClientModel?> getClientByRUC(String ruc) async {
    if (ruc.isEmpty) {
      return null;
    }
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    final vendorId = currentUser.uid;

    try {
      final querySnapshot = await _firestore
          .collection('clients')
          .where('vendorId', isEqualTo: vendorId)
          .where('ruc', isEqualTo: ruc)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ClientModel.fromFirestore(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting client by RUC: $e');
      return null; // Return null on error
    }
  }
}
