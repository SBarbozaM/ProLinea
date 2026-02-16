import 'dart:async';
import 'dart:convert';
import 'package:embarques_tdp/src/models/datos_app.dart';
import 'package:http/http.dart' as http;
import '../connection/conexion.dart';

class DatosAppServicio {
  String _url = Conexion.apiUrl;
  DatosApp _datosApp = new DatosApp();

  final _datosAppStreamController = StreamController<DatosApp>.broadcast();

  Function(DatosApp) get datosAppSink => _datosAppStreamController.sink.add;

  Stream<DatosApp> get datosAppStream => _datosAppStreamController.stream;

  void disposeStream() {
    _datosAppStreamController.close();
  }

  Future<DatosApp> _procesarRespuestaGetFormData(Uri url) async {
    DatosApp datosApp = new DatosApp();

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "{}") {
          datosApp = DatosApp.fromJsonMap(decodedData);
        }
      } else {}
    } catch (e) {
      datosApp.rpta = '9';
    }

    return datosApp;
  }

  Future<DatosApp> obtenerDatosApp({
    required String tipoDoc,
    required String numDoc,
  }) async {
    final url = _url + 'obtener_datos_app_v2/${tipoDoc}/${numDoc}';

    final resp = await _procesarRespuestaGetFormData(Uri.parse(url));

    return resp;
  }
}
