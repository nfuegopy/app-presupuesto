import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/user.dart';
import './../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    // Asegurarse de que Firebase esté inicializado
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase no está inicializado. Asegúrate de llamar a Firebase.initializeApp primero.');
    }
  }

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userModel = UserModel.fromMap(doc.data()!, user.uid);
          if (userModel.role == 'seller') {
            return User(
              uid: userModel.uid,
              email: userModel.email,
              role: userModel.role,
            );
          } else {
            throw Exception('Acceso denegado: Solo los vendedores pueden iniciar sesión.');
          }
        }
        throw Exception('Usuario no encontrado en la base de datos.');
      }
      return null;
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
          return 'Contraseña incorrecta. Por favor, intenta de nuevo.';
        case 'user-not-found':
          return 'Usuario no encontrado. Verifica tu correo electrónico.';
        case 'invalid-email':
          return 'Correo electrónico inválido.';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    }
    return error.toString();
  }
}