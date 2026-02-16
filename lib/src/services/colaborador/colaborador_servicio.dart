import 'dart:convert';

import 'package:embarques_tdp/src/models/colaborador/colaboradorAreas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorDatos.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorEmpresas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorTipoDoc.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:async';

import 'package:embarques_tdp/src/connection/conexion.dart';

class ColaboradorServicio {
  final String _url = Conexion.apiUrl;

  Future<List<ColaboradorTipoDoc>> ColaboradorListarTipoDoc() async {
    final url = _url + 'Lista_TipoDoc_Colaborador';

    List<ColaboradorTipoDoc> listaTipoDoc = [];

    try {
      final resp = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body) as List;
        listaTipoDoc = decodedData.map((e) => ColaboradorTipoDoc.fromJson(e)).toList();
      } else {
        listaTipoDoc = [];
      }
    } catch (e) {
      print(e);
      listaTipoDoc = [];
    }
    return listaTipoDoc;
  }

  Future<List<ColaboradorEmpresas>> ColaboradorListarEmpresas({
    required String usuario,
    required String codOperacion,
  }) async {
    final url = _url + 'Colaborador_ListarEmpresas/${usuario}/${codOperacion}';

    List<ColaboradorEmpresas> listaEmpresas = [];

    try {
      final resp = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body) as List;
        listaEmpresas = decodedData.map((e) => ColaboradorEmpresas.fromJson(e)).toList();
      } else {
        listaEmpresas = [];
      }
    } catch (e) {
      print(e);
      listaEmpresas = [];
    }
    return listaEmpresas;
  }

  Future<List<ColaboradorAreas>> ColaboradorListarAreas({
    required String usuario,
    required String codOperacion,
    required int idEmpresa,
  }) async {
    final url = _url + 'Colaborador_ListarAreas/${usuario}/${codOperacion}/${idEmpresa}';

    List<ColaboradorAreas> listaAreas = [];

    try {
      final resp = await http.get(Uri.parse(url)).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );
      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body) as List;
        listaAreas = decodedData.map((e) => ColaboradorAreas.fromJson(e)).toList();
      } else {
        listaAreas = [];
      }
    } catch (e) {
      print(e);
      listaAreas = [];
    }
    return listaAreas;
  }

  Future<ColaboradorDatos> colaboradorDatos({
    required String codOperacion,
    required String usuario,
    required String tdoc,
    required String ndoc,
  }) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['CodOperacion'] = codOperacion;
    mapFormData['usuario'] = usuario;
    mapFormData['tdoc'] = tdoc;
    mapFormData['ndoc'] = ndoc;

    ColaboradorDatos colaborador = ColaboradorDatos(
      paterno: "",
      materno: "",
      nombres: "",
      idEmpresa: "",
      empresa: "",
      idArea: "",
      area: "",
      codigoExterno: "",
      activo: "",
    );

    final url = _url + 'Colaborador_Datos';
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = await json.decode(resp.body);
        colaborador = ColaboradorDatos.fromJson(decodedData);
      }
    } catch (e) {}
    return colaborador;
  }

  Future<String> colaborador_RegistrarModificar({
    required String codOperacion,
    required String usuario,
    required String tdoc,
    required String ndoc,
    required String paterno,
    required String materno,
    required String nombres,
    required String idEmpresa,
    required String idArea,
    required String activo,
    required String codigoExterno,
  }) async {
    var mapFormData = new Map<String, dynamic>();
    mapFormData['CodOperacion'] = codOperacion;
    mapFormData['usuario'] = usuario;
    mapFormData['TipoDoc'] = tdoc;
    mapFormData['NroDoc'] = ndoc;
    mapFormData['Ap_Paterno'] = paterno;
    mapFormData['Ap_Materno'] = materno;
    mapFormData['Nombres'] = nombres;
    mapFormData['Id_Empresa'] = idEmpresa;
    mapFormData['Id_Area'] = idArea;
    mapFormData['Activo'] = activo;
    mapFormData['CodigoExterno'] = codigoExterno;

    String rpta = "";

    final url = _url + 'Colaborador_RegistrarModificar';
    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        rpta = resp.body;
      }
    } catch (e) {}
    return rpta;
  }
}
