import 'dart:convert';

import 'package:embarques_tdp/src/models/colaborador/colaboradorAreas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorDatos.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorEmpresas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorTipoDoc.dart';
import 'package:embarques_tdp/src/models/usuario-geop.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:async';

import 'package:embarques_tdp/src/connection/conexion.dart';

class UsuarioGeopServicio {
  final String _url = Conexion.apiUrl;

  Future<UsuarioGeop> GeopvalidarUnidad({
    required String idUsuario,
    required String tipoDoc,
    required String ndoc,
    required String paterno,
    required String materno,
    required String nombres,
    required String placa,
  }) async {
    Map obj = {
      "parametros_url": "${idUsuario}#${tipoDoc}#${ndoc}#${paterno}#${materno}#${nombres}",
      "placa": placa,
    };

    String body = json.encode(obj);

    UsuarioGeop usuario = new UsuarioGeop(encriptado: "", codUndiad: "");

    final url = _url + 'encriptar_url_app_geop';
    try {
      final resp = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: body).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body) as List;
        if (decodedData.isNotEmpty) {
          if (decodedData[0]["codUndiad"] == "") {
            usuario = UsuarioGeop(rpta: "No se encontro el vehiculo", status: "400", encriptado: "", codUndiad: "");
          } else {
            usuario = UsuarioGeop(rpta: "Vehiculo Encontrado", status: "200", encriptado: decodedData[0]["encriptado"], codUndiad: decodedData[0]["codUndiad"]);
          }
        }
      }
    } catch (e) {
      usuario = UsuarioGeop(rpta: "${e.toString()}", status: "500", encriptado: "", codUndiad: "");
    }
    return usuario;
  }

  Future<UsuarioGeop> GeopvalidarUnidades({
    required String idUsuario,
    required String tipoDoc,
    required String ndoc,
    required String paterno,
    required String materno,
    required String nombres,
  }) async {
    Map obj = {
      "parametros_url": "${idUsuario}#${tipoDoc}#${ndoc}#${paterno}#${materno}#${nombres}",
      "placa": "",
    };

    String body = json.encode(obj);

    UsuarioGeop usuario = new UsuarioGeop(encriptado: "", codUndiad: "");

    final url = _url + 'encriptar_url_app_geop';
    try {
      final resp = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: body).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body) as List;
        if (decodedData.isNotEmpty) {
          usuario = UsuarioGeop(rpta: "Vehiculo Encontrado", status: "200", encriptado: decodedData[0]["encriptado"], codUndiad: "");
        }
      }
    } catch (e) {
      usuario = UsuarioGeop(rpta: "${e.toString()}", status: "500", encriptado: "", codUndiad: "");
    }
    return usuario;
  }
}
