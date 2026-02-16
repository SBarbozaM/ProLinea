import 'dart:convert';

import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:async';

import '../connection/conexion.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class ViajeServicio {
  final String _url = Conexion.apiUrl;

  final _viajeStreamController = StreamController<Viaje>.broadcast();

  Function(Viaje) get viajeSink => _viajeStreamController.sink.add;

  Stream<Viaje> get viajeStream => _viajeStreamController.stream;

  void disposeStreams() {
    //CERRANDO LAS INSTANCIAS DEL SINK QUE ES LA INFO DE ENTRADA DEL STREAM
    _viajeStreamController.close();
  }

  Future<Response?> cambiarEstadoPuntoEmbarqueV2(PuntoEmbarque puntoEmbarque, String tipoDoc, String numDoc, Viaje viaje) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = tipoDoc;
    mapFormData['numDoc'] = numDoc;
    mapFormData['nroViaje'] = viaje.nroViaje;
    mapFormData['codOperacion'] = viaje.codOperacion;
    mapFormData['codRuta'] = viaje.codRuta;
    mapFormData['fechaViaje'] = viaje.fechaSalida + " " + viaje.horaSalida;
    mapFormData['estadoPuntoEmb'] = puntoEmbarque.eliminado.toString();
    mapFormData['idPuntoEmbarque'] = puntoEmbarque.id;
    mapFormData['nombrePuntoEmbarque'] = puntoEmbarque.nombre;
    mapFormData['fechaAccion'] = puntoEmbarque.fechaAccion;

    final url = _url + 'cambiar_estado_puntoEmbarque';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      return resp;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Viaje> _procesarRespuestaPostFormData(Uri url) async {
    Viaje viaje = new Viaje();
    String result = "";

    try {
      final resp = await http.get(url, headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          result = decodedData['rpta'];
          if (result == "0") {
            final viajeDB = new Viaje.fromJsonMap(decodedData);
            viaje = viajeDB;
          } else {
            viaje.rpta = result;
          }
        }
      }
    } catch (identifier) {
      viaje.rpta = "9"; //No hay internet
    }

    return viaje;
  }

  Future<Viaje> obtenerViajeConductor(String tipoDoc, String numDoc, String nroViaje) async {
    final url = _url + 'obtener_viaje_conductor/' + tipoDoc + '/' + numDoc + '/' + nroViaje;

    final resp = await _procesarRespuestaPostFormData(Uri.parse(url));
    return resp;
  }

  Future<String> finalizarViaje(String nroViaje, String codOperacion, Usuario usuario) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['nroViaje'] = nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['tipoDoc'] = usuario.tipoDoc;
    mapFormData['numDoc'] = usuario.numDoc;

    String rpta = "";

    final url = _url + 'finalizar_viaje_v2';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "4";
      }
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }
  //si-gps
  Future<String> finalizarViaje_v2_1(
    String nroViaje,
    String codOperacion,
    Usuario usuario,
    String Coordenadas,
  ) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['nroViaje'] = nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['tipoDoc'] = usuario.tipoDoc;
    mapFormData['numDoc'] = usuario.numDoc;
    mapFormData['cordenadas'] = Coordenadas;

    String rpta = "";

    final url = _url + 'finalizar_viaje_v2_1';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "4";
      }
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }
  //si-gps
  Future<String> finalizarViajeV4(
    String nroViaje,
    String codOperacion,
    Usuario usuario,
    String odometroFin,
    String cordenadaFinal,
  ) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['nroViaje'] = nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['tipoDoc'] = usuario.tipoDoc;
    mapFormData['numDoc'] = usuario.numDoc;
    mapFormData['OdometroFin'] = odometroFin;
    mapFormData['cordenadaFinal'] = cordenadaFinal;

    String rpta = "";

    final url = _url + 'finalizar_viaje_v4';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15)).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "4";
      }
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }
  //si-gps
  Future<String> finalizarViajeV5(
    String nroViaje,
    String codOperacion,
    Usuario usuario,
    String odometroFin,
    String cordenadaFinal,
    String odometroPor,
  ) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['nroViaje'] = nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['tipoDoc'] = usuario.tipoDoc;
    mapFormData['numDoc'] = usuario.numDoc;
    mapFormData['OdometroFin'] = odometroFin;
    mapFormData['cordenadaFinal'] = cordenadaFinal;
    mapFormData['odometroPor'] = odometroPor;

    String rpta = "";

    final url = _url + 'finalizar_viaje_v5';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15)).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "4";
      }
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }

  Future<List<Viaje>> obtenerViajesRutaFecha(String codOperacion, String codRuta, String fecha) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['codOperacion'] = codOperacion;
    mapFormData['codRuta'] = codRuta;
    mapFormData['fecha'] = fecha;
    List<Viaje> listaViajes = [];
    final url = _url + 'obtener_viajes_ruta_fecha';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajes = Viajes.fromJsonList(decodedData);
          listaViajes.addAll(viajes.viajes);
        }
      } else {}
    } catch (e) {}

    return listaViajes;
  }

  //TODO: OBTENER VIAJES NO FINALIZADOS

  Future<List<Viaje>> obtenerViajesNoFinalizados(String codOperacion, String codRuta, String fecha) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['codOperacion'] = codOperacion;
    mapFormData['codRuta'] = codRuta;
    mapFormData['fecha'] = fecha;
    List<Viaje> listaViajes = [];
    final url = _url + 'obtener_viajes_no_finalizados';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajes = Viajes.fromJsonList(decodedData);
          listaViajes.addAll(viajes.viajes);
        }
      } else {}
    } catch (e) {}

    return listaViajes;
  }

  //TODO: FINALIZAR VIAJE FORZADO

  Future<String> finalizarViajeForzado(
    String numViaje,
    String codOperacion,
    String tipoDoc,
    String numDoc,
    String fecha,
  ) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['nroViaje'] = numViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['tipoDoc'] = tipoDoc;
    mapFormData['numDoc'] = numDoc;
    mapFormData['fecha'] = fecha;
    final url = _url + 'finalizar_viaje_forzado';

    String rpta = "";

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "4";
      }
      rpta;
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }

  Future<Viaje> obtenerViajeManifiesto(String nroViaje, String codOperacion, String tipoDoc, String numDoc) async {
    final url = _url + 'obtener_viaje_datos_manifiesto/' + nroViaje + '/' + codOperacion + '/' + tipoDoc + '/' + numDoc;

    final resp = await _procesarRespuestaPostFormData(Uri.parse(url));
    return resp;
  }

  Future<String> cambiarEstadoPuntoEmbarque(PuntoEmbarque puntoEmbarque, Usuario usuario, Viaje viaje) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = usuario.tipoDoc;
    mapFormData['numDoc'] = usuario.numDoc;
    mapFormData['nroViaje'] = viaje.nroViaje;
    mapFormData['codOperacion'] = viaje.codOperacion;
    mapFormData['codRuta'] = viaje.codRuta;
    mapFormData['fechaViaje'] = viaje.fechaSalida + " " + viaje.horaSalida;
    mapFormData['estadoPuntoEmb'] = puntoEmbarque.eliminado.toString();
    mapFormData['idPuntoEmbarque'] = puntoEmbarque.id;
    mapFormData['nombrePuntoEmbarque'] = puntoEmbarque.nombre;
    mapFormData['fechaAccion'] = puntoEmbarque.fechaAccion;

    String rpta = "";

    final url = _url + 'cambiar_estado_puntoEmbarque';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "2";
      }
    } catch (e) {
      print(e);
      rpta = "9";
    }

    return rpta;
  }

  Future<ViajeDomicilio> obtenerViajeConductorDomicilio(String tipoDoc, String numDoc, String nroViaje) async {
    ViajeDomicilio viaje = new ViajeDomicilio();
    String result = "";
    final url = _url + 'obtener_viaje_conductor_domicilio_v5/' + tipoDoc + '/' + numDoc + '/' + nroViaje;

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          result = decodedData['rpta'];
          if (result == "0") {
            final viajeDB = new ViajeDomicilio.fromJsonMap(decodedData);
            viaje = viajeDB;
          } else {
            viaje.rpta = result;
          }
        }
      }
    } catch (identifier) {
      viaje.rpta = "9"; //No hay internet
    }

    return viaje;
  }

  Future<ViajeDomicilio> obtenerViajeVinculadoDomicilio(Usuario usuario) async {
    ViajeDomicilio viaje = new ViajeDomicilio();
    final url = _url + 'obtener_viaje_conductor_domicilio_v5/' + usuario.tipoDoc + '/' + usuario.numDoc + '/' + usuario.viajeEmp;

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 15), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajeDB = new ViajeDomicilio.fromJsonMapVinculado(decodedData);
          viaje = viajeDB;
        }
      }
    } catch (identifier) {
      viaje.rpta = "1";
      viaje.mensaje = "¡Ha ocurrido un error!";
    }

    return viaje;
  }

  //OBETENER VIAJES CONDUCTOR RECOJO Y REPARTO
  Future<List<ViajeDomicilio>> obtenerViajesConductorVinculadoDomicilio(Usuario usuario) async {
    List<ViajeDomicilio> Listaviaje = <ViajeDomicilio>[];
    final url = _url + 'obtener_viajes_domicilio_conductor/' + usuario.tipoDoc + '/' + usuario.numDoc;

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);

        final viajeDB = (decodedData as List).map((e) => ViajeDomicilio.fromJsonMapVinculado(e)).toList();
        Listaviaje = viajeDB;
      }
    } catch (identifier) {
      return [];
    }

    return Listaviaje;
  }

  //OBETENER POSIBLES PASAJEROS
  Future<List<PasajeroDomicilio>> obtenerPosiblesPasajeros(String nroViaje) async {
    List<PasajeroDomicilio> ListaPasajeros = <PasajeroDomicilio>[];
    final url = _url + 'listarPosiblesPasajeros/${nroViaje}';

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);

        final PasajerosDB = (decodedData as List).map((e) => PasajeroDomicilio.fromJsonMap(e)).toList();
        ListaPasajeros = PasajerosDB;
      }
    } catch (identifier) {
      return [];
    }

    return ListaPasajeros;
  }

  //oobtener viaje cercano
  Future<Response?> obtenerViajeCercano(String tipoDoc, String numDoc, String codOperacion) async {
    ViajeDomicilio viaje = new ViajeDomicilio();
    final url = _url + 'obtener_viaje_cercano/' + tipoDoc + '/' + numDoc + '/' + codOperacion;

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      return resp;
    } catch (e) {
      return null;
    }
  }

  Future<Viaje> obtenerViajeVinculadoBolsa(Usuario usuario) async {
    Viaje viaje = new Viaje();
    final url = _url + 'obtener_viaje_conductor_bolsa_v2/' + usuario.tipoDoc + '/' + usuario.numDoc + '/' + usuario.viajeEmp;

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajeDB = new Viaje.fromJsonMapVinculadoRemote(decodedData);
          viaje = viajeDB;
        }
      }
    } catch (identifier) {
      viaje.rpta = "1";
      viaje.mensaje = "¡Ha ocurrido un error!";
    }

    return viaje;
  }

  Future<List<PuntoEmbarque>> ListarPuntosEmbarqueXRuta(String nroViaje, String codOperacion) async {
    final url = _url + 'ListarPuntosEmbarqueXRuta/${nroViaje}/${codOperacion}';

    List<PuntoEmbarque> puntos = [];

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body) as List;
        puntos = decodedData.map((e) => new PuntoEmbarque.fromJsonMap(e)).toList();
      }
      return puntos;
    } catch (identifier) {
      return [];
    }
  }

  Future<List<PuntoEmbarque>> ListarPuntosEmbarqueXFecha(Usuario usuario) async {
    final url = '${_url}ListarPuntosEmbarqueXFecha/${usuario.codOperacion}/${usuario.tipoDoc}/${usuario.numDoc}';
    List<PuntoEmbarque> puntos = [];

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body) as List;
        puntos = decodedData.map((e) => new PuntoEmbarque.fromJsonMap(e)).toList();
      }
      return puntos;
    } catch (identifier) {
      return [];
    }
  }

