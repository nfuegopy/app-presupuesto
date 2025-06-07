import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    // Asegurarse de que Firebase esté inicializado
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase no está inicializado. Asegúrate de llamar a Firebase.initializeApp primero.');
    }
  }

  @override
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }
}