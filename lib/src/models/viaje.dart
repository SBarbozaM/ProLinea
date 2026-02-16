import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';

import 'documento.dart';

class Viajes {
  List<Viaje> viajes = [];
  Viajes.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;
    for (var element in jsonList) {
      final viaje = Viaje.fromJsonMap(element);
      viajes.add(viaje);
    }
  }
  /* NUEVO 05/05/2023 */
  Viajes.fromJsonListPtoEmbarque(List<dynamic>? jsonList, String puntoEmbarque) {
    if (jsonList == null) return;
    for (var element in jsonList) {
      final viaje = Viaje.fromJsonMapPuntoEmbarque(element, puntoEmbarque);
      viajes.add(viaje);
    }
  }
}

class Viaje {
  String? rpta = "";
  String? mensaje = "";
  String nroViaje = "";
  String codRuta = "";
  String codOperacion = "";
  String subOperacionId = "";
  String subOperacionNombre = "";
  String origen = "";
  String destino = "";
  String fechaSalida = "";
  String horaSalida = "";
  String servicio = "";
  String unidad = "";
  int cantAsientos = 0;
  int cantReservados = 0;
  int cantDisponibles = 0;
  int cantEmbarcados = 0;
  int estadoEmbarque = 0;
  int porSincronizar = 1; //0 (True) 1 (False)
  String? ruc = "";
  String? razonSocial = "";
  String? telefono = "";
  String? direccion = "";
  List<Tripulante> tripulantes = [];
  List<Pasajero> pasajeros = [];
  List<PuntoEmbarque> puntosEmbarque = [];
  List<Documento> documentos = [];

  String tipoDocumento = "";
  String numDocumento = "";
  String cod_vehiculo = "";

  bool isExpanded = false;
  String FechaLlegada = "";
  String HoraLLegada = "";

  String impresoEmbarque = "0"; /* NUEVO 05/05/23 */
  String nombrePuntoEmbarqueActual = ""; /* NUEVO 05/05/23 */

  String totalEmbarcados = "0";

  String caracterSplit = "";
  String indexLectura = "";
  String corteLadoCantidad = "";

  int odometroInicial = 0;
  int odometroFinal = 0;
  String cordenadaInicial = "";
  String cordenadaFinal = "";
  String estadoViaje = "0";
  String estadoInicioViaje = "0";
  String seleccionado = "";

  String fechaConsultada = "";
  bool isActivo = false;

  Viaje() {}

  Viaje.constructor({
    required this.nroViaje,
    required this.codRuta,
    required this.codOperacion,
    required this.subOperacionId,
    required this.subOperacionNombre,
    required this.origen,
    required this.destino,
    required this.fechaSalida,
    required this.horaSalida,
    required this.servicio,
    required this.unidad,
    required this.cantAsientos,
    required this.cantReservados,
    required this.cantDisponibles,
    required this.cantEmbarcados,
    required this.estadoEmbarque,
    required this.porSincronizar,
    required this.ruc,
    required this.razonSocial,
    required this.telefono,
    required this.direccion,
    required this.caracterSplit,
    required this.indexLectura,
    required this.corteLadoCantidad,
    required this.cordenadaInicial,
    required this.cordenadaFinal,
  });

