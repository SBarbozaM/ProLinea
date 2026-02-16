import 'dart:convert';
import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:embarques_tdp/src/models/Incidentes/incidente_model.dart';
import 'package:http/http.dart' as http;

class IncidentesService {
  String _url = Conexion.apiUrl;

  Future<List<Incidente>> getListaIncidentesNoti(String tipoDoc, String numDoc, int numDias) async {
    final finalurl = _url + 'GetListaIncidentesNoti';

    try {
      final response = await http.post(
        Uri.parse(finalurl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'Usu_tipoDoc': tipoDoc,
          'Usu_numDoc': numDoc,
          'numDias': numDias.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['rpta'] == "0") {
          // Mapeamos la lista de notificaciones a una lista de Incidente
          final List<dynamic> notiIncidentes = responseData['noti_Incidentes'];
          return notiIncidentes.map((noti) => Incidente.fromJson(noti)).toList();
        } else {
          throw Exception('Error en la respuesta: ${responseData['mensaje']}');
        }
      } else {
        throw Exception('Error en la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> isValidUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Si el código de estado es exitoso, consideramos que la URL es válida
        return true;
      } else {
        // Si la respuesta no es exitosa, la URL no es válida
        return false;
      }
    } catch (e) {
      // Si ocurre un error (como una excepción de conexión), la URL no es válida
      return false;
    }
  }
}
