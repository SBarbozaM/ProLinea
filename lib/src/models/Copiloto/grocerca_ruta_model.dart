class GeocercaRuta {
  final int orden;
  final String idGeocerca;
  final String rutaCod;

  GeocercaRuta({required this.orden, required this.idGeocerca, required this.rutaCod});

  // Convertir de JSON a GeocercaRuta
  factory GeocercaRuta.fromJson(Map<String, dynamic> json) {
    return GeocercaRuta(
      orden: json['orden'],
      idGeocerca: json['idGeocerca'],
      rutaCod: json['rutaCod'],
    );
  }

  // Convertir de GeocercaRuta a Map para almacenar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'orden': orden,
      'idGeocerca': idGeocerca,
      'rutaCod': rutaCod,
    };
  }

  // Convertir de Map a GeocercaRuta (desde la base de datos)
  factory GeocercaRuta.fromMap(Map<String, dynamic> map) {
    return GeocercaRuta(
      orden: map['orden'],
      idGeocerca: map['idGeocerca'],
      rutaCod: map['rutaCod'],
    );
  }
}
