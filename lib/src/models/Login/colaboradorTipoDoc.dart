class ColaboradorTipoDocv2 {
  final String codigo;
  final String nombre;
  final String selected;
  final String codigoPadre;

  ColaboradorTipoDocv2({
    required this.codigo,
    required this.nombre,
    required this.selected,
    required this.codigoPadre,
  });

  factory ColaboradorTipoDocv2.fromJson(Map<String, dynamic> json) {
    return ColaboradorTipoDocv2(
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      selected: json['selected'] ?? '',
      codigoPadre: json['codigoPadre'] ?? '',
    );
  }
}