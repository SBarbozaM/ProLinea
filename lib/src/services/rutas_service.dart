import 'dart:async';
import 'dart:convert';
import 'package:embarques_tdp/src/models/rutas/ruta_listar.dart';
import 'package:http/http.dart' as http;
import '../connection/conexion.dart';

class RutaListarServicio {
  String _url = Conexion.apiUrl;
  List<RutaListar> _rutas = [];

  final _rutasStreamController = StreamController<List<RutaListar>>.broadcast();

  Function(List<RutaListar>) get rutasSink => _rutasStreamController.sink.add;

  Stream<List<RutaListar>> get rutasStream => _rutasStreamController.stream;

  void disposeStream() {
    _rutasStreamController.close();
  }

  Future<RutaListarResponse> listarRutas(String tdoc, String ndoc, String codOperacion) async {
    final url = Uri.parse(_url + 'listar_rutas');

    try {
      final response = await http.post(
        url,
        body: {
          'Tdoc': tdoc,
          'Ndoc': ndoc,
          'CodOperacion': codOperacion,
        },
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        return RutaListarResponse.fromJson(decodedData);
      } else {
        return RutaListarResponse(
          rpta: '1',
          mensaje: 'Error en la solicitud: ${response.statusCode}',
          rutas: [],
          codigoEstado: response.statusCode,
        );
      }
    } catch (e) {
      return RutaListarResponse(
        rpta: '1',
        mensaje: 'Excepción: $e',
        rutas: [],
        codigoEstado: 500,
      );
    }
  }

  Future<void> cargarRutas(String tdoc, String ndoc, String codOperacion) async {
    final response = await listarRutas(tdoc, ndoc, codOperacion);

    if (response.rpta == '0') {
      _rutas = response.rutas;
      rutasSink(_rutas);
    } else {
      print('Error al cargar rutas: ${response.mensaje}');
    }
  }
}
