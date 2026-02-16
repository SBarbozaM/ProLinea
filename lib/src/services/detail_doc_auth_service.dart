import 'dart:convert';
import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/detail_doc_model.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/subAuth_model.dart';

import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class DetailDocsAuthServicio {
  String _url = Conexion.apiUrl;

  Future<DetailDocModel> detailDocument(String tipoDoc, String numDoc, String pk_Orden, String tdoc_Orden) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['Usu_tipoDoc'] = tipoDoc;
    mapFormData['Usu_numDoc'] = numDoc;
    mapFormData['pk_Orden'] = pk_Orden;
    mapFormData['tdoc_Orden'] = tdoc_Orden;

    // String rpta = "";

    DetailDocModel datosApp = DetailDocModel(
      rpta: "500",
      mensaje: "ERROR EN LA CONSULTA",
      tipoDoc: "",
      numDoc: "",
      pkOrden: "",
      tipoDocOrden: "",
      authDetail: [],
    );

    final url = _url + 'GetDetailAuthDocs';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);

      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData.toString() != "{}") {
        datosApp = DetailDocModel.fromJson(decodedData);
      }
    } catch (e) {
      datosApp = DetailDocModel(
        rpta: "500",
        mensaje: "ERROR EN LA CONSULTA",
        tipoDoc: "",
        numDoc: "",
        pkOrden: "",
        tipoDocOrden: "",
        authDetail: [],
      );
    }

    return datosApp;
  }
}
