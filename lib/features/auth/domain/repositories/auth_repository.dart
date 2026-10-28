import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  Future<String?> getStoredUserEmail();
  Future<void> storeUserEmail(String email);
  Future<void> resetPassword(String email);
  Future<Map<String, String>?> getStoredCredentials(); // <-- AÑADIDO
}
