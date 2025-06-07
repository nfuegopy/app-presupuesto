class UserModel {
  final String uid;
  final String email;
  final String role;
  final String nombre;
  final String apellido;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.nombre,
    required this.apellido,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'nombre': nombre,
      'apellido': apellido,
    };
  }
}
