import 'package:embarques_tdp/src/models/documento.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/paradero.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';

class ViajesDomicilio {
  List<ViajeDomicilio> viajes = [];
  ViajesDomicilio.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;
    for (var element in jsonList) {
      final viaje = ViajeDomicilio.fromJsonMap(element);
      viajes.add(viaje);
    }
  }
}

class ViajeDomicilio {
  String? rpta = "";
  String? mensaje = "";
  String nroViaje = "";
  String codRuta = "";
  String codOperacion = "";
  String origen = "";
  String destino = "";
  String fechaSalida = "";
  String horaSalida = "";
  String servicio = "";
  String unidad = "";
  String sentido = "N"; //I: recojo R: reparto
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
  String horaLlegada = "";

  int odometroInicial = 0;
  int odometroFinal = 0;
  bool isExpanded = false;
  String seleccionado = "0"; //0: no seleccionado  1: seleccionado //2:no puede seleccionarlo por que esta finalizado
  String estadoViaje = "0"; //0: no finalizado 1: finalizado
  String estadoInicioViaje = "0"; //0: sincronizado //1: no sincronizado
  String cordenadaInicial = "";
  String cordenadaFinal = "";

  bool isActivo = false;

  List<PasajeroDomicilio> pasajeros = [];
  List<Tripulante> tripulantes = [];
  List<Parada> paradas = [];
  List<Paradero> paraderos = [];
  List<Documento> documentos = [];

  ViajeDomicilio();

  ViajeDomicilio.fromJsonMap(Map<String, dynamic> json) {
    rpta = json['rpta'];
    nroViaje = json['nroViaje'];
    codRuta = json['codRuta'];
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
    sentido = json['sentido'];
    horaLlegada = json['horaLlegada'];
    odometroInicial = json['odometroInicial'] ?? 0;
    odometroFinal = json['odometroFinal'] ?? 0;
    cordenadaInicial = json["cordenadaInicial"] ?? "";
    cordenadaFinal = json["cordenadaFinal"] ?? "";

    if (json['pasajeros'] != null && json['pasajeros'] != "[]") {
      //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
      var pasajerosAux = json['pasajeros'] as List;
      List<PasajeroDomicilio> _pasajeros = pasajerosAux.map((e) => PasajeroDomicilio.fromJsonMap(e)).toList();
      pasajeros = _pasajeros;
    }

    if (json['paradas'] != null && json['paradas'] != "[]") {
      var paradasAux = json['paradas'] as List;
      List<Parada> _paradas = paradasAux.map((e) => Parada.fromJsonMap(e)).toList();

      for (int i = 0; i < _paradas.length; i++) {
        //_paradas[i].nroViaje = nroViaje;
        paradas.add(_paradas[i]);
      }
    }

    if (json['paraderos'] != null && json['paraderos'] != "[]") {
      var paraderosAux = json['paraderos'] as List;
      List<Paradero> _paraderos = paraderosAux.map((e) => Paradero.fromJsonMap(e)).toList();

      for (int i = 0; i < _paraderos.length; i++) {
        //_paradas[i].nroViaje = nroViaje;
        paraderos.add(_paraderos[i]);
      }
    }
    //pasajeros = pasajerosAux;
  }