//TODO: ONBTENER INFORMACION VIAJE VINCULADO BOLSA SUPERVISOR
  Future<Viaje> obtenerViajeVinculadoBolsaSupervisor(String tipoDoc, String numDoc, String viajeEmp) async {
    Viaje viaje = new Viaje();
    final url = _url + 'obtener_viaje_conductor_bolsa_v2/' + tipoDoc + '/' + numDoc.trim() + '/' + viajeEmp;

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajeDB = new Viaje.fromJsonMapVinculadoRemote(decodedData);
          viaje = viajeDB;
        }
      }
    } catch (identifier) {
      viaje.rpta = "1";
      viaje.mensaje = "¡Ha ocurrido un error!";
    }

    return viaje;
  }

  Future<Viaje> obtenerViajeVinculadoBolsaSupervisor_v4(String tipoDoc, String numDoc, String viajeEmp) async {
    Viaje viaje = new Viaje();
    final url = _url + 'obtener_viaje_conductor_bolsa_v4/' + tipoDoc + '/' + numDoc.trim() + '/' + viajeEmp;

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajeDB = new Viaje.fromJsonMapVinculadoRemote(decodedData);
          viaje = viajeDB;
        }
      }
    } catch (identifier) {
      viaje.rpta = "1";
      viaje.mensaje = "¡Ha ocurrido un error!";
    }

    return viaje;
  }

  //OBTENER VIAJES MANIFIESTO
  Future<List<Viaje>> obtenerViajesManifiesto(
    String ptoEmbarque,
    String fecha,
    Usuario usuario,
    String impreso,
  ) async {
    var mapFormData = <String, dynamic>{};

    mapFormData['ptoEmbarque'] = ptoEmbarque;
    mapFormData['fechaViaje'] = fecha;
    mapFormData['tDocUsuario'] = usuario.tipoDoc;
    mapFormData['nDocUsuario'] = usuario.numDoc;
    mapFormData['codOperacion'] = usuario.codOperacion;
    mapFormData['impreso'] = impreso;
    List<Viaje> listaViajes = [];
    final url = '${_url}obtener_viajes_manifiesto_v2';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        const Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajes = Viajes.fromJsonListPtoEmbarque(decodedData, ptoEmbarque);
          listaViajes.addAll(viajes.viajes);
          print(viajes);
        }
      } else {}
    } catch (e) {
      listaViajes = [];
    }

    return listaViajes;
  }

  //TODO: OBTENER VIAJES PROGRAMADOS DEL CONDUCTOR

  Future<List<Viaje>> obtenerViajesProgramdosBolsa(Usuario usuario) async {
    List<Viaje> Listaviaje = <Viaje>[];
    final url = _url + 'obtener_viajes_bolsa_conductor_v1/${usuario.tipoDoc}/${usuario.numDoc}/${usuario.codOperacion}';

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"});
      // .timeout(
      //   Duration(seconds: 15), // Establece el tiempo de espera en segundos
      //   onTimeout: () {
      //     throw TimeoutException('La solicitud excedió el tiempo de espera');
      //   },
      // );
      //TODO: cambiar el timeout INICIAR VIAJE

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);

        final viajeDB = (decodedData as List).map((e) => Viaje.fromJsonMapVinculadoRemote(e)).toList();
        Listaviaje = viajeDB;
      }
    } catch (identifier) {
      return [];
    }

    return Listaviaje;
  }

