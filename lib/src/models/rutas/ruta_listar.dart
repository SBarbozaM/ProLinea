class RutaListarResponse {
  String rpta;
  String mensaje;
  List<RutaListar> rutas;
  int codigoEstado;

  RutaListarResponse({
    required this.rpta,
    required this.mensaje,
    required this.rutas,
    required this.codigoEstado,
  });

  factory RutaListarResponse.fromJson(Map<String, dynamic> json) {
    return RutaListarResponse(
      rpta: json['rpta']?.toString() ?? '1',
      mensaje: json['mensaje']?.toString() ?? '',
      rutas: (json['rutas'] as List<dynamic>?)?.map((e) => RutaListar.fromJson(e)).toList() ?? [],
      codigoEstado: json['codigoEstado'] ?? 500,
    );
  }
}

class RutaListar {
  String codigo;
  String origen;
  String destino;
  String inicio;
  String fin;
  String camino;
  String mapa;
  String tipo;

  RutaListar({
    required this.codigo,
    required this.origen,
    required this.destino,
    required this.inicio,
    required this.fin,
    required this.camino,
    required this.mapa,
    required this.tipo,
  });

  factory RutaListar.fromJson(Map<String, dynamic> json) {
    return RutaListar(
      codigo: json['codigo']?.toString() ?? '',
      origen: json['origen']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      inicio: json['inicio']?.toString() ?? '',
      fin: json['fin']?.toString() ?? '',
      camino: json['camino']?.toString() ?? '',
      mapa: json['mapa']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
    );
  }
}