  ViajeDomicilio.fromJsonMapVinculado(Map<String, dynamic> json) {
    rpta = json['rpta'];
    mensaje = json['mensaje'];

    if (rpta == "0") {
      nroViaje = json['nroViaje'];
      codRuta = json['codRuta'];
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
      sentido = json['sentido'];
      horaLlegada = json['horaLlegada'];
      odometroInicial = json['odometroInicial'] ?? 0;
      odometroFinal = json['odometroFinal'] ?? 0;
      cordenadaInicial = json["cordenadaInicial"] ?? "";
      cordenadaFinal = json["cordenadaFinal"] ?? "";

      if (json['pasajeros'] != null && json['pasajeros'] != "[]") {
        //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
        var pasajerosAux = json['pasajeros'] as List;
        List<PasajeroDomicilio> _pasajeros = pasajerosAux.map((e) => PasajeroDomicilio.fromJsonMap(e)).toList();
        pasajeros = _pasajeros;
      }

      if (json['paradas'] != null && json['paradas'] != "[]") {
        var paradasAux = json['paradas'] as List;
        List<Parada> _paradas = paradasAux.map((e) => Parada.fromJsonMap(e)).toList();

        for (int i = 0; i < _paradas.length; i++) {
          //_paradas[i].nroViaje = nroViaje;
          paradas.add(_paradas[i]);
        }
      }

      if (json['paraderos'] != null && json['paraderos'] != "[]") {
        var paraderosAux = json['paraderos'] as List;
        List<Paradero> _paraderos = paraderosAux.map((e) => Paradero.fromJsonMap(e)).toList();

        for (int i = 0; i < _paraderos.length; i++) {
          //_paradas[i].nroViaje = nroViaje;
          paraderos.add(_paraderos[i]);
        }
      }
      //pasajeros = pasajerosAux;
    }
  }

  ViajeDomicilio.fromJsonMapBDLocal(Map<String, dynamic> json) {
    nroViaje = json['nroViaje'];
    codRuta = json['codRuta'];
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
    porSincronizar = json['porSincronizar'];
    ruc = json['ruc'];
    razonSocial = json['razonSocial'];
    telefono = json['telefono'];
    direccion = json['direccion'];
    sentido = json['sentido'];
    horaLlegada = json['horaLlegada'];
    odometroFinal = json['odometroFinal'];
    odometroInicial = json['odometroInicial'];
    estadoViaje = json['estadoViaje'];
    estadoInicioViaje = json['estadoInicioViaje'] ?? '0';
    seleccionado = json['seleccionado'];
    cordenadaInicial = json["cordenadaInicial"] ?? "";
    cordenadaFinal = json["cordenadaFinal"] ?? "";

    if (json['pasajeros'] != null && json['pasajeros'] != "[]") {
      //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
      var pasajerosAux = json['pasajeros'] as List;
      List<PasajeroDomicilio> _pasajeros = pasajerosAux.map((e) => PasajeroDomicilio.fromJsonMap(e)).toList();
      pasajeros = _pasajeros;
    }

    if (json['paradas'] != null && json['paradas'] != "[]") {
      var paradasAux = json['paradas'] as List;
      List<Parada> _paradas = paradasAux.map((e) => Parada.fromJsonMap(e)).toList();

      for (int i = 0; i < _paradas.length; i++) {
        //_paradas[i].nroViaje = nroViaje;
        paradas.add(_paradas[i]);
      }
    }

    if (json['paraderos'] != null && json['paraderos'] != "[]") {
      var paraderosAux = json['paraderos'] as List;
      List<Paradero> _paraderos = paraderosAux.map((e) => Paradero.fromJsonMap(e)).toList();

      for (int i = 0; i < _paraderos.length; i++) {
        //_paradas[i].nroViaje = nroViaje;
        paraderos.add(_paraderos[i]);
      }
    }
    //pasajeros = pasajerosAux;
  }

  Map<String, dynamic> toMapDatabase() {
    return {
      'nroViaje': nroViaje.trim(),
      'codRuta': codRuta.trim(),
      'codOperacion': codOperacion.trim(),
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
    };
  }

  Map<String, dynamic> toMapDatabaseLocal() {
    return {
      'nroViaje': nroViaje.trim(),
      'codRuta': codRuta.trim(),
      'codOperacion': codOperacion.trim(),
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
      'sentido': sentido.trim(),
      'horaLlegada': horaLlegada.trim(),
      'odometroInicial': odometroInicial,
      'cordenadaInicial': cordenadaInicial.trim(),
      'odometroFinal': odometroFinal,
      'cordenadaFinal': cordenadaFinal.trim(),
      'seleccionado': seleccionado.trim(),
      'estadoViaje': estadoViaje.trim(),
      "estadoInicioViaje": estadoInicioViaje
    };
  }
}
