import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';

class RutaServicio {
  String _url = Conexion.apiUrl;
  List<Ruta> _rutas = [];

  final __rutasStreamController = StreamController<List<Ruta>>.broadcast();

  Function(List<Ruta>) get rutasSink => __rutasStreamController.sink.add;

  Stream<List<Ruta>> get rutasStream => __rutasStreamController.stream;

  void disposeStream() {
    __rutasStreamController.close();
  }

  Future<List<Ruta>> _procesarRespuestaGetFormData(Uri url) async {
    List<Ruta> listaRutas = [];

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final rutas = Rutas.fromJsonList(decodedData);
          listaRutas.addAll(rutas.rutas);
        }
      } else {}
    } catch (e) {}

    return listaRutas;
  }

  Future<List<Ruta>> obtenerRutas(String codOperacion) async {
    final url = _url + 'obtenerRutasReserva/' + codOperacion;

    final resp = await _procesarRespuestaGetFormData(Uri.parse(url));

    _rutas.addAll(resp);
    return resp;
  }
}
