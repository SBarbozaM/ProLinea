class Paradas {
  List<Parada> paradas = [];

  Paradas.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var element in jsonList) {
      final parada = Parada.fromJsonMap(element);
      paradas.add(parada);
    }
  }
}

class Parada {
  String id = "";
  String nroViaje = "";
  String direccion = "";
  String distrito = "";
  String coordenadas = "";
  String horaRecojo = "";
  String orden = "";
  String recojoTaxi = "";
  String estado =
      "0"; //0 en espera, 1 registrar hora llegada, 2 registrar pasajeros, 3 todos pasajeros registrados

  Parada();

  Parada.fromJsonMap(Map<String, dynamic> json) {
    nroViaje = json['nroViaje'] ?? "";
    direccion = json['direccion'];
    distrito = json['distrito'];
    horaRecojo = json['horaRecojo'];
    coordenadas = json['coordenadas'];
    recojoTaxi = json['recojoTaxi'] ?? '0';
    orden = json['orden'];
  }

  Parada.fromJsonMapBDLocal(Map<String, dynamic> json) {
    nroViaje = json['nroViaje'];
    direccion = json['direccion'];
    distrito = json['distrito'];
    coordenadas = json['coordenadas'];
    horaRecojo = json['horaRecojo'];
    orden = json['orden'];
    recojoTaxi = json['recojoTaxi'] == null ? '0' : json['recojoTaxi'];
    estado = json["estado"];
  }

  Map<String, dynamic> toJson() => {
        "nroViaje": nroViaje,
        "direccion": direccion,
        "distrito": distrito,
        "coordenadas": coordenadas,
        "horaRecojo": horaRecojo,
        "orden": orden,
        "recojoTaxi": recojoTaxi,
        "estado": estado
      };
}
