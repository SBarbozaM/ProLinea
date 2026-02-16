import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:async';

import '../connection/conexion.dart';
import '../models/pasajero.dart';
import '../models/pasajero_habilitado.dart';
import '../models/viaje_domicilio/pasajero_domicilio.dart';

class PasajeroServicio {
  final String _url = Conexion.apiUrl;

  final _pasajeroStreamController = StreamController<Pasajero>.broadcast();

  Function(Pasajero) get pasajeroSink => _pasajeroStreamController.sink.add;

  Stream<Pasajero> get pasajeroStream => _pasajeroStreamController.stream;

  void disposeStreams() {
    //CERRANDO LAS INSTANCIAS DEL SINK QUE ES LA INFO DE ENTRADA DEL STREAM
    _pasajeroStreamController.close();
  }

  //TODO: JS: 18/7/23
  Future<Response?> cambiarEstadoPrereservaV4(Pasajero pasajero, String codOperacion, String nuevoNroViaje, String usuario, String nroViaje) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['usuario'] = usuario;
    mapFormData['tipoDoc'] = pasajero.tipoDoc.toString().trim();
    mapFormData['numDoc'] = pasajero.numDoc.toString().trim();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['puntoEmbarque'] = pasajero.idEmbarqueReal;
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    mapFormData['asiento'] = pasajero.asiento.toString();
    mapFormData['estadoReserva'] = pasajero.estado;
    mapFormData['nuevoNroViaje'] = nuevoNroViaje;
    mapFormData['codRutaPrereserva'] = pasajero.idRuta;

