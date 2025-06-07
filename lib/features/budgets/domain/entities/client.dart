class Client {
  final String razonSocial;
  final String ruc;
  final String? email;
  final String? telefono;
  final String? ciudad;
  final String? departamento;

  Client({
    required this.razonSocial,
    required this.ruc,
    this.email,
    this.telefono,
    this.ciudad,
    this.departamento,
  });
}
