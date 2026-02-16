import 'dart:convert';
import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/doc_Auth_model.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/subAuth_model.dart';

import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class ListDocsAuthServicio {
  String _url = Conexion.apiUrl;

  Future<DocAuthModel> listarDocsAuthsUsuario(String tipoDoc, String numDoc, String idSubAut) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['Usu_tipoDoc'] = tipoDoc;
    mapFormData['Usu_numDoc'] = numDoc;
    mapFormData['Id_subauth'] = idSubAut.toString();

    // String rpta = "";

    DocAuthModel datosApp = DocAuthModel(
      count: 0,
      rpta: "500",
      mensaje: "ERROR EN LA CONSULTA",
      tipoDoc: "",
      numDoc: "",
      idSubAuth: 0,
      authDocs: [],
    );

    final url = _url + 'GetLisSubAuthDocs';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);

      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData.toString() != "{}") {
        datosApp = DocAuthModel.fromJson(decodedData);
      }
    } catch (e) {
      datosApp = DocAuthModel(
        count: 0,
        rpta: "500",
        mensaje: "ERROR EN LA CONSULTA",
        tipoDoc: "",
        numDoc: "",
        idSubAuth: 0,
        authDocs: [],
      );
    }

    return datosApp;
  }
}
