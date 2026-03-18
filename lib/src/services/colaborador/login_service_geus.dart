import 'dart:convert';

import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:embarques_tdp/src/models/Login/colaboradorTipoDoc.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorTipoDoc.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/app_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginService {
  final String _url = Conexion.apiUrlLogin;

  Future<String> obtenerToken() async {
    final uri = Uri.parse(
      '${AppData.apiSeguridad}/authorization/create-auth-application-token-v2',
    ).replace(queryParameters: {
      'ClaveAccesoCliente': AppData.clientKey,
      'IdAppRecurso': AppData.idRecurso,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['jwt'] as String;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error obteniendo el token de seguridad: $e');
      rethrow;
    }
  }

  Future<List<ColaboradorTipoDocv2>> ObtenerTiposDocumentos() async {
    try {
      // String tokenSeguridad = await obtenerToken();

      final uri = Uri.parse('$_url/ObtenerTiposDocumentos');

      final response = await http.get(uri
          // headers: {
          //   'Authorization': 'Bearer $tokenSeguridad',
          //   'Content-Type': 'application/json',
          // },
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => ColaboradorTipoDocv2.fromJson(e)).toList();
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<void> cargarAccionesMenu(int idUsuario, UsuarioProvider usuarioProvider) async {
    print('cargarAccionesMenu idUsuario: $idUsuario');
    try {
      final idPlataforma = AppData.idPlataforma;
      final response = await http.post(
        Uri.parse('$_url/OpcionesMenu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"idPlataforma": int.parse(idPlataforma), "idUsuario": idUsuario, "idEmpresa": 1}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status']['isError'] == false) {
          final accionesId = _extraerAcciones(data);
          final acciones = accionesId.map((a) => a.url).toList();
          usuarioProvider.asignarAcciones(accionesId, acciones);
        }
      }
    } catch (e) {
      debugPrint('Error al cargar menú: $e');
    }
  }

  List<AccionId> _extraerAcciones(Map<String, dynamic> menuData) {
    List<AccionId> accionesId = [];

    final sidebar = menuData['data']['sidebar'] as List<dynamic>? ?? [];

    for (var modulo in sidebar) {
      final acciones = modulo['acciones'] as List<dynamic>? ?? [];

      for (var accion in acciones) {
        accionesId.add(AccionId(
          accion: accion['nombre'] ?? '',
          accionPredecesora: int.tryParse(accion['idPredecesor']?.toString() ?? '0') ?? 0,
          icono: accion['icono'] ?? '',
          orden: accion['orden'] ?? '0',
          pendientes: accion['pendientes'] ?? 0,
          url: accion['url'] ?? '',
          id: int.tryParse(accion['idOpcion']?.toString() ?? '0') ?? 0,
        ));
      }
    }

    return accionesId;
  }
}
