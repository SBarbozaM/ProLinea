import 'dart:convert';
import 'dart:io';
import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:embarques_tdp/src/models/DocumentosLaborales/descuentos_model.dart';
import 'package:embarques_tdp/src/models/DocumentosLaborales/docsAcciones_model.dart';
import 'package:embarques_tdp/src/models/DocumentosLaborales/docsUsuario_model.dart';
import 'package:embarques_tdp/src/models/DocumentosLaborales/documentoTemporal_model.dart';
import 'package:embarques_tdp/src/models/DocumentosLaborales/documentos_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocsUsuarioServicio {
  /// 🔹 ESTE MÉTODO NO CAMBIA NUNCA
  Future<DocsUsuario> listarDocsLabsAccionesUsuario(
    String tipoDoc,
    String numDoc,
  ) async {
    try {
      final uri = Uri.parse(
        '${Conexion.apiUrlDocsLabs}/obtenerAccionesDocLabs?tipoDoc=$tipoDoc&nroDoc=$numDoc',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      late List<DocsAccion> acciones;

      // 🔥 CASO 1: backend devuelve LISTA DIRECTA
      if (decoded is List) {
        acciones = decoded.map<DocsAccion>((e) => DocsAccion.fromJson(e)).toList();

        return DocsUsuario(
          rpta: "0",
          mensaje: "OK",
          tipoDoc: tipoDoc,
          numDoc: numDoc,
          docsAcciones: acciones,
        );
      }

      // 🔥 CASO 2: backend devuelve OBJETO con data
      if (decoded is Map<String, dynamic>) {
        acciones = (decoded['data'] as List).map<DocsAccion>((e) => DocsAccion.fromJson(e)).toList();

        return DocsUsuario(
          rpta: decoded['rpta'] ?? "0",
          mensaje: decoded['mensaje'] ?? "OK",
          tipoDoc: tipoDoc,
          numDoc: numDoc,
          docsAcciones: acciones,
        );
      }

      throw Exception('Formato de respuesta no soportado');
    } catch (e, s) {
      return DocsUsuario(
        rpta: "500",
        mensaje: "ERROR EN LA CONSULTA",
        tipoDoc: "",
        numDoc: "",
        docsAcciones: [],
      );
    }
  }

  Future<List<DocLaboralDetalle>> listarDocsPorEstado({
    required int tipo,
    required String tipoDoc,
    required String nroDoc,
    required String estado,
  }) async {
    final uri = Uri.parse(
      '${Conexion.apiUrlDocsLabs}/ListarPorEstado'
      '?tipoDoc=$tipoDoc'
      '&nroDoc=$nroDoc'
      '&tipo=$tipo'
      '&estado=$estado',
    );

    final response = await http.get(uri);

    // ❌ Error HTTP
    if (response.statusCode != 200) {
      throw Exception(
        'Error ${response.statusCode}: ${response.body}',
      );
    }

    // ✅ Decodificar JSON
    final decoded = jsonDecode(response.body);

    // 🔴 Backend devuelve ARRAY directo
    if (decoded is List) {
      return decoded.map((e) => DocLaboralDetalle.fromJson(e)).toList();
    }

    // ⚠️ Defensa extra
    throw Exception('Formato de respuesta inesperado');
  }

  Future<File> descargarBoletaEnDescargas({required String codigo, required int tipo, required String tipoDoc, required String numDoc, required String tipoPlanilla, required String mesanio, required String desc}) async {
    final uri = Uri.parse(
      '${Conexion.apiUrlDocsLabs}/DescargarDocumento?codigo=${codigo.trim()}&tipo=$tipo&tipoDoc=$tipoDoc&numDoc=$numDoc&tipoPlanilla=$tipoPlanilla&mesanio=$mesanio&desc=$desc',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('No se pudo descargar el documento');
    }

    final downloadsDir = await getDownloadDirectoryAndroid();

    final nombreArchivo = obtenerNombreArchivo(response) ?? 'Documento_$codigo.pdf';

    final file = File('${downloadsDir.path}/$nombreArchivo');

    await file.writeAsBytes(response.bodyBytes, flush: true);

    return file;
  }

  static Future<DocumentoTemporal> obtenerDocumentoTemporal({
    required String codigo,
    required int tipo,
    required String tipoDoc,
    required String numDoc,
    required String tipoPlanilla,
    required String mesanio,
    required String desc,
  }) async {
    final uri = Uri.parse(
      '${Conexion.apiUrlDocsLabs}/DescargarDocumento'
      '?codigo=${codigo.trim()}'
      '&tipo=$tipo'
      '&tipoDoc=$tipoDoc'
      '&numDoc=$numDoc'
      '&tipoPlanilla=$tipoPlanilla'
      '&mesanio=$mesanio'
      '&desc=$desc',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener el documento');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/doc_$codigo.pdf');

    await file.writeAsBytes(response.bodyBytes, flush: true);

    return DocumentoTemporal(
      file: file,
      bytes: response.bodyBytes,
    );
  }

  Future<Directory> getDownloadDirectoryAndroid() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('No se pudo acceder al almacenamiento externo');
    }

    // Normalmente devuelve algo como:
    // /storage/emulated/0/Android/data/com.app/files
    // Subimos hasta /storage/emulated/0
    final rootPath = dir.path.split('/Android')[0];

    final downloadDir = Directory('$rootPath/Download');

    if (!downloadDir.existsSync()) {
      throw Exception('No se encontró la carpeta Descargas');
    }

    return downloadDir;
  }

  String? obtenerNombreArchivo(http.Response response) {
    final contentDisposition = response.headers['content-disposition'];
    if (contentDisposition == null) return null;

    final regex = RegExp(r'filename="?([^"]+)"?');
    final match = regex.firstMatch(contentDisposition);

    return match?.group(1);
  }

  Future<List<DescuentoPersona>> listarDescuentos({
    required String tipoDoc,
    required String dni,
    required String mesAnio,
    required String tipoPlanilla,
  }) async {
    final uri = Uri.parse('${Conexion.apiUrlDocsLabs}/DescuentoDetalle'
        '?tipoDoc=$tipoDoc'
        '&dni=$dni'
        '&mesanio=$mesAnio'
        '&tipoPlanilla=$tipoPlanilla');

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Error al obtener descuentos');
    }

    final List data = jsonDecode(response.body);

    return data.map((e) => DescuentoPersona.fromJson(e)).toList();
  }
}
