class DocsAccion {
  final int id;
  final String nombre;
  final int orden;
  final int pendientes;
  final String icono;

  const DocsAccion({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.pendientes,
    required this.icono,
  });
  factory DocsAccion.fromJson(Map<String, dynamic> json) {
    return DocsAccion(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      orden: json['orden'] is int ? json['orden'] : int.tryParse(json['orden']?.toString() ?? '') ?? 0,
      pendientes: json['pendientes'] is int ? json['pendientes'] : int.tryParse(json['pendientes']?.toString() ?? '') ?? 0,
      icono: json['icono']?.toString() ?? '',
    );
  }

  /// 🔹 TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'orden': orden,
      'pendientes': pendientes,
      'icono': icono,
    };
  }
}
