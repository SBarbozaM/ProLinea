class DataGeocerca {
  String idGeocerca;
  String nombre;
  int vMaximaBuses;
  int tipo;
  String fechaRegistro;
  List<Coordenada> coordenadas;

  DataGeocerca({
    required this.idGeocerca,
    required this.nombre,
    required this.vMaximaBuses,
    required this.tipo,
    required this.fechaRegistro,
    required this.coordenadas,
  });

  factory DataGeocerca.fromJson(Map<String, dynamic> json) => DataGeocerca(
        idGeocerca: json["idGeocerca"],
        nombre: json["nombre"],
        vMaximaBuses: json["vMaximaBuses"],
        tipo: json["tipo"],
        fechaRegistro: json["fechaRegistro"],
        coordenadas: List<Coordenada>.from(json["coordenadas"].map((x) => Coordenada.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "idGeocerca": idGeocerca,
        "nombre": nombre,
        "vMaximaBuses": vMaximaBuses,
        "tipo": tipo,
        "fechaRegistro": fechaRegistro,
        "coordenadas": List<dynamic>.from(coordenadas.map((x) => x.toJson())),
      };
}

class Coordenada {
  double latitude;
  double longitude;
  int orden;

  Coordenada({
    required this.latitude,
    required this.longitude,
    required this.orden,
  });

  factory Coordenada.fromJson(Map<String, dynamic> json) => Coordenada(
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        orden: json["orden"],
      );

  Map<String, dynamic> toJson() => {
        "latitude": latitude,
        "longitude": longitude,
        "orden": orden,
      };
}
