class ActualVersion {
  final String nombre;
  final String version;

  ActualVersion({required this.nombre, required this.version});

  // Método para mapear el JSON a la clase
  factory ActualVersion.fromJson(Map<String, dynamic> json) {
    return ActualVersion(
      nombre: json['nombre'],
      version: json['version'],
    );
  }
}
