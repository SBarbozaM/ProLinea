import 'dart:async';
import 'dart:convert';
import 'package:embarques_tdp/src/models/programacion/programacion_model.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class ProgramacionServicio {
  String _url = Conexion.apiUrl;

  Future<ProgramacionModel> listarProgramacion(String tipoDoc, String numDoc) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['Tdoc'] = tipoDoc;
    mapFormData['Ndoc'] = numDoc;

    // String rpta = "";

    ProgramacionModel datosApp = ProgramacionModel(
      rpta: "500",
      mensaje: "ERROR EN LA CONSULTA",
      programacion: [],
    );

    final url = _url + 'Listar_Programacion_Conductor';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);

      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData.toString() != "{}") {
        datosApp = ProgramacionModel.fromJson(decodedData);
      }
    } catch (e) {
      datosApp = ProgramacionModel(rpta: "500", mensaje: "ERROR EN LA CONSULTA2", programacion: []);
    }

    return datosApp;
  }
}
