import 'dart:async';
import 'dart:convert';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../connection/conexion.dart';
import '../models/ruta.dart';

class EmbarquesSupScanerServicio {
  String _url = Conexion.apiUrl;
  List<Ruta> _rutas = [];

  Future<Response?> ScanearUnidad(String textqr, String codOperacion) async {
    final url = _url + 'VincularValidaUnidad/${textqr.trim()}/${codOperacion.trim()}';

    try {
      final resp = await http.get(Uri.parse(url)).timeout(Duration(seconds: 15));
      return resp;
    } catch (e) {
      return null;
    }
  }

  Future<List<Ruta>> obtenerRutaSupervisor(String codOperacion) async {
    List<Ruta> listaRutas = [];
    final url = _url + 'listarRutasReservaHoy/${codOperacion}';

    try {
      final resp = await http.get(Uri.parse(url)).timeout(Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body) as List;
        print(decodedData);
        if (decodedData != null && decodedData.toString() != "[]") {
          listaRutas = decodedData.map((e) => Ruta.fromJsonMap(e)).toList();
        }
      }
    } catch (e) {}

    return listaRutas;
  }

  Future<List<Viaje>> obtenerViajesRutaSupervisor(String codOperacion, String codRuta) async {
    var mapFormData = new Map<String, dynamic>();

    mapFormData['codOperacion'] = codOperacion;
    mapFormData['codRuta'] = codRuta;
    List<Viaje> listaViajes = [];
    final url = _url + 'obtenerViajesPorAbarcarHoy';

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        if (decodedData != null && decodedData.toString() != "[]") {
          final viajes = Viajes.fromJsonList(decodedData);
          listaViajes.addAll(viajes.viajes);
        }
      } else {}
    } catch (e) {}

    return listaViajes;
  }

  Future<Response?> vincularInicio(String nroViaje, String NDocCondutor, String TDocUsuario, String NDocUsuario, String CodOperacion) async {
    final url = _url + 'VincularInicio';
    var mapFormData = new Map<String, dynamic>();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['NDocCondutor'] = NDocCondutor;
    mapFormData['TDocUsuario'] = TDocUsuario;
    mapFormData['NDocUsuario'] = NDocUsuario;
    mapFormData['CodOperacion'] = CodOperacion;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));
      return resp;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> vincularInicio_v2(
    String nroViaje,
    String NDocCondutor,
    String TDocUsuario,
    String NDocUsuario,
    String CodOperacion,
    String Coordenadas,
  ) async {
    final url = _url + 'VincularInicio_v2';
    var mapFormData = new Map<String, dynamic>();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['NDocCondutor'] = NDocCondutor;
    mapFormData['TDocUsuario'] = TDocUsuario;
    mapFormData['NDocUsuario'] = NDocUsuario;
    mapFormData['CodOperacion'] = CodOperacion;
    mapFormData['coordenadas'] = Coordenadas;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));
      return resp;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> ScanearUnidadJornada(String textqr, String codOperacion) async {
    final url = _url + 'VincularValidaUnidadJornada/${textqr.trim()}/${codOperacion.trim()}';

    try {
      final resp = await http.get(Uri.parse(url)).timeout(Duration(seconds: 15));
      return resp;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> vincularInicioJornada(
    String nroViaje,
    String NDocCondutor,
    String OrdenConductor,
    String TDocUsuario,
    String NDocUsuario,
    String CodOperacion,
    String odometroInicio,
  ) async {
    final url = _url + 'VincularInicioJornada';
    var mapFormData = new Map<String, dynamic>();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['NDocCondutor'] = NDocCondutor;
    mapFormData['OrdenConductor'] = OrdenConductor;
    mapFormData['TDocUsuario'] = TDocUsuario;
    mapFormData['NDocUsuario'] = NDocUsuario;
    mapFormData['CodOperacion'] = CodOperacion;
    mapFormData['OdometroInicio'] = odometroInicio;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));
      print(resp);
      return resp;
    } catch (e) {
      print(e);
      return null;
    }
  }
  //si-gps
  Future<Response?> vincularInicioJornada_v2(
    String nroViaje,
    String NDocCondutor,
    String OrdenConductor,
    String TDocUsuario,
    String NDocUsuario,
    String CodOperacion,
    String odometroInicio,
    String coordenadas,
    String odometroPor,
  ) async {
    final url = _url + 'VincularInicioJornada_v2';
    var mapFormData = new Map<String, dynamic>();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['NDocCondutor'] = NDocCondutor;
    mapFormData['OrdenConductor'] = OrdenConductor;
    mapFormData['TDocUsuario'] = TDocUsuario;
    mapFormData['NDocUsuario'] = NDocUsuario;
    mapFormData['CodOperacion'] = CodOperacion;
    mapFormData['OdometroInicio'] = odometroInicio;
    mapFormData['coordenadas'] = coordenadas;
    mapFormData['odometroPor'] = odometroPor;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));
      print(resp);
      return resp;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Response?> ObtenerOdometroViaje(String codUnidad) async {
    final url = _url + 'ObtenerOdometroViaje';
    var mapFormData = new Map<String, dynamic>();
    mapFormData['codUnidad'] = codUnidad;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));
      print(resp);
      return resp;
    } catch (e) {
      print(e);
      return null;
    }
  }
  //si-gps
  Future<Response?> IniciarViaje(
    String nroViaje,
    String NDocCondutor,
    String OrdenConductor,
    String TDocUsuario,
    String NDocUsuario,
    String CodOperacion,
    String odometroInicio,
    String cordenadaInicial,
  ) async {
    final url = _url + 'IniciarViaje';
    var mapFormData = new Map<String, dynamic>();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['NDocCondutor'] = NDocCondutor;
    mapFormData['OrdenConductor'] = OrdenConductor;
    mapFormData['TDocUsuario'] = TDocUsuario;
    mapFormData['NDocUsuario'] = NDocUsuario;
    mapFormData['CodOperacion'] = CodOperacion;
    mapFormData['OdometroInicio'] = odometroInicio;
    mapFormData['cordenadaInicial'] = cordenadaInicial;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));
      print(resp);
      return resp;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Response?> RegistarTurno(
    String nroViaje,
    String turno,
    String dni,
    String inicio,
    String fin,
    String cordenadasInicio,
    String cordenadasFin,
  ) async {
    final url = _url + 'RegistrarTurno';
    var mapFormData = new Map<String, dynamic>();
    mapFormData['nroViaje'] = nroViaje;
    mapFormData['Turno'] = turno;
    mapFormData['Dni'] = dni;
    mapFormData['Inicio'] = inicio;
    mapFormData['Fin'] = fin;
    mapFormData['CordenadasInicio'] = cordenadasInicio;
    mapFormData['CordenadasFin'] = cordenadasFin;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(Duration(seconds: 15));
      return resp;
    } catch (e) {
      return null;
    }
  }

  Future<Response?> ObtenerTurnoViajeVincualdo(String nroViaje) async {
    final url = _url + 'listarTurnosViajeVinculado/${nroViaje.trim()}';

    try {
      final resp = await http.get(Uri.parse(url));
      return resp;
    } catch (e) {
      return null;
    }
  }

  /// OBTENER DATOS VINCULACION

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
      final resp = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: str).timeout(Duration(seconds: 15));

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
}
