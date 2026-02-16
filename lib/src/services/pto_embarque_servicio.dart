import 'dart:async';
import 'dart:convert';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class PuntoEmbarqueServicio {
  String _url = Conexion.apiUrl;
  List<PuntoEmbarque> _puntosEmbarque = [];

  final __puntosEmbarqueStreamController =
      StreamController<List<Ruta>>.broadcast();

  Function(List<Ruta>) get puntosEmbarqueSink =>
      __puntosEmbarqueStreamController.sink.add;

  Stream<List<Ruta>> get puntosEmbarqueStream =>
      __puntosEmbarqueStreamController.stream;

  void disposeStream() {
    __puntosEmbarqueStreamController.close();
  }

  Future<List<PuntoEmbarque>> _procesarRespuestaGetFormData(Uri url) async {
    List<PuntoEmbarque> puntosEmbarque = [];

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final ptosEmbarque = PuntosEmbarque.fromJsonListNombre(decodedData);
          puntosEmbarque.addAll(ptosEmbarque.puntosEmbarque);
        }
      } else {}
    } catch (e) {}

    return puntosEmbarque;
  }

  Future<List<PuntoEmbarque>> obtenerPuntoEmbarque(String codOperacion) async {
    final url = _url + 'listarPuntosEmbarque/' + codOperacion;

    final resp = await _procesarRespuestaGetFormData(Uri.parse(url));

    _puntosEmbarque.addAll(resp);
    return resp;
  }

  Future<String> cambiarEstadoImpresoPuntoEmbarque(
      PuntoEmbarque puntoEmbarque, Usuario usuario, Viaje viaje) async {
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

    final url = _url + 'cambiar_estado_impreso_puntoEmbarque';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);
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
}