  Viaje.fromJsonMap(Map<String, dynamic> json) {
    rpta = json['rpta'] ?? "";
    nroViaje = json['nroViaje'] ?? "";
    codRuta = json['codRuta'] ?? "";
    codOperacion = json['codOperacion'];
    subOperacionId = json['subOperacionId'] ?? "";
    subOperacionNombre = json['subOperacionNombre'] ?? "";
    origen = json['origen'] ?? "";
    destino = json['destino'] ?? "";
    fechaSalida = json['fechaSalida'] ?? "";
    horaSalida = json['horaSalida'] ?? "";
    servicio = json['servicio'] ?? "";
    unidad = json['unidad'] ?? "";
    cantAsientos = json['cantAsientos'] ?? 0;
    cantReservados = json['cantReservados'] ?? 0;
    cantDisponibles = json['cantDisponibles'] ?? 0;
    cantEmbarcados = json['cantEmbarcados'] ?? 0;
    estadoEmbarque = json['estadoEmbarque'] ?? 0;
    ruc = json['ruc'] ?? "";
    razonSocial = json['razonSocial'] ?? "";
    telefono = json['telefono'] ?? "";
    direccion = json['direccion'] ?? "";
    tipoDocumento = json['tipoDocumento'] ?? '';
    numDocumento = json['numDocumento'] ?? '';
    cod_vehiculo = json['cod_vehiculo'] ?? '';

    if (json['pasajeros'] != null && json['pasajeros'] != "[]") {
      //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
      var pasajerosAux = json['pasajeros'] as List;
      List<Pasajero> _pasajeros = pasajerosAux.map((e) => Pasajero.fromJsonMap(e)).toList();
      pasajeros = _pasajeros;
    }

    if (json['puntosEmbarque'] != null && json['puntosEmbarque'] != "[]") {
      var puntosAux = json['puntosEmbarque'] as List;
      List<PuntoEmbarque> _puntosEmbarque = puntosAux.map((e) => PuntoEmbarque.fromJsonMap(e)).toList();

      for (int i = 0; i < _puntosEmbarque.length; i++) {
        _puntosEmbarque[i].nroViaje = nroViaje;
      }
      puntosEmbarque = _puntosEmbarque;
    }

    if (json['tripulantes'] != null && json['tripulantes'] != "[]") {
      var tripulantesAux = json['tripulantes'] as List;
      List<Tripulante> _tripulantes = tripulantesAux.map((e) => Tripulante.fromJsonMap(e)).toList();

      for (int i = 0; i < _tripulantes.length; i++) {
        //if (_tripulantes[i].tipoDoc != "" && _tripulantes[i].numDoc != "") {
        _tripulantes[i].nroViaje = nroViaje;
        tripulantes.add(_tripulantes[i]);
        //}
      }
    }
    //pasajeros = pasajerosAux;
  }

  Viaje.fromJsonMapVinculadoRemote(Map<String, dynamic> json) {
    rpta = json['rpta'];
    mensaje = json['mensaje'];
    nroViaje = json['nroViaje'];
    codRuta = json['codRuta'];
    codOperacion = json['codOperacion'];
    subOperacionId = json['subOperacionId'];
    subOperacionNombre = json['subOperacionNombre'];
    origen = json['origen'];
    destino = json['destino'];
    fechaSalida = json['fechaSalida'];
    horaSalida = json['horaSalida'];
    servicio = json['servicio'];
    unidad = json['unidad'];
    cantAsientos = json['cantAsientos'];
    cantReservados = json['cantReservados'];
    cantDisponibles = json['cantDisponibles'];
    cantEmbarcados = json['cantEmbarcados'];
    estadoEmbarque = json['estadoEmbarque'];
    ruc = json['ruc'];
    razonSocial = json['razonSocial'];
    telefono = json['telefono'];
    direccion = json['direccion'];
    caracterSplit = json["caracterSplit"];
    indexLectura = json["indexLectura"].toString();
    corteLadoCantidad = json["corteLadoCantidad"];
    odometroInicial = json["odometroInicial"];
    odometroFinal = json["odometroFinal"] ?? '';
    tipoDocumento = json["tipoDocumento"];
    numDocumento = json["numDocumento"];
    cod_vehiculo = json["cod_vehiculo"];
    impresoEmbarque = json["impresoEmbarque"];
    totalEmbarcados = json["totalEmbarcados"];
    cordenadaInicial = json["cordenadaInicial"] ?? '';
    cordenadaFinal = json["cordenadaFinal"] ?? '';

    if (json['pasajeros'] != null && json['pasajeros'] != "[]") {
      //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
      var pasajerosAux = json['pasajeros'] as List;
      List<Pasajero> _pasajeros = pasajerosAux.map((e) => Pasajero.fromJsonMapRemote(e)).toList();
      pasajeros = _pasajeros;
    }

    if (json['puntosEmbarque'] != null && json['puntosEmbarque'] != "[]") {
      var puntosAux = json['puntosEmbarque'] as List;
      List<PuntoEmbarque> _puntosEmbarque = puntosAux.map((e) => PuntoEmbarque.fromJsonMap(e)).toList();

      for (int i = 0; i < _puntosEmbarque.length; i++) {
        _puntosEmbarque[i].nroViaje = nroViaje;
      }
      puntosEmbarque = _puntosEmbarque;
    }

    if (json['tripulantes'] != null && json['tripulantes'] != "[]") {
      var tripulantesAux = json['tripulantes'] as List;
      List<Tripulante> _tripulantes = tripulantesAux.map((e) => Tripulante.fromJsonMap(e)).toList();

      for (int i = 0; i < _tripulantes.length; i++) {
        //if (_tripulantes[i].tipoDoc != "" && _tripulantes[i].numDoc != "") {
        _tripulantes[i].nroViaje = nroViaje;
        tripulantes.add(_tripulantes[i]);
        //}
      }
    }
    //pasajeros = pasajerosAux;
  }

