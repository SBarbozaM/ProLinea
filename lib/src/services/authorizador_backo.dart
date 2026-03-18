import 'dart:convert';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/DocumentoDetalle.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/DocumentoRegistrado.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/RespuestaAction.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/TipoDocumento.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/GrupoDocumento.dart';
import 'package:http/http.dart' as http;
import '../connection/conexion.dart';

class DocsBackoServicio {
  final String _url = Conexion.apiUrlDocBacko;

  // Tipos de documentos
  Future<List<TipoDocumento>> listarTiposDocumentos() async {
    final url = _url + '/obtenerdocumentos';
    try {
      final resp = await http.get(Uri.parse(url));
      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData is List && decodedData.isNotEmpty) {
        return decodedData.map((e) => TipoDocumento.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }

  // Pendientes
  Future<List<GrupoDocumento>> listarDocumentosPendientes({
    required int idTipoDocAprobacion,
    required String tipoDocumentoCodigo,
    required String dniColaborador,
  }) async {
    final url = '$_url/ObtenerDocumentosPendientes?idTipoDocApro=$idTipoDocAprobacion&tipoDoc=$tipoDocumentoCodigo&numDoc=$dniColaborador';
    // final url = '$_url/ObtenerDocumentosPendientes?idTipoDocApro=$idTipoDocAprobacion&tipoDoc=$tipoDocumentoCodigo&numDoc=$dniColaborador';
    return await _getGrupoDocumentos(url);
  }

  // Aprobados
  Future<List<GrupoDocumento>> listarDocumentosAprobados({
    required int idTipoDocAprobacion,
    required String tipoDocumentoCodigo,
    required String dniColaborador,
  }) async {
    final url = '$_url/ObtenerDocumentosAprobados?idTipoDocApro=$idTipoDocAprobacion&tipoDoc=$tipoDocumentoCodigo&numDoc=$dniColaborador';
    // final url = '$_url/ObtenerDocumentosAprobados?idTipoDocApro=$idTipoDocAprobacion&tipoDoc=$tipoDocumentoCodigo&numDoc=$dniColaborador';
    return await _getGrupoDocumentos(url);
  }

  // Observados
  Future<List<GrupoDocumento>> listarDocumentosObservados({
    required int idTipoDocAprobacion,
    required String tipoDocumentoCodigo,
    required String dniColaborador,
  }) async {
    final url = '$_url/ObtenerDocumentosObservados?idTipoDocApro=$idTipoDocAprobacion&tipoDoc=$tipoDocumentoCodigo&numDoc=$dniColaborador';
    return await _getGrupoDocumentos(url);
  }

  // Rechazados
  Future<List<GrupoDocumento>> listarDocumentosRechazados({
    required int idTipoDocAprobacion,
    required String tipoDocumentoCodigo,
    required String dniColaborador,
  }) async {
    final url = '$_url/ObtenerDocumentosRechazados?idTipoDocApro=$idTipoDocAprobacion&tipoDoc=$tipoDocumentoCodigo&numDoc=$dniColaborador';
    return await _getGrupoDocumentos(url);
  }

  Future<DocumentoDetalleNormalizado?> obtenerDocumentoDetalle({
    required int id,
    required int tipoId,
  }) async { 
    final url = '$_url/ObtenerDocumentoDetalle?id=$id&tipoId=$tipoId';
    try {
      final resp = await http.get(Uri.parse(url));
      final decodedData = json.decode(resp.body);
      if (decodedData != null) {
        return DocumentoDetalleNormalizado.fromJson(decodedData);
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  Future<List<DocumentoRegistrado>> listarDocumentosRegistrados({
    required int idTipoDocumento,
    required String tipoDocumentoCodigo,
    required String dniColaborador,
  }) async {
    final url = '$_url/ObtenerDocumentosRegistrados?idTipoDocApro=$idTipoDocumento&tipoDoc=$tipoDocumentoCodigo&numDoc=$dniColaborador';
    try {
      final resp = await http.get(Uri.parse(url));
      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData is List && decodedData.isNotEmpty) {
        return decodedData.map((e) => DocumentoRegistrado.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }

  Future<RespuestaAccion?> _postAccion(String endpoint, Map<String, dynamic> body) async {
    final url = '$_url/$endpoint';
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      final decodedData = json.decode(resp.body);
      if (decodedData != null) {
        return RespuestaAccion.fromJson(decodedData);
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  Future<RespuestaAccion?> aprobarDocumento({
    required String tipoDocumentoCodigo,
    required String dniCreadoPor,
    required int id,
    required int idTipoDocumento,
  }) async {
    return await _postAccion('AprobarDocumento', {
      'TipoDocumentoCodigo': tipoDocumentoCodigo,
      'DniCreadoPor': dniCreadoPor,
      'Id': id,
      'MotivoRechazoObservacion': '',
      'IdTipoDocumento': idTipoDocumento,
    });
  }

  Future<RespuestaAccion?> rechazarDocumento({
    required String tipoDocumentoCodigo,
    required String dniCreadoPor,
    required int id,
    required String motivo,
    required int idTipoDocumento,
  }) async {
    return await _postAccion('RechazarDocumento', {
      'TipoDocumentoCodigo': tipoDocumentoCodigo,
      'DniCreadoPor': dniCreadoPor,
      'Id': id,
      'MotivoRechazoObservacion': motivo,
      'IdTipoDocumento': idTipoDocumento,
    });
  }

  Future<RespuestaAccion?> observarDocumento({
    required String tipoDocumentoCodigo,
    required String dniCreadoPor,
    required int id,
    required String motivo,
    required int idTipoDocumento,
  }) async {
    return await _postAccion('ObservarDocumento', {
      'TipoDocumentoCodigo': tipoDocumentoCodigo,
      'DniCreadoPor': dniCreadoPor,
      'Id': id,
      'MotivoRechazoObservacion': motivo,
      'IdTipoDocumento': idTipoDocumento,
    });
  }

  // Método privado reutilizable
  Future<List<GrupoDocumento>> _getGrupoDocumentos(String url) async {
    try {
      final resp = await http.get(Uri.parse(url));
      final decodedData = json.decode(resp.body);
      if (decodedData != null && decodedData is List && decodedData.isNotEmpty) {
        return decodedData.map((e) => GrupoDocumento.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }
}
