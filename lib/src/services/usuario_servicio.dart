import 'dart:convert';

import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:http/http.dart' as http;
import 'dart:async';


import 'package:embarques_tdp/src/models/usuario.dart';

import '../connection/conexion.dart';

class UsuarioServicio {
  final String _url = Conexion.apiUrl;

  final _usuarioStreamController = StreamController<Usuario>.broadcast();

  Function(Usuario) get usuarioSink => _usuarioStreamController.sink.add;

  Stream<Usuario> get usuarioStream => _usuarioStreamController.stream;

  void disposeStreams() {
    //CERRANDO LAS INSTANCIAS DEL SINK QUE ES LA INFO DE ENTRADA DEL STREAM
    _usuarioStreamController.close();
  }

  Future<Usuario> _procesarRespuestaPostFormData(Uri url, String mapFormData) async {
    Usuario usuario = new Usuario(
      tipoDoc: "",
      numDoc: "",
      rpta: "-1",
      clave: "",
      usuarioId: "0",
      apellidoPat: "",
      apellidoMat: "",
      nombres: "",
      perfil: "",
      codOperacion: "",
      nombreOperacion: "",
      equipo: "",
    );
    String result = "";

    try {
      final resp = await http.post(url, headers: {"Content-Type": "application/json"}, body: mapFormData);

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          result = decodedData['rpta'];
          final usuarioLog = new Usuario.fromJsonMap(decodedData);
          usuario = usuarioLog;
        }
      }
    } catch (e) {
      usuario.rpta = "9";
    }

    return usuario;
  }

  Future<Usuario> iniciarSesion(String tipoDoc, String numDoc, String contrasenia, String appVersion, String idDispositivo, String fechaCompilacion) async {
    Map obj = {"Usu_tipoDoc": tipoDoc, "Usu_numDoc": numDoc, "Usu_password": contrasenia, "AppVersion": appVersion, "idDispositivo": idDispositivo, "fechaCompilacion": fechaCompilacion};

    String str = json.encode(obj);

    final url = '${_url}loginGETP_v13';

    final resp = await _procesarRespuestaPostFormData(Uri.parse(url), str);


    return resp;
  }

  Future<Map<String, dynamic>> insertNoriUser(String tipoDoc, String numDoc, String tipoNoti, String plataforma, String imei, String oSuserId, String dataAux) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['Usu_tipoDoc'] = tipoDoc;
    mapFormData['Usu_numDoc'] = numDoc;
    mapFormData['Usu_tipoNoti'] = tipoNoti;
    mapFormData['Usu_plataforma'] = plataforma; //Err 309138
    mapFormData['Usu_imei'] = imei;
    mapFormData['Usu_oSuserID'] = oSuserId;
    mapFormData['Usu_dataAux'] = dataAux;

    final url = Uri.parse(_url + 'InsertNotiUsuario');

    try {
      final response = await http.post(
        url,
        body: mapFormData,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        return {};
      }
    } catch (e) {
      print('Exception: $e');
      return {};
    }
  }

  Future<DatosVinculacion> obtenerDatosVinculacion(String tipoDoc, String numDoc, String codOperacion) async {
    Map obj = {"tipoDoc": tipoDoc, "numDoc": numDoc, "codOperacion": codOperacion};

    String str = json.encode(obj);
    final url = _url + "obtenerDatosVinculacion";
    DatosVinculacion respUsuario = DatosVinculacion(
      rpta: "",
      viajeEmp: "",
      unidadEmp: "",
      placaEmp: "",
      fechaEmp: "",
    );
    String result = "";

    try {
      final resp = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: str);

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          result = decodedData['rpta'];
          if (result == "0") {
            respUsuario = new DatosVinculacion.fromJson(decodedData);
          } else {
            respUsuario.rpta = result;
          }
        }
      }
    } catch (e) {
      respUsuario.rpta = "9";
    }

    return respUsuario;
  }

  Future<String> cerrarSesion(String tipoDoc, String numDoc, String appVersion, String fechaCierreSesion) async {
    Map obj = {"Usu_tipoDoc": tipoDoc, "Usu_numDoc": numDoc, "AppVersion": appVersion, "FechaCierreSesion": fechaCierreSesion};

    String str = json.encode(obj);

    final url = _url + 'cerrarSesion';

    String rpta = "";

    try {
      final resp = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: str);

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "1";
      }
    } catch (e) {
      rpta = "9";
    }
    return rpta;
  }

  //TODO: GUARDAR ARCHIVO LOG
  Future<String> GuardarArchivoLog(String tipoDoc, String nroDoc, String idDispositivo, String archivo) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = tipoDoc;
    mapFormData['nroDoc'] = nroDoc;
    mapFormData['idDispositivo'] = idDispositivo;
    mapFormData['archivo'] = archivo;

    final url = _url + 'GuardarArchivoLog';

    String rpta = "";

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData);

      if (resp.statusCode == 200) {
        rpta = resp.body;
      } else {
        rpta = "1";
      }
    } catch (e) {
      rpta = "9";
    }
    return rpta;
  }
}
