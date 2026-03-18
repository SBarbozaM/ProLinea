class TipoDocumento {
  final int id;
  final String descripcion;
  final String codigo;

  TipoDocumento({required this.id, required this.descripcion, required this.codigo});

  factory TipoDocumento.fromJson(Map<String, dynamic> json) {
    return TipoDocumento(
      id: json['id'],
      descripcion: json['descripcion'],
      codigo: json['codigo'],
    );
  }
}