  Viaje.fromJsonMapVinculadoLocal(Map<String, dynamic> json) {
    rpta = json['rpta'] ?? '';
    mensaje = json['mensaje'] ?? '';
    nroViaje = json['nroViaje'];
    codRuta = json['codRuta'];
    codOperacion = json['codOperacion'];
    subOperacionId = json['subOperacionId'];
    subOperacionNombre = json['subOperacionNombre'];
    codOperacion = json['codOperacion'];
    origen = json['origen'];
    destino = json['destino'];
    fechaSalida = json['fechaSalida'];
    horaSalida = json['horaSalida'];
    servicio = json['servicio'];
    unidad = json['unidad'];
    cantAsientos = json['cantAsientos'];
    cantReservados = json['cantReservados'];
    cantDisponibles = json['cantDisponibles'];
    cantEmbarcados = json['cantEmbarcados'];
    estadoEmbarque = json['estadoEmbarque'];
    ruc = json['ruc'];
    razonSocial = json['razonSocial'];
    telefono = json['telefono'];
    direccion = json['direccion'];
    caracterSplit = json["caracterSplit"] ?? '';
    indexLectura = json["indexLectura"].toString() ?? '';
    corteLadoCantidad = json["corteLadoCantidad"] ?? '';
    odometroInicial = json["odometroInicial"] == "" || json["odometroInicial"] == null ? 0 : json["odometroInicial"];
    odometroFinal = json["odometroFinal"] == "" || json["odometroFinal"] == null ? 0 : json["odometroFinal"];
    seleccionado = json["seleccionado"] ?? '';
    estadoViaje = json["estadoViaje"] ?? '';
    estadoInicioViaje = json["estadoInicioViaje"] ?? '';
    cordenadaInicial = json["cordenadaInicial"] ?? '';
    cordenadaFinal = json["cordenadaFinal"] ?? '';
    fechaConsultada = json["fechaConsultada"] ?? '';

    if (json['pasajeros'] != null && json['pasajeros'] != "[]") {
      //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
      var pasajerosAux = json['pasajeros'] as List;
      List<Pasajero> _pasajeros = pasajerosAux.map((e) => Pasajero.fromJsonMapRemote(e)).toList();
      pasajeros = _pasajeros;
    }

    if (json['puntosEmbarque'] != null && json['puntosEmbarque'] != "[]") {
      var puntosAux = json['puntosEmbarque'] as List;
      List<PuntoEmbarque> _puntosEmbarque = puntosAux.map((e) => PuntoEmbarque.fromJsonMap(e)).toList();

      for (int i = 0; i < _puntosEmbarque.length; i++) {
        _puntosEmbarque[i].nroViaje = nroViaje;
      }
      puntosEmbarque = _puntosEmbarque;
    }

    if (json['tripulantes'] != null && json['tripulantes'] != "[]") {
      var tripulantesAux = json['tripulantes'] as List;
      List<Tripulante> _tripulantes = tripulantesAux.map((e) => Tripulante.fromJsonMap(e)).toList();

      for (int i = 0; i < _tripulantes.length; i++) {
        //if (_tripulantes[i].tipoDoc != "" && _tripulantes[i].numDoc != "") {
        _tripulantes[i].nroViaje = nroViaje;
        tripulantes.add(_tripulantes[i]);
        //}
      }
    }
    //pasajeros = pasajerosAux;
  }

