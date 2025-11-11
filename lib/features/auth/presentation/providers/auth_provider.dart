import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/create_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final SignIn signInUseCase;
  final CreateUser createUserUseCase;
  final AuthRepository authRepository;
  bool isLoading = false;
  String? errorMessage;
  User? user;
  String? storedEmail;

  AuthProvider({
    required this.signInUseCase,
    required this.createUserUseCase,
    required this.authRepository,
  }) {
    _loadStoredEmail();
  }

  Future<void> _loadStoredEmail() async {
    storedEmail = await authRepository.getStoredUserEmail();
    notifyListeners();
  }

  // --- INICIO CAMBIO: Nuevo método ---
  Future<void> signInWithBiometrics() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // 1. Obtener credenciales seguras
      final credentials = await authRepository.getStoredCredentials();

      if (credentials != null) {
        // 2. Usar credenciales para iniciar sesión normal
        user = await signInUseCase(
          credentials['email']!,
          credentials['password']!,
        );
      } else {
        errorMessage =
            'No hay credenciales guardadas. Inicie sesión con su contraseña al menos una vez.';
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Método de ayuda para establecer errores desde la UI (si es necesario)
  void setErrorMessage(String message) {
    errorMessage = message;
    notifyListeners();
  }
  // --- FIN CAMBIO ---

  Future<void> signIn(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      user = await signInUseCase(email, password);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      user = await createUserUseCase(
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
      );
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await authRepository.resetPassword(email);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    user = null;
    storedEmail = null;
    notifyListeners();
  }
}
