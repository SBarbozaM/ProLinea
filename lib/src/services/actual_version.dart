import 'dart:convert';
import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:embarques_tdp/src/models/actual_version.dart';

class VersionService {
  final String baseurl = Conexion.apiUrl;

  Future<ActualVersion?> fetchUltimaVersion() async {
    try {
      final response = await http.get(Uri.parse(baseurl + 'Traer_UltimaVersion'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return ActualVersion.fromJson(data);
      } else {
        throw Exception('Error al cargar la última versión');
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
