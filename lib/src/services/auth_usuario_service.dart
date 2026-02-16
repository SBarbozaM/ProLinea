import 'dart:convert';
import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';

import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class AuthUsuarioServicio {
  String _url = Conexion.apiUrl;

  Future<AuthUsuario> listarAuthsUsuario(String tipoDoc, String numDoc) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['Usu_tipoDoc'] = tipoDoc;
    mapFormData['Usu_numDoc'] = numDoc;

    // String rpta = "";

    AuthUsuario datosApp = AuthUsuario(
      rpta: "500",
      mensaje: "ERROR EN LA CONSULTA",
      tipoDoc: "",
      numDoc: "",
      authAcciones: [],
    );

    final url = _url + 'GetListaAuths';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);

      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData.toString() != "{}") {
        datosApp = AuthUsuario.fromJson(decodedData);
      }
    } catch (e) {
      datosApp = AuthUsuario(rpta: "500", mensaje: "ERROR EN LA CONSULTA", tipoDoc: "", numDoc: "", authAcciones: []);
    }

    return datosApp;
  }
}
