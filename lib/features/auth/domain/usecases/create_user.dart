import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CreateUser {
  final AuthRepository repository;

  CreateUser(this.repository);

  Future<User?> call({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
  }) async {
    return await repository.createUser(
      email: email,
      password: password,
      nombre: nombre,
      apellido: apellido,
    );
  }
}