    final url = _url + 'cambiar_estado_prereserva_v4';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      return resp;
    } catch (e) {
      return null;
    }
  }
  //si-gps-viaje-bolsa&embarque-multiple
  Future<Response?> cambiarEstadoPrereservaV5(Pasajero pasajero, String codOperacion, String nuevoNroViaje, String usuario, String nroViaje) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['usuario'] = usuario;
    mapFormData['tipoDoc'] = pasajero.tipoDoc.toString().trim();
    mapFormData['numDoc'] = pasajero.numDoc.toString().trim();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['puntoEmbarque'] = pasajero.idEmbarqueReal;
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    mapFormData['asiento'] = pasajero.asiento.toString();
    mapFormData['estadoReserva'] = pasajero.estado;
    mapFormData['nuevoNroViaje'] = nuevoNroViaje;
    mapFormData['codRutaPrereserva'] = pasajero.idRuta;
    mapFormData['coordenadas'] = pasajero.coordenadas;
    mapFormData['embarcadoPor'] = pasajero.embarcadoPor;

    final url = _url + 'cambiar_estado_prereserva_v5';
    
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      return resp;
    } catch (e) {
      return null;
    }
  }

  Future<List<PasajeroHabilitado>> _procesarRespuestaPostFormData(Uri url) async {
    List<PasajeroHabilitado> listaPasajerosHab = [];

    try {
      final resp = await http.get(url, headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final pasajeros = new PasajerosHabilitados.fromJsonList(decodedData);
          listaPasajerosHab.addAll(pasajeros.pasajeros);
        }
      }
    } catch (e) {}

    return listaPasajerosHab;
  }

  Future<List<PasajeroHabilitado>> obtenerPasajerosHabilitados(String nroViaje, String codOperacion) async {
    final url = _url + 'obtener_pasajeros_habilitados/' + nroViaje + '/' + codOperacion;

    final resp = await _procesarRespuestaPostFormData(Uri.parse(url));
    return resp;
  }

  Future<String> cambiarEstadoEmbarquePasajero(Pasajero pasajero, String codOperacion) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['puntoEmbarque'] = pasajero.idEmbarqueReal;
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    String rpta = "";

    final url = _url + 'cambiar_estado_embarque_pasajero';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
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
      rpta = "9";
    }

    return rpta;
  }

  Future<List<Pasajero>> obtener_prereservas(String nroViaje, String tDocUsuario, String nDocUsuario, String codOperacion) async {
    final url = '${_url}obtener_viaje_prereservas_v3/${nroViaje}/${tDocUsuario}/${nDocUsuario}/${codOperacion}';

    final resp = await _procesarRespuestaPostFormDataPrereservas(Uri.parse(url));
    print(resp);
    return resp;
  }

  //#JS:23112023
  Future<List<Pasajero>> obtener_nuevos_pasajeros({
    required String fecha,
    required String nroViaje,
    required String tDocUsuario,
    required String nDocUsuario,
    required String codOperacion,
  }) async {
    final url = '${_url}obtener_nuevos_pasajeros_v1';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['fecha'] = fecha;
    mapFormData['nro_viaje'] = nroViaje;
    mapFormData['TDoc_Usuario'] = tDocUsuario;
    mapFormData['NDoc_Usuario'] = nDocUsuario;
    mapFormData['codOperacion'] = codOperacion;

    List<Pasajero> listaPrereservas = [];

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final pasajeros = new Pasajeros.fromJsonList(decodedData);
          listaPrereservas.addAll(pasajeros.pasajeros);
        }
      }
    } catch (e) {
      listaPrereservas = [];
    }

    return listaPrereservas;
  }
  //----------------------

  //00495723
  //04405171
  //29639421

  Future<List<Pasajero>> _procesarRespuestaPostFormDataPrereservas(Uri url) async {
    List<Pasajero> listaPrereservas = [];

    try {
      final resp = await http.get(url, headers: {"Content-Type": "application/json"});
      // .timeout(
      //   Duration(seconds: 10), // Establece el tiempo de espera en segundos
      //   onTimeout: () {
      //     throw TimeoutException('La solicitud excedió el tiempo de espera');
      //   },
      // );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final pasajeros = new Pasajeros.fromJsonList(decodedData);
          listaPrereservas.addAll(pasajeros.pasajeros);
        }
      }
    } catch (e) {
      listaPrereservas = [];
    }

    return listaPrereservas;
  }

  Future<String> cambiarEstadoPrereserva(Pasajero pasajero, String codOperacion, String nuevoNroViaje, String usuario) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['usuario'] = usuario;
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['puntoEmbarque'] = pasajero.idEmbarqueReal;
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    mapFormData['asiento'] = pasajero.asiento.toString();
    mapFormData['estadoReserva'] = pasajero.estado;
    mapFormData['nuevoNroViaje'] = nuevoNroViaje;

    String rpta = "";

    final url = _url + 'cambiar_estado_prereserva';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
        print(rpta);
      } else {
        rpta = "3";
      }
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }

  Future<String> cambiarEstadoPrereservaV2(Pasajero pasajero, String codOperacion, String nuevoNroViaje, String usuario) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['usuario'] = usuario;
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['puntoEmbarque'] = pasajero.idEmbarqueReal;
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    mapFormData['asiento'] = pasajero.asiento.toString();
    mapFormData['estadoReserva'] = pasajero.estado;
    mapFormData['nuevoNroViaje'] = nuevoNroViaje;
    mapFormData['codRutaPrereserva'] = pasajero.idRuta;

    String rpta = "";

    final url = _url + 'cambiar_estado_prereserva_v3';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
        print(rpta);
      } else {
        rpta = "3";
      }
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }

  //TODO: NO SE UTILIZA
  Future<String> cambiarEstadoEmbarquePasajeroDomicilio(PasajeroDomicilio pasajero, String codOperacion, String usuario) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    mapFormData['usuario'] = usuario;
    String rpta = "";

    final url = _url + 'cambiar_estado_embarque_pasajero_domicilio';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
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
      rpta = "9";
    }

    return rpta;
  }

  ///
  //si-gps
  Future<String> registrarDesembarquePasajeroDomicilio(PasajeroDomicilio pasajero, String codOperacion, String usuario) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['fechaHoraDesembarque'] = pasajero.fechaDesembarque;
    mapFormData['usuario'] = usuario;
    mapFormData['idPuntoDesembarque'] = pasajero.idDesembarqueReal;
    mapFormData['coordenadas'] = pasajero.coordenadasParadero;
    String rpta = "";

    print(pasajero.coordenadasParadero);

    final url = _url + 'registrar_desembarque_pasajero_domicilio_v2';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
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
      rpta = "9";
    }

    return rpta;
  }
  //si-gps
  Future<String> cambiarEstadoEmbarquePasajeroDomicilio_v2(PasajeroDomicilio pasajero, String codOperacion, String usuario) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    mapFormData['usuario'] = usuario;
    mapFormData['idPuntoEmbarque'] = pasajero.idEmbarqueReal;
    mapFormData['coordenadas'] = pasajero.coordenadasParadero;

    print(pasajero.coordenadasParadero);

    String rpta = "";

    final url = _url + 'cambiar_estado_embarque_pasajero_domicilio_v3';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
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
      rpta = "9";
    }

    return rpta;
  }
  //si-gps
  Future<String> registrarFechaLlegadaUnidadDomicilio(PasajeroDomicilio pasajero, String codOperacion, String usuario) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['fechaHoraArribo'] = pasajero.fechaArriboUnidad;
    mapFormData['coordenadas'] = pasajero.coordenadas;
    mapFormData['usuario'] = usuario;
    String rpta = "";

    print(pasajero.coordenadasParadero);

    final url = _url + 'registrar_fechaLlegada_unidad_domicilio_v2';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "3";
        throw TimeoutException('3');
      }
    } catch (e) {
      rpta = "9";
    }

    return rpta;
  }

  Future<List<Pasajero>> obtener_manifiesto_viaje_x_puntoEmbarque(String nroViaje, String codOperacion, String puntoEmbarque) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['nroViaje'] = nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['puntoEmbarque'] = puntoEmbarque;

    List<Pasajero> listaPasajeros = [];

    final url = _url + 'obtenerManifiestoXpuntoEmbarque';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      ;

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final pasajeros = Pasajeros.fromJsonList(decodedData);
          listaPasajeros.addAll(pasajeros.pasajeros);
        }
      } else {
        throw TimeoutException('');
      }
    } catch (e) {
      listaPasajeros = [];
    }

    return listaPasajeros;
  }
  //si-gps
  Future<String> cambiarEstadoEmbarquePasajeroDomicilio_Reparto(PasajeroDomicilio pasajero, String codOperacion, String usuario) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = pasajero.tipoDoc;
    mapFormData['numDoc'] = pasajero.numDoc;
    mapFormData['nroViaje'] = pasajero.nroViaje;
    mapFormData['codOperacion'] = codOperacion;
    mapFormData['estadoEmbarque'] = pasajero.embarcado.toString();
    mapFormData['fechaHoraEmbarque'] = pasajero.fechaEmbarque;
    mapFormData['usuario'] = usuario;
    mapFormData['idPuntoEmbarque'] = pasajero.idEmbarqueReal;
    mapFormData['coordenadas'] = pasajero.coordenadas;
    mapFormData['nuevo'] = pasajero.nuevo;
    mapFormData['nombres'] = pasajero.nombres;

    print(pasajero.coordenadasParadero);

    String rpta = "";

    final url = _url + 'cambiar_estado_embarque_pasajero_domicilio_reparto';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "-2";
      }
    } catch (e) {
      rpta = "-9";
    }

    return rpta;
  }
}
