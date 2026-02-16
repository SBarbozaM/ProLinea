import 'dart:convert';

import 'package:embarques_tdp/src/models/control_asistencia.dart';
import 'package:embarques_tdp/src/models/control_salida.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:async';

import 'package:embarques_tdp/src/models/control_ingreso.dart';
import 'package:embarques_tdp/src/connection/conexion.dart';

class ControladorServicio {
  final String _url = Conexion.apiUrl;
  //si-gps-control-salida
  Future<ControlSalida> QRControlSalidas({
    required String idAndroid,
    required String conductorQR,
    required String unidadQR,
    required String fecha,
    required String codOperacion,
    required String tipoDoc,
    required String usuario,
    required String latitud,
    required String longitud,
  }) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['IdAndroid'] = idAndroid;
    mapFormData['NumDocQR'] = conductorQR;
    mapFormData['UnidadQR'] = unidadQR;
    mapFormData['Fecha'] = fecha;
    mapFormData['CodOperacion'] = codOperacion;
    mapFormData['TipoDoc'] = tipoDoc;
    mapFormData['Usuario'] = usuario;
    mapFormData['Latitud'] = latitud;
    mapFormData['Longitud'] = longitud;

    ControlSalida controlSalida = ControlSalida();

    final url = _url + 'QR_Control_Salidas_conductor_viaje_3';
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body);
        controlSalida = ControlSalida.fromJsonMap(decodedData);
      } else {
        controlSalida.mensaje = "Error el procesar la consulta";
        controlSalida.rpta = "400";
      }
    } catch (e) {
      print(e);
      controlSalida.mensaje = "Error el procesar la consulta";
      controlSalida.rpta = "500";
    }
    return controlSalida;
  }

  Future<String> QRConfirmarControlSalidas({
    required String idAndroid,
    required String idControl,
    required String Observacion,
    required String salidaHabilitada,
  }) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['IdAndroid'] = idAndroid;
    mapFormData['idControl'] = idControl;
    mapFormData['Observacion'] = Observacion;
    mapFormData['salidaHabilitada'] = salidaHabilitada;

    String rpta = "400";

    final url = _url + 'QR_Confirmar_Control_Salida_3';
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 45), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        rpta = resp.body.toString();
      } else {
        rpta = "400";
      }
    } catch (e) {
      print(e);
      rpta = "500";
    }
    return rpta;
  }

  Future<List<ControlSalidaUsuario>> ListarControlSalidasUsuario({
    required String idAndroid,
    required String DocUsuario,
  }) async {
    final url = _url + 'QR_Control_Salidas_Listar_Usuario_3/${idAndroid}/${DocUsuario}';

    List<ControlSalidaUsuario> listaControlSalida = [];

    try {
      final resp = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body) as List;
        listaControlSalida = decodedData.map((e) => ControlSalidaUsuario.fromJson(e)).toList();
      } else {
        listaControlSalida = [];
      }
    } catch (e) {
      print(e);
      listaControlSalida = [];
    }
    return listaControlSalida;
  }

  //CONTROL ASISTENCIA
  Future<ControlAsistencia> QRControlAsistencia({
    required String idEquipo,
    required String fotocheck,
    required String tipoDoc,
    required String nroDoc,
  }) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['ASIEQ_IDEquipo'] = idEquipo;
    mapFormData['ASI_Fotocheck'] = fotocheck;
    mapFormData['ASI_TDoc_Usuario'] = tipoDoc;
    mapFormData['ASI_NDoc_Usuario'] = nroDoc;

    ControlAsistencia controlAsistencia = ControlAsistencia(hora: "", mensaje: "", rpta: "");

    final url = _url + 'CTRL_Asistencia';
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 40), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera.');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body);
        controlAsistencia = ControlAsistencia.fromJson(decodedData);
      } else {
        controlAsistencia.mensaje = "Error el procesar la consulta";
        controlAsistencia.rpta = "400";
      }
    } catch (e) {
      print(e);
      controlAsistencia.mensaje = "Error el procesar la consulta";
      controlAsistencia.rpta = "500";
    }
    return controlAsistencia;
  }

//----CONTROL INGRESO
  Future<List<ControlIngresoUsuario>> ListarControlIngresoUsuario({
    required String idAndroid,
    required String DocUsuario,
  }) async {
    final url = _url + 'QR_Control_Ingreso_Listar_Usuario_3/${idAndroid}/${DocUsuario}';

    List<ControlIngresoUsuario> listaControlSalida = [];

    try {
      final resp = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body) as List;
        listaControlSalida = decodedData.map((e) => ControlIngresoUsuario.fromJson(e)).toList();
      } else {
        listaControlSalida = [];
      }
    } catch (e) {
      print(e);
      listaControlSalida = [];
    }
    return listaControlSalida;
  }
  //si-gps-control-ingreso
  Future<ControlIngreso> QRControlIngreso({
    required String idAndroid,
    required String conductorQR,
    required String unidadQR,
    required String fecha,
    required String codOperacion,
    required String tipoDoc,
    required String usuario,
    required String latitud,
    required String longitud,
  }) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['IdAndroid'] = idAndroid;
    mapFormData['NumDocQR'] = conductorQR;
    mapFormData['UnidadQR'] = unidadQR;
    mapFormData['Fecha'] = fecha;
    mapFormData['CodOperacion'] = codOperacion;
    mapFormData['TipoDoc'] = tipoDoc;
    mapFormData['Usuario'] = usuario;
    mapFormData['Latitud'] = latitud;
    mapFormData['Longitud'] = longitud;

    ControlIngreso controlIngreso = ControlIngreso();

    final url = _url + 'QR_Control_Ingreso_conductor_viaje_3';
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body);
        controlIngreso = ControlIngreso.fromJsonMap(decodedData);
      } else {
        controlIngreso.mensaje = "Error el procesar la consulta";
        controlIngreso.rpta = "400";
      }
    } catch (e) {
      print(e);
      controlIngreso.mensaje = "Error el procesar la consulta";
      controlIngreso.rpta = "500";
    }
    return controlIngreso;
  }

  Future<String> QRConfirmarControlIngreso({
    required String idAndroid,
    required String idControl,
    required String Observacion,
    required String salidaHabilitada,
  }) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['IdAndroid'] = idAndroid;
    mapFormData['idControl'] = idControl;
    mapFormData['Observacion'] = Observacion;
    mapFormData['salidaHabilitada'] = salidaHabilitada;

    String rpta = "400";

    final url = _url + 'QR_Confirmar_Control_Ingreso_3';
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        rpta = resp.body.toString();
      } else {
        rpta = "400";
      }
    } catch (e) {
      print(e);
      rpta = "500";
    }
    return rpta;
  }
}
