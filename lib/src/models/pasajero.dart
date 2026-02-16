class Pasajeros {
  List<Pasajero> pasajeros = [];

  Pasajeros.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    jsonList.forEach((element) {
      final pasajero = Pasajero.fromJsonMap(element);
      pasajeros.add(pasajero);
    });
  }
}

class Pasajero {
  String tipoDoc = "";
  String numDoc = "";
  String numeroDoc = "";
  String apellidos = "";
  String nombres = "";

  String nroViaje = "";
  int asiento = 0;
  int embarcado = 0; //0 no embarcado 1 embarcado
  String idEmbarque = "0";
  String lugarEmbarque = "";
  String fechaEmbarque = "";
  String fechaViaje = "";
  String idEmbarqueReal = "";

  String idDesembarque = "0";
  String lugarDesembarque = "";
  String fechaDesembarque = "";
  String idDesembarqueReal = "";

  String idServicio = "";
  String servicio = "";
  String idRuta = "";
  String ruta = "";

  int modificado = 1; //1 -> no modificado, 0 -> modificado reserva fija, 2 -> modificado prereserva
  String estado = "";
  String? origen = "";
  String? destino = "";
  String? unidad = "";
  String? sincronizar = "0"; //0: sincronizado //1: no sincronizado

  String? embarcadoPor = "COD";
  String? coordenadas = "0,0";

  Pasajero();

  Pasajero.constructor({
    required this.tipoDoc,
    required this.numDoc,
    required this.numeroDoc,
    required this.apellidos,
    required this.nombres,
    required this.nroViaje,
    required this.asiento,
    required this.embarcado,
    required this.idEmbarque,
    required this.lugarEmbarque,
    required this.fechaEmbarque,
    required this.fechaViaje,
    required this.idEmbarqueReal,
    required this.estado,
    required this.idDesembarque,
    required this.lugarDesembarque,
    required this.fechaDesembarque,
    required this.idDesembarqueReal,
    this.origen,
    this.destino,
    this.unidad,
    this.sincronizar,
    this.embarcadoPor,
    this.coordenadas,
  });

  Pasajero.fromJsonMapRemote(Map<String, dynamic> json) {
    nroViaje = json['nroViaje'];
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    numeroDoc = json['numeroDoc'];
    apellidos = json['apellidos'];
    nombres = json['nombres'];
    asiento = json['asiento'];
    embarcado = json['embarcado'];
    idEmbarque = json['idEmbarque'];
    lugarEmbarque = json['lugarEmbarque'];
    fechaViaje = json['fechaViaje'];
    fechaEmbarque = json['fechaEmbarque'];
    idEmbarqueReal = json['idEmbarqueReal'];
    idDesembarque = json['idDesembarque'];
    lugarDesembarque = json['lugarDesembarque'];
    fechaDesembarque = json['fechaDesembarque'];
    idDesembarqueReal = json['idDesembarqueReal'];
    idServicio = json['idServicio'];
    servicio = json['servicio'];
    idRuta = json['idRuta'];
    ruta = json['ruta'];
    origen = json['origen'];
    destino = json['destino'];
    unidad = json['unidad'];
    estado = json['estado'];
    coordenadas = json["coordenadas"] ?? '';
    embarcadoPor = json["embarcadoPor"] ?? '';
  }
  Pasajero.fromJsonMapDBLocal(Map<String, dynamic> json) {
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    numeroDoc = json['numeroDoc'];
    apellidos = json['apellidos'];
    nombres = json['nombres'];
    nroViaje = json['nroViaje'] ?? '';
    asiento = json['asiento'];
    embarcado = json['embarcado'];
    idEmbarque = json['idEmbarque'];
    lugarEmbarque = json['lugarEmbarque'];
    fechaEmbarque = json['fechaEmbarque'];
    fechaViaje = json['fechaViaje'];
    idEmbarqueReal = json['idEmbarqueReal'];
    idDesembarque = json['idDesembarque'];
    lugarDesembarque = json['lugarDesembarque'];
    fechaDesembarque = json['fechaDesembarque'];
    idDesembarqueReal = json['idDesembarqueReal'];
    idServicio = json['idServicio'];
    servicio = json['servicio'];
    idRuta = json['idRuta'];
    ruta = json['ruta'];
    origen = json['origen'];
    destino = json['destino'];
    unidad = json['unidad'];
    estado = json['estado'];
    coordenadas = json["coordenadas"] ?? '';
    embarcadoPor = json["embarcadoPor"] ?? '';
    sincronizar = json['sincronizar'];
  }

  Pasajero.fromJsonMap(Map<String, dynamic> json) {
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    numeroDoc = json['numeroDoc'];
    apellidos = json['apellidos'];
    nombres = json['nombres'];
    if (json['nroViaje'] != null) nroViaje = json['nroViaje'];
    asiento = json['asiento'];
    embarcado = json['embarcado'];
    idEmbarque = json['idEmbarque'];
    lugarEmbarque = json['lugarEmbarque'];
    fechaEmbarque = json['fechaEmbarque'];
    fechaViaje = json['fechaViaje'];
    idEmbarqueReal = json['idEmbarqueReal'];
    estado = json['estado'];
    idDesembarque = json['idDesembarque'];
    lugarDesembarque = json['lugarDesembarque'];
    fechaDesembarque = json['fechaDesembarque'];
    idDesembarqueReal = json['idDesembarqueReal'];
    idServicio = json['idServicio'];
    servicio = json['servicio'];
    idRuta = json['idRuta'];
    ruta = json['ruta'];
    coordenadas = json["coordenadas"] ?? '';
    embarcadoPor = json["embarcadoPor"] ?? '';
  }

  Map<String, dynamic> toMapDatabase() {
    return {
      'tipoDoc': tipoDoc.trim(),
      'numDoc': numDoc.trim(),
      'numeroDoc': numeroDoc.trim(),
      'apellidos': apellidos.trim(),
      'nombres': nombres.trim(),
      'nroViaje': nroViaje.trim(),
      'asiento': asiento,
      'embarcado': embarcado,
      'idEmbarque': idEmbarque.trim(),
      'lugarEmbarque': lugarEmbarque.trim(),
      'fechaEmbarque': fechaEmbarque,
      'fechaViaje': fechaViaje,
      'idEmbarqueReal': idEmbarqueReal,
      'idDesembarque': idDesembarque,
      'lugarDesembarque': lugarDesembarque,
      'fechaDesembarque': fechaDesembarque,
      'idDesembarqueReal': idDesembarqueReal,
      'idServicio': idServicio,
      'servicio': servicio,
      'idRuta': idRuta,
      'ruta': ruta,
      'origen': origen,
      'destino': destino,
      'unidad': unidad,
      'estado': estado,
      'coordenadas': coordenadas,
      'embarcadoPor': embarcadoPor,
      'sincronizar': sincronizar,
    };
  }
  
}
