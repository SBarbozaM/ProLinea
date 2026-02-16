class Rutas {
  List<Ruta> rutas = [];

  Rutas.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var element in jsonList) {
      final tipoDoc = Ruta.fromJsonMap(element);
      rutas.add(tipoDoc);
    }
  }
}

class Ruta {
  String ruta = "";
  String idOrigen = "";
  String idDestino = "";
  String origen = "";
  String destino = "";
  String codRuta = "";
  String? estado = "";

  Ruta(
      {required this.ruta,
      required this.idOrigen,
      required this.idDestino,
      required this.origen,
      required this.destino,
      required this.codRuta});

  Ruta.fromJsonMap(Map<String, dynamic> json) {
    ruta = json['ruta'];
    idOrigen = json['idOrigen'];
    idDestino = json['idDestino'];
    origen = json['origen'];
    destino = json['destino'];
    codRuta = json['codRuta'];
  }
}
