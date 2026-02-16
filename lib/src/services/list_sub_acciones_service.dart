import 'dart:convert';
import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/subAuth_model.dart';

import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class SubAutorizacionesServicio {
  String _url = Conexion.apiUrl;

  Future<SubAuthUsuarioModel> listarsubAuthsUsuario(String tipoDoc, String numDoc, String idAut) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['Usu_tipoDoc'] = tipoDoc;
    mapFormData['Usu_numDoc'] = numDoc;
    mapFormData['Id_auth'] = idAut.toString();

    // String rpta = "";

    SubAuthUsuarioModel datosApp = SubAuthUsuarioModel(
      rpta: "500",
      mensaje: "ERROR EN LA CONSULTA",
      tipoDoc: "",
      numDoc: "",
      idAuth: 0,
      authSubAcciones: [],
    );

    final url = _url + 'GetLisSubAuths';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);

      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData.toString() != "{}") {
        datosApp = SubAuthUsuarioModel.fromJson(decodedData);
      }
    } catch (e) {
      datosApp = SubAuthUsuarioModel(rpta: "500", mensaje: "ERROR EN LA CONSULTA2", tipoDoc: "", numDoc: "", idAuth: 0, authSubAcciones: []);
    }

    return datosApp;
  }
}
