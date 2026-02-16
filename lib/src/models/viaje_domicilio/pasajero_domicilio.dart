class PasajerosDomicilio {
  List<PasajeroDomicilio> pasajeros = [];

  PasajerosDomicilio.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    jsonList.forEach((element) {
      final pasajero = PasajeroDomicilio.fromJsonMap(element);
      pasajeros.add(pasajero);
    });
  }
}

class PasajeroDomicilio {
  String nroViaje = "";
  String tipoDoc = "";
  String numDoc = "";
  String apellidos = "";
  String nombres = "";
  //String codigo = "";
  String coordenadas = "";
  int embarcado = 2;
  int embarcadoAux = 2;
  String direccion = "";
  String horaRecojo = "";
  String distrito = "";
  String fechaEmbarque = "";
  String fechaDesembarque = "0";
  String idEmbarqueReal = "0";
  String idDesembarqueReal = "0";
  String coordenadasParadero = "0, 0";
  String fechaViaje = "";
  String estado = "";
  int modificado = 1; //1 -> no modificado, 0 -> modificado
  int modificadoFechaArribo = 1; //1 -> no modificado, 0 -> modificado
  String fechaArriboUnidad = "";
  List<bool> selectedStatus = <bool>[false, true, false];
  // List<bool> selectedStatus = <bool>[false, false];
  bool desEmb = false;
  bool mostrarMarker = false;
  bool markerMostrado = false;
  bool tocaRecojo = false;

  //// INTEGRACION
  String nuevo = "0"; //0: no es nuevo 1: nuevo pasajero
  String asiento = "0"; //0: Reserva creada en GEOP, 1: Reserva Creada en AppBus
  int modificadoAccion = 1; //1 -> no modificado, 0 -> modificado (Para Reparto)
  String estadoDesem = ""; //1 Esta desembarcad  ;   "" Aun no desembarcado
  int pasjPorSinc = 0; //1 por sincronizar   ;   0

  PasajeroDomicilio();

  PasajeroDomicilio.fromJsonMap(Map<String, dynamic> json) {
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    apellidos = json['apellidos'];
    nombres = json['nombres'];
    //codigo = json['codigo'];
    coordenadas = json['coordenadas'];
    embarcado = json['embarcado'];
    direccion = json['direccion'];
    horaRecojo = json['horaRecojo'];
    distrito = json['distrito'];
    nroViaje = json['nroViaje'];
    fechaEmbarque = json['fechaEmbarque'];
    fechaDesembarque = json['fechaDesembarque'];
    fechaViaje = json['fechaViaje'];
    fechaArriboUnidad = json['fechaArriboUnidad'];
    idEmbarqueReal = json['idEmbarqueReal'];
    idDesembarqueReal = json['idDesembarqueReal'];
    asiento = json['asiento'].toString();
  }

  PasajeroDomicilio.fromJsonMapBDLocal(Map<String, dynamic> json) {
    nroViaje = json['nroViaje'];
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    apellidos = json['apellidos'];
    nombres = json['nombres'];
    //codigo = json['codigo'];
    embarcado = json['embarcado'];
    fechaViaje = json['fechaViaje'];
    fechaEmbarque = json['fechaEmbarque'];
    fechaDesembarque = json['fechaDesembarque'];
    estado = json['estado'] ?? '';
    horaRecojo = json['horaRecojo'];
    direccion = json['direccion'];
    distrito = json['distrito'];
    coordenadas = json['coordenadas'];
    fechaArriboUnidad = json['fechaArriboUnidad'];
    idEmbarqueReal = json['idEmbarqueReal'];
    idDesembarqueReal = json['idDesembarqueReal'];
    embarcadoAux = json['embarcadoAux'] ?? '';
    coordenadasParadero = json['coordenadasParadero'] ?? '';
    modificado = json["modificado"];
    modificadoFechaArribo = json["modificadoFechaArribo"];
    modificadoAccion = json["modificadoAccion"] ?? 1;
    nuevo = json["nuevo"];
    asiento = json["asiento"];
  }

  Map<String, dynamic> toJsonBDLocal() => {
        "nroViaje": nroViaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "apellidos": apellidos,
        "nombres": nombres,
        "coordenadas": coordenadas,
        "embarcado": embarcado,
        "embarcadoAux": embarcadoAux,
        "direccion": direccion,
        "horaRecojo": horaRecojo,
        "distrito": distrito,
        "fechaEmbarque": fechaEmbarque,
        "fechaDesembarque": fechaDesembarque,
        "idEmbarqueReal": idEmbarqueReal,
        "idDesembarqueReal": idDesembarqueReal,
        "coordenadasParadero": coordenadasParadero,
        "fechaViaje": fechaViaje,
        "estado": estado,
        "modificado": modificado,
        "modificadoFechaArribo": modificadoFechaArribo,
        "fechaArriboUnidad": fechaArriboUnidad,
        "nuevo": nuevo,
        "modificadoAccion": modificadoAccion,
        "asiento": asiento
      };
}
