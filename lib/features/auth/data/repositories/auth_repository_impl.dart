import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // <-- AÑADIDO
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Future<SharedPreferences>? _prefs;

  // --- INICIO CAMBIO ---
  final _storage = const FlutterSecureStorage();
  // --- FIN CAMBIO ---

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Future<SharedPreferences>? prefs,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    if (Firebase.apps.isEmpty) {
      throw Exception(
          'Firebase no está inicializado. Asegúrate de llamar a Firebase.initializeApp primero.');
    }
    _prefs = prefs ?? SharedPreferences.getInstance();
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
            await storeUserEmail(email);
            // --- INICIO CAMBIO: Guardar credenciales seguras ---
            await _storage.write(key: 'user_email', value: email);
            await _storage.write(key: 'user_password', value: password);
            // --- FIN CAMBIO ---
            return User(
              uid: userModel.uid,
              email: userModel.email,
              role: userModel.role,
              nombre: userModel.nombre,
              apellido: userModel.apellido,
            );
          } else {
            throw Exception(
                'Acceso denegado: Solo los vendedores pueden iniciar sesión.');
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
    final prefs = await _prefs;
    await prefs?.remove('user_email');
    // --- INICIO CAMBIO: Borrar credenciales seguras ---
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_password');
    // --- FIN CAMBIO ---
  }

  @override
  Future<User?> createUser({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          role: 'seller',
          nombre: nombre,
          apellido: apellido,
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        await storeUserEmail(email);
        return User(
          uid: userModel.uid,
          email: userModel.email,
          role: userModel.role,
          nombre: userModel.nombre,
          apellido: userModel.apellido,
        );
      }
      return null;
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  @override
  Future<String?> getStoredUserEmail() async {
    final prefs = await _prefs;
    return prefs?.getString('user_email');
  }

  @override
  Future<void> storeUserEmail(String email) async {
    final prefs = await _prefs;
    await prefs?.setString('user_email', email);
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // --- INICIO CAMBIO: Nuevo método ---
  @override
  Future<Map<String, String>?> getStoredCredentials() async {
    final email = await _storage.read(key: 'user_email');
    final password = await _storage.read(key: 'user_password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
  // --- FIN CAMBIO ---

  String _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
          return 'Contraseña incorrecta. Por favor, intenta de nuevo.';
        case 'user-not-found':
          return 'Usuario no encontrado. Verifica tu correo electrónico.';
        case 'invalid-email':
          return 'Correo electrónico inválido.';
        case 'email-already-in-use':
          return 'El correo electrónico ya está registrado.';
        case 'weak-password':
          return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    }
    return error.toString();
  }
}
