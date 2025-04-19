import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/sign_in.dart';

class AuthProvider with ChangeNotifier {
  final SignIn signInUseCase;
  bool isLoading = false;
  String? errorMessage;
  User? user;

  AuthProvider(this.signInUseCase);

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
}
