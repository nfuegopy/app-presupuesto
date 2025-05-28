class ParaguayLocation {
  final String departamento;
  final List<String> ciudades;

  ParaguayLocation({required this.departamento, required this.ciudades});

  factory ParaguayLocation.fromJson(Map<String, dynamic> json) {
    return ParaguayLocation(
      departamento: json['departamento'],
      ciudades: List<String>.from(json['ciudades']),
    );
  }
}