//Actualizar
  Future<List<Viaje>> obtenerViajesProgramdosBolsaActualizar(String tipoDoc, String numDoc, String codOperacion) async {
    List<Viaje> Listaviaje = <Viaje>[];
    final url = _url + 'obtener_viajes_bolsa_conductor_v1/${tipoDoc}/${numDoc}/${codOperacion}';

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"});
      // .timeout(
      //   Duration(seconds: 15), // Establece el tiempo de espera en segundos
      //   onTimeout: () {
      //     throw TimeoutException('La solicitud excedió el tiempo de espera');
      //   },
      // );
      //TODO: cambiar el timeout INICIAR VIAJE

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);

        final viajeDB = (decodedData as List).map((e) => Viaje.fromJsonMapVinculadoRemote(e)).toList();
        Listaviaje = viajeDB;
      }
    } catch (identifier) {
      return [];
    }

    return Listaviaje;
  }

  //TODO: ONBTENER INFORMACION VIAJE VINCULADO BOLSA SUPERVISOR
  Future<dynamic> obtenerDatosDeEmbarqueMultiple(Usuario usuario, String idEmbarque) async {
    final url = '${_url}obtener_prereservas_xPEmb/${usuario.codOperacion}/${usuario.tipoDoc}/${usuario.numDoc}/${idEmbarque}';

    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"});

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        return decodedData;
      } else {
        // Devuelve un Map en caso de error en la respuesta
        return {
          'item1': '-1',
          'item2': 'Error conexión API',
          'item3': [],
          'item4': [],
          'item5': [],
        };
      }
    } catch (e) {
      // Devuelve un Map en caso de excepción
      return {
        'item1': '-1',
        'item2': 'Error catch petición',
        'item3': [],
        'item4': [],
        'item5': [],
      };
    }
  }
}
