class ClientModel {
  final String id; // Nuevo campo para identificar al cliente
  final String razonSocial;
  final String ruc;
  final String? email;
  final String? telefono;
  final String? ciudad;
  final String? departamento;
  final String createdBy; // Nuevo campo para el UID del creador
  final String? clientType; // Nuevo: Campo para el tipo de cliente

  ClientModel({
    required this.id,
    required this.razonSocial,
    required this.ruc,
    this.email,
    this.telefono,
    this.ciudad,
    this.departamento,
    required this.createdBy,
    this.clientType, // Nuevo: Añadido al constructor
  });

  factory ClientModel.fromMap(Map<String, dynamic> data, String id) {
    return ClientModel(
      id: id,
      razonSocial: data['razonSocial'] ?? '',
      ruc: data['ruc'] ?? '',
      email: data['email'],
      telefono: data['telefono'],
      ciudad: data['ciudad'],
      departamento: data['departamento'],
      createdBy: data['createdBy'] ?? '',
      clientType: data['clientType'], // Nuevo: Añadido a fromMap
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'razonSocial': razonSocial,
      'ruc': ruc,
      'email': email,
      'telefono': telefono,
      'ciudad': ciudad,
      'departamento': departamento,
      'createdBy': createdBy,
      'clientType': clientType, // Nuevo: Añadido a toMap
    };
  }
}
