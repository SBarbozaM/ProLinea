import 'dart:convert';
import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/auto_desauth_model.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/subAuth_model.dart';

import 'package:http/http.dart' as http;

import '../connection/conexion.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';

class AutorizaRechazaServicio {
  String _url = Conexion.apiUrl;

  Future<AutorizaRechazaModel> autorizaRechaza(String tipoDoc, String numDoc, String subAccion, String idDoc, String tipoDocAc, String estado, String documento, String motivo) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['Usu_tipoDoc'] = tipoDoc; 
    mapFormData['Usu_numDoc'] = numDoc;
    mapFormData['sub_accion'] = subAccion;
    mapFormData['id_doc'] = idDoc; //Err 309138
    mapFormData['tipo_doc'] = tipoDocAc;
    mapFormData['estado'] = estado;
    mapFormData['motivo'] = motivo;
    mapFormData['documento'] = documento;

    // String rpta = "";

    AutorizaRechazaModel datosApp = AutorizaRechazaModel(
      rpta: "",
      mensaje: "ERROR EN LA CONSULTA",
      tipoDoc: "",
      numDoc: "",
      subAccion: "",
      idDoc: "",
      tipoDocumento: "",
      estado: "",
      motivo: "",
      documento: "",
    );

    final url = _url + 'AutorizaRechaza';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);
      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData.toString() != "{}") {
        datosApp = AutorizaRechazaModel.fromJson(decodedData);
      }
    } catch (e) {
      datosApp = AutorizaRechazaModel(
        rpta: "",
        mensaje: "ERROR EN LA CONSULTA",
        tipoDoc: "",
        numDoc: "",
        subAccion: "",
        idDoc: "",
        tipoDocumento: "",
        estado: "",
        motivo: "",
        documento: "",
      );
    }

    return datosApp;
  }
}
