class GeocercaOrdenada {
  double orden;
  String idGeocerca;
  String nombre;
  int vMaximaBuses;
  int tipo;
  String rutaCod;
  bool seRecorrioGeo;
  bool alertAcercamiento;

  GeocercaOrdenada({
    required this.orden,
    required this.idGeocerca,
    required this.nombre,
    required this.vMaximaBuses,
    required this.tipo,
    required this.rutaCod,
    this.seRecorrioGeo = false,
    this.alertAcercamiento = false,
  });

  factory GeocercaOrdenada.fromMap(Map<String, dynamic> map) {
    return GeocercaOrdenada(
      orden: map['orden'] != null ? (map['orden'] as num).toDouble() : 0.0,
      idGeocerca: map['idGeocerca'] ?? '',
      nombre: map['nombre'] ?? '',
      vMaximaBuses: map['vMaximaBuses'] ?? 0,
      tipo: map['tipo'] ?? 0,
      rutaCod: map['rutaCod'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'orden': orden,
      'idGeocerca': idGeocerca,
      'nombre': nombre,
      'vMaximaBuses': vMaximaBuses,
      'tipo': tipo,
      'rutaCod': rutaCod,
    };
  }
}
