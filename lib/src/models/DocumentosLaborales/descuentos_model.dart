class DescuentoPersona {
  final String nombre;
  final double abono;
  final double saldoDesc;

  DescuentoPersona({
    required this.nombre,
    required this.abono,
    required this.saldoDesc,
  });

  factory DescuentoPersona.fromJson(Map<String, dynamic> json) {
    return DescuentoPersona(
      nombre: json['nombre'] ?? '',
      abono: (json['abono'] ?? 0).toDouble(),
      saldoDesc: (json['saldoDesc'] ?? 0).toDouble(),
    );
  }
}
