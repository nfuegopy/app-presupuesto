import '../../domain/entities/user.dart';

abstract class AuthRepository {
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  Future<User?> createUser({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  });
  Future<String?> getStoredUserEmail();
  Future<void> storeUserEmail(String email);
  Future<void> resetPassword(String email);
}