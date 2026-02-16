import 'dart:convert';

import 'package:embarques_tdp/src/models/cheklist_mantenimiento.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_obtener_taller.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_orden_servicio.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_requerimientos_unidad.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_trabajos_unidad.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:embarques_tdp/src/connection/conexion.dart';

class OrdenServicioService {
  final String _url = Conexion.apiUrl;

  Future<OsRequerimientosUnidad> BuscarProblemasUnidad_Jefatura({
    required String CodVeh,
    required String CodPro,
  }) async {
    final url = _url + 'Listar_BuscarProblemasUnidad_Jefatura';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['CodVeh'] = CodVeh;
    mapFormData['CodPro'] = CodPro;

    OsRequerimientosUnidad requemientosUnidad = OsRequerimientosUnidad.constructor();

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        requemientosUnidad = OsRequerimientosUnidad.fromJson(decodedData);
      }
    } catch (e) {
      requemientosUnidad.rpta = "${400}";
      requemientosUnidad.mensaje = "${e.toString()}";
    }
    return requemientosUnidad;
  }

  Future<OsRequerimientosUnidad> BuscarProblemasUnidad_Mantenimiento({
    required String CodVeh,
    required String CodPro,
    required String Tdoc,
    required String Ndoc,
  }) async {
    final url = _url + 'Listar_BuscarProblemasUnidad_Mantenimiento';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['CodVeh'] = CodVeh;
    mapFormData['CodPro'] = CodPro;
    mapFormData['Tdoc'] = Tdoc;
    mapFormData['Ndoc'] = Ndoc;

    OsRequerimientosUnidad requemientosUnidad = OsRequerimientosUnidad.constructor();

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        requemientosUnidad = OsRequerimientosUnidad.fromJson(decodedData);
      }
    } catch (e) {
      requemientosUnidad.rpta = "${400}";
      requemientosUnidad.mensaje = "${e.toString()}";
    }
    return requemientosUnidad;
  }

  Future<OsTrabajosUnidad> Listar_BuscarTrabajosRegistrados_Jefatura({
    required String NroOS,
    required String taller,
    required String CodPro,
  }) async {
    final url = _url + 'Listar_BuscarTrabajosRegistrados_Jefatura';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['NroOS'] = NroOS;
    mapFormData['taller'] = taller;
    mapFormData['CodPro'] = CodPro;

    OsTrabajosUnidad trabajosUnidad = OsTrabajosUnidad.constructor();

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        trabajosUnidad = OsTrabajosUnidad.fromJson(decodedData);
      }
    } catch (e) {
      trabajosUnidad.rpta = "${400}";
      trabajosUnidad.mensaje = "${e.toString()}";
    }
    return trabajosUnidad;
  }

  Future<OsTrabajosUnidad> Listar_BuscarTrabajosRegistrados_Mantenimiento({
    required String NroOS,
    required String taller,
    required String CodPro,
    required String Tdoc,
    required String Ndoc,
  }) async {
    final url = _url + 'Listar_BuscarTrabajosRegistrados_Mantenimiento';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['NroOS'] = NroOS;
    mapFormData['taller'] = taller;
    mapFormData['CodPro'] = CodPro;
    mapFormData['Tdoc'] = Tdoc;
    mapFormData['Ndoc'] = Ndoc;

    OsTrabajosUnidad trabajosUnidad = OsTrabajosUnidad.constructor();

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        trabajosUnidad = OsTrabajosUnidad.fromJson(decodedData);
      }
    } catch (e) {
      trabajosUnidad.rpta = "${400}";
      trabajosUnidad.mensaje = "${e.toString()}";
    }
    return trabajosUnidad;
  }

  Future<OsOrdenServicio> ListaOrdenesServicio_Jefatura({
    required String Taller,
    required String Placa,
  }) async {
    final url = _url + 'Listar_OrdenServicio_Jefatura';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['Taller'] = Taller;
    mapFormData['Placa'] = Placa;

    OsOrdenServicio orden = OsOrdenServicio.constructor();

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        orden = OsOrdenServicio.fromJson(decodedData);
      }
    } catch (e) {
      orden.rpta = "${400}";
      orden.mensaje = "${e.toString()}";
    }
    return orden;
  }

  Future<OsOrdenServicio> ListaOrdenesServicio_Mantenimiento({
    required String Taller,
    required String Placa,
    required String Tdoc,
    required String Ndoc,
  }) async {
    final url = _url + 'Listar_OrdenServicio_Mantenimiento';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['Taller'] = Taller;
    mapFormData['Placa'] = Placa;
    mapFormData['Tdoc'] = Tdoc;
    mapFormData['Ndoc'] = Ndoc;

    OsOrdenServicio orden = OsOrdenServicio.constructor();

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        orden = OsOrdenServicio.fromJson(decodedData);
      }
    } catch (e) {
      orden.rpta = "${400}";
      orden.mensaje = "${e.toString()}";
    }
    return orden;
  }

  Future<OsObtenerTaller> ObtenerTaller({
    required String tdoc,
    required String ndoc,
  }) async {
    final url = _url + 'obtenerTaller';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['TDOC'] = tdoc;
    mapFormData['NDOC'] = ndoc;

    OsObtenerTaller taller = OsObtenerTaller.constructor();

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        taller = OsObtenerTaller.fromJson(decodedData);
      }
    } catch (e) {
      taller.rpta = "${400}";
      taller.mensaje = "${e.toString()}";
    }
    return taller;
  }
}
