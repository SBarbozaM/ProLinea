class Geocerca {
  String idGeocerca;
  String nombre;
  int vMaximaBuses;
  int vMaximaCagueros;
  int tipo;
  String fechaRegistro;

  Geocerca({
    required this.idGeocerca,
    required this.nombre,
    required this.vMaximaBuses,
    required this.vMaximaCagueros,
    required this.tipo,
    required this.fechaRegistro,
  });

  factory Geocerca.fromJson(Map<String, dynamic> json) {
    return Geocerca(
      idGeocerca: json['idGeocerca'] ?? '',
      nombre: json['nombre'] ?? '',
      vMaximaBuses: json['vMaximaBuses'] ?? 0,
      vMaximaCagueros: json['vMaximaCagueros'] ?? 0,
      tipo: json['tipo'] ?? 0,
      fechaRegistro: json['fechaRegistro'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idGeocerca': idGeocerca,
      'nombre': nombre,
      'vMaximaBuses': vMaximaBuses,
      'vMaximaCagueros': vMaximaCagueros,
      'tipo': tipo,
      'fechaRegistro': fechaRegistro,
    };
  }
}

class GeocercaDetalle {
  int id;
  String idGeocerca;
  double latitud;
  double longitud;
  int radio;
  String fechaRegistro;

  GeocercaDetalle({
    required this.id,
    required this.idGeocerca,
    required this.latitud,
    required this.longitud,
    required this.radio,
    required this.fechaRegistro,
  });

  factory GeocercaDetalle.fromJson(Map<String, dynamic> json) {
    return GeocercaDetalle(
      id: json['id'] ?? 0,
      idGeocerca: json['idGeocerca'] ?? '',
      latitud: json['latitud'] ?? 0.0,
      longitud: json['longitud'] ?? 0.0,
      radio: json['radio'] ?? 0,
      fechaRegistro: json['fechaRegistro'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idGeocerca': idGeocerca,
      'latitud': latitud,
      'longitud': longitud,
      'radio': radio,
      'fechaRegistro': fechaRegistro,
    };
  }
}
