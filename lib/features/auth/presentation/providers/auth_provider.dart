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

  Future<void> signOut() async {
    await authRepository.signOut();
    user = null;
    storedEmail = null;
    notifyListeners();
  }
}