  /* NUEVO 05/05/23 */
  Viaje.fromJsonMapPuntoEmbarque(Map<String, dynamic> json, String puntoEmbarque) {
    nroViaje = json['nroViaje'];
    codRuta = json['codRuta'];
    codOperacion = json['codOperacion'];
    subOperacionId = json['subOperacionId'];
    subOperacionNombre = json['subOperacionNombre'];
    origen = json['origen'];
    destino = json['destino'];
    fechaSalida = json['fechaSalida'];
    horaSalida = json['horaSalida'];
    servicio = json['servicio'];
    unidad = json['unidad'];
    cantAsientos = json['cantAsientos'];
    cantReservados = json['cantReservados'];
    cantDisponibles = json['cantDisponibles'];
    cantEmbarcados = json['cantEmbarcados'];
    estadoEmbarque = json['estadoEmbarque'];
    impresoEmbarque = json['impresoEmbarque'];
    ruc = json['ruc'];
    razonSocial = json['razonSocial'];
    telefono = json['telefono'];
    direccion = json['direccion'];
    totalEmbarcados = json['totalEmbarcados'];
    cordenadaInicial = json["cordenadaInicial"] ?? '';
    cordenadaFinal = json["cordenadaFinal"] ?? '';
    nombrePuntoEmbarqueActual = puntoEmbarque;

    if (json['tripulantes'] != null && json['tripulantes'] != "[]") {
      var tripulantesAux = json['tripulantes'] as List;
      List<Tripulante> _tripulantes = tripulantesAux.map((e) => Tripulante.fromJsonMap(e)).toList();

      for (int i = 0; i < _tripulantes.length; i++) {
        //if (_tripulantes[i].tipoDoc != "" && _tripulantes[i].numDoc != "") {
        _tripulantes[i].nroViaje = nroViaje;
        tripulantes.add(_tripulantes[i]);
        //}
      }
    }
    //pasajeros = pasajerosAux;
  }

  Map<String, dynamic> toMapDatabase() {
    return {
      'nroViaje': nroViaje.trim(),
      'codRuta': codRuta.trim(),
      'codOperacion': codOperacion.trim(),
      'subOperacionId': subOperacionId.trim(),
      'subOperacionNombre': subOperacionNombre.trim(),
      'origen': origen.trim(),
      'destino': destino.trim(),
      'fechaSalida': fechaSalida.trim(),
      'horaSalida': horaSalida.trim(),
      'servicio': servicio.trim(),
      'unidad': unidad.trim(),
      'cantAsientos': cantAsientos,
      'cantReservados': cantReservados,
      'cantDisponibles': cantDisponibles,
      'cantEmbarcados': cantEmbarcados,
      'estadoEmbarque': estadoEmbarque,
      'porSincronizar': porSincronizar,
      'ruc': ruc?.trim(),
      'razonSocial': razonSocial?.trim(),
      'telefono': telefono?.trim(),
      'direccion': direccion?.trim(),
      'caracterSplit': caracterSplit.trim(),
      'indexLectura': indexLectura.trim(),
      'corteLadoLectura': corteLadoCantidad.trim(),
      'odometroInicial': odometroInicial,
      'odometroFinal': odometroFinal,
      'seleccionado': seleccionado.trim(),
      'estadoViaje': estadoViaje.trim(),
      'estadoInicioViaje': estadoInicioViaje.trim(),
      'cordenadaInicial': cordenadaInicial.trim(),
      'cordenadaFinal': cordenadaFinal.trim(),
      'fechaConsultada': fechaConsultada.trim(),
    };
  }
}
