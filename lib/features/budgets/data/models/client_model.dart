class ClientModel {
  final String razonSocial;
  final String ruc;
  final String? email;
  final String? telefono;
  final String? ciudad;
  final String? departamento;

  ClientModel({
    required this.razonSocial,
    required this.ruc,
    this.email,
    this.telefono,
    this.ciudad,
    this.departamento,
  });

  factory ClientModel.fromMap(Map<String, dynamic> data) {
    return ClientModel(
      razonSocial: data['razonSocial'] ?? '',
      ruc: data['ruc'] ?? '',
      email: data['email'],
      telefono: data['telefono'],
      ciudad: data['ciudad'],
      departamento: data['departamento'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'razonSocial': razonSocial,
      'ruc': ruc,
      'email': email,
      'telefono': telefono,
      'ciudad': ciudad,
      'departamento': departamento,
    };
  }
}
