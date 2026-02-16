class PasajerosHabilitados {
  List<PasajeroHabilitado> pasajeros = [];

  PasajerosHabilitados.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    jsonList.forEach((element) {
      final pasajero = PasajeroHabilitado.fromJsonMap(element);
      pasajeros.add(pasajero);
    });
  }
}

class PasajeroHabilitado {
  String tipoDoc = "";
  String numDoc = "";
  String apellidos = "";
  String nombres = "";
  String fechaViaje = "";
  String nroViaje = "";
  String origen = "";
  String destino = "";
  String unidad = "";

  PasajeroHabilitado(
      {required this.tipoDoc,
      required this.numDoc,
      required this.apellidos,
      required this.nombres,
      required this.nroViaje,
      required this.fechaViaje,
      required this.origen,
      required this.destino,
      required this.unidad});

  PasajeroHabilitado.fromJsonMap(Map<String, dynamic> json) {
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    apellidos = json['apellidos'];
    nombres = json['nombres'];
    nroViaje = json['nroViaje'];
    fechaViaje = json['fechaViaje'];
    origen = json['origen'];
    destino = json['destino'];
    unidad = json['unidad'];
  }

  Map<String, dynamic> toMapDatabase() {
    return {
      'tipoDoc': tipoDoc.trim(),
      'numDoc': numDoc.trim(),
      'apellidos': apellidos.trim(),
      'nombres': nombres.trim(),
      'nroViaje': nroViaje.trim(),
      'fechaViaje': fechaViaje,
      'origen': origen,
      'destino': destino,
      'unidad': unidad
    };
  }
}
