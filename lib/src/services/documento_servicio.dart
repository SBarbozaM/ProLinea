import 'dart:async';
import 'dart:convert';
import 'package:embarques_tdp/src/models/documento_vehiculo.dart';
import 'package:embarques_tdp/src/models/respuesta_mensaje.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/vinculacion.dart';
import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/documento.dart';

class DocumentoServicio {
  String _url = Conexion.apiUrl;
  List<Documento> _documentos = [];

  final __documentosStreamController =
      StreamController<List<Documento>>.broadcast();

  Function(List<Documento>) get documentosSink =>
      __documentosStreamController.sink.add;

  Stream<List<Documento>> get documentosStream =>
      __documentosStreamController.stream;

  void disposeStream() {
    __documentosStreamController.close();
  }

  Future<Vinculacion> emparejarConductorViaje(
      Usuario usuario, String textoQr) async {
    Vinculacion respuesta = new Vinculacion();

    final url = _url + 'qr_emparejar_conductor_viaje';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = usuario.tipoDoc;
    mapFormData['numDoc'] = usuario.numDoc;
    mapFormData['textoQr'] = textoQr;
    mapFormData['codOperacion'] = usuario.codOperacion;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "{}") {
          respuesta.rpta = decodedData['rpta'];
          respuesta.mensaje = decodedData['mensaje'];

          if (respuesta.rpta == "0") {
            respuesta.nroViaje = decodedData['nroViaje'];
            respuesta.codUnidad = decodedData['codUnidad'];
            respuesta.placa = decodedData['placa'];
            respuesta.fecha = decodedData['fecha'];
          }

          if (respuesta.rpta == "2") {
            if (decodedData['documentos'] != null &&
                decodedData['documentos'] != "[]") {
              //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
              var documentosAux = decodedData['documentos'] as List;
              List<Documento> _documentos =
                  documentosAux.map((e) => Documento.fromJsonMap(e)).toList();
              respuesta.documentos = _documentos;
            }
          }
        }
      } else {}
    } catch (e) {
      respuesta.rpta = "1";
      respuesta.mensaje = "¡Ha ocurrido un error!";
    }

    return respuesta;
  }

  Future<Vinculacion> emparejarConductorViajeSupervisor(
    String tipoDoc,
    String numDoc,
    String textoQr,
    String codOperacion,
  ) async {
    Vinculacion respuesta = new Vinculacion();

    final url = _url + 'qr_emparejar_conductor_viaje';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = tipoDoc;
    mapFormData['numDoc'] = numDoc;
    mapFormData['textoQr'] = textoQr;
    mapFormData['codOperacion'] = codOperacion;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "{}") {
          respuesta.rpta = decodedData['rpta'];
          respuesta.mensaje = decodedData['mensaje'];

          if (respuesta.rpta == "0") {
            respuesta.nroViaje = decodedData['nroViaje'];
            respuesta.codUnidad = decodedData['codUnidad'];
            respuesta.placa = decodedData['placa'];
            respuesta.fecha = decodedData['fecha'];
          }

          if (respuesta.rpta == "2") {
            if (decodedData['documentos'] != null &&
                decodedData['documentos'] != "[]") {
              //final pasajeros = new Pasajeros.fromJsonList(json['pasajeros']);
              var documentosAux = decodedData['documentos'] as List;
              List<Documento> _documentos =
                  documentosAux.map((e) => Documento.fromJsonMap(e)).toList();
              respuesta.documentos = _documentos;
            }
          }
        }
      } else {}
    } catch (e) {
      respuesta.rpta = "1";
      respuesta.mensaje = "¡Ha ocurrido un error!";
    }

    return respuesta;
  }

  Future<RespuestaMensaje> desvincularConductorViaje(Usuario usuario) async {
    RespuestaMensaje respuesta = new RespuestaMensaje();

    final url = _url + 'qr_desvincular_conductor_viaje';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['nroViaje'] = usuario.viajeEmp;
    mapFormData['codOperacion'] = usuario.codOperacion;
    mapFormData['tipoDoc'] = usuario.tipoDoc;
    mapFormData['numDoc'] = usuario.numDoc;
    mapFormData['codUnidad'] = usuario.unidadEmp;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);
      print(resp);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "{}") {
          respuesta.rpta = decodedData['rpta'];
          respuesta.mensaje = decodedData['mensaje'];
        }
      } else {}
    } catch (e) {
      respuesta.rpta = "1";
      respuesta.mensaje = "¡Ha ocurrido un error!";
    }

    return respuesta;
  }

  Future<List<DocumentoVehiculo>> obtenerDocumentoVehiculo(
      String idVehiculo) async {
    final url = _url + 'obtener_documentos_vehiculos/$idVehiculo';

    List<DocumentoVehiculo> listDocumentos = [];
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body) as List;

        listDocumentos =
            decodedData.map((e) => DocumentoVehiculo.fromJson(e)).toList();

        return listDocumentos;
      }
      return listDocumentos;
    } catch (e) {
      return [];
    }
  }
}
