import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:embarques_tdp/src/models/tipo_documento.dart';

import '../connection/conexion.dart';

class TipoDocumentoServicio {
  String _url = Conexion.apiUrl;
  List<TipoDocumento> _tiposDocumento = [];

  final _tiposDocumentoStreamController =
      StreamController<List<TipoDocumento>>.broadcast();

  Function(List<TipoDocumento>) get tiposDocumentoSink =>
      _tiposDocumentoStreamController.sink.add;

  Stream<List<TipoDocumento>> get tiposDocumentoStream =>
      _tiposDocumentoStreamController.stream;

  void disposeStream() {
    _tiposDocumentoStreamController.close();
  }

  Future<List<TipoDocumento>> _procesarRespuestaGetFormData(Uri url) async {
    List<TipoDocumento> listaTiposDocumentos = [];

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final tiposDocumentos = TiposDocumento.fromJsonList(decodedData);
          listaTiposDocumentos.addAll(tiposDocumentos.tiposDocumento);
        }
      } else {}
    } catch (e) {}

    return listaTiposDocumentos;
  }

  Future<List<TipoDocumento>> obtenerTiposDocumento() async {
    final url = _url + 'tiposDocumentoGETP';

    final resp = await _procesarRespuestaGetFormData(Uri.parse(url));

    _tiposDocumento.addAll(resp);
    return resp;
  }
}
