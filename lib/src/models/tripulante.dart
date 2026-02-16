class Tripulante {
  String tipoDoc = "";
  String numDoc = "";
  String nombres = "";
  String nroViaje = "";
  String tipo = "";
  String orden = "";

  Tripulante({required this.tipoDoc, required this.numDoc, required this.nombres, required this.nroViaje, required this.tipo, required this.orden});

  Tripulante.fromJsonMap(Map<String, dynamic> json) {
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    nombres = json['nombres'];
    tipo = json['tipo'];
    orden = json['orden'];
  }

  Map<String, dynamic> toMapDatabase() {
    return {
      'tipoDoc': tipoDoc.trim(),
      'numDoc': numDoc.trim(),
      'nombres': nombres.trim(),
      'nroViaje': nroViaje.trim(),
      'tipo': tipo.trim(),
      'orden': orden.trim(),
    };
  }
}
