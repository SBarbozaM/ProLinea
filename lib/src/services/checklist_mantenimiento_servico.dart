import 'dart:convert';
import 'dart:io';

import 'package:embarques_tdp/src/models/check_list/checklist.dart';
import 'package:embarques_tdp/src/models/check_list/cheklist_mantenimiento.dart';
import 'package:embarques_tdp/src/models/check_list/validar_checklist.dart';
import 'package:embarques_tdp/src/models/check_list/validar_edit_checkList.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:intl/intl.dart';

class ChecklistServicio {
  final String _url = Conexion.apiUrl;

  Future<CheckListModel> GET_CheckList({required int Hs_codigo, required String tDoc, required String nDoc, required String placa, required int tipoCheckList}) async {
    CheckListModel check = CheckListModel.empty();

    // final url = _url + 'Listar_CheckList/${Hs_codigo}/${tDoc}/${nDoc}';
    final url = _url + 'Listar_CheckListV2/${Hs_codigo}/${tDoc}/${nDoc}/${placa}/${tipoCheckList}';
    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        check = CheckListModel.fromJson(decodedData);
      }
    } catch (e) {
      String mensajeSeguro = "Error inesperado. Inténtelo nuevamente.";

      // 🔍 Sin conexión a Internet
      if (e is SocketException) {
        mensajeSeguro = "Sin conexión a Internet. Por favor verifique su red.";
      }

      // 🔍 Timeout de la solicitud
      if (e is TimeoutException) {
        mensajeSeguro = "El servidor no responde. Intente nuevamente.";
      }
      check.rpta = "${400}";
      check.mensaje = mensajeSeguro;
    }
    return check;
  }

  Future<TipoCheckListModel> GET_TipoCheckList({required String tDoc, required String nDoc}) async {
    TipoCheckListModel check = TipoCheckListModel.empty();

    final url = _url + 'Listar_CheckTipoList/${tDoc}/${nDoc}';
    try {
      final resp = await http.get(Uri.parse(url), headers: {"Content-Type": "application/json"}).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw TimeoutException('La solicitud excedió el tiempo de espera');
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        check = TipoCheckListModel.fromJson(decodedData);
      }
    } catch (e) {
      check.rpta = "${400}";
      check.mensaje = "${e.toString()}";
    }
    return check;
  }

  Future<ValidarCheckList> Validar_CheckList({
    required String tipoDoc,
    required String nroDoc,
    required String placa,
    required String codOperacion,
    required int tipoCheckList
  }) async {
    ValidarCheckList check = ValidarCheckList(rpta: "", mensaje: "", nroViaje: 0, tipoChecklist: "", descVehiculo: "", codVehiculo: "", hoseCodigo: 0, hoseRegistro: "", maxFiles: 0, maxSizeFiles: 0);

    final url = _url + 'Validar_CheckList';
    try {
      var mapFormData = new Map<String, dynamic>();
      mapFormData['tipoDoc'] = tipoDoc;
      mapFormData['nroDoc'] = nroDoc;
      mapFormData['placa'] = placa;
      mapFormData['codOperacion'] = codOperacion;
      mapFormData['tipoCheckList'] = tipoCheckList.toString();

      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 20), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw ValidarCheckList(rpta: "${400}", mensaje: 'La solicitud excedió el tiempo de espera', nroViaje: 0, tipoChecklist: "", descVehiculo: "", codVehiculo: "", hoseCodigo: 0, hoseRegistro: "", maxFiles: 0, maxSizeFiles: 0);
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        check = ValidarCheckList.fromJson(decodedData);
      }
    } catch (e) {
      String mensajeSeguro = "Error inesperado. Inténtelo nuevamente.";

      // 🔍 Sin conexión a Internet
      if (e is SocketException) {
        mensajeSeguro = "Sin conexión a Internet. Por favor verifique su red.";
      }

      // 🔍 Timeout de la solicitud
      if (e is TimeoutException) {
        mensajeSeguro = "El servidor no responde. Intente nuevamente.";
      }

      check = ValidarCheckList(
          rpta: "400",
          mensaje: mensajeSeguro, // 👈 YA NO SE MUESTRA URL NI ERROR TÉCNICO
          nroViaje: 0,
          tipoChecklist: "",
          descVehiculo: "",
          codVehiculo: "",
          hoseCodigo: 0,
          hoseRegistro: "",
          maxFiles: 0,
          maxSizeFiles: 0);
    }
    return check;
  }

  Future<ValidarEditCheckList> ValidarListarEditarCheckList({
    required String tipoDoc,
    required String nroDoc,
    required String placa,
    required String codOperacion,
  }) async {
    ValidarEditCheckList check = ValidarEditCheckList.empty();

    final url = _url + 'Validar_Listar_Edit_CheckList';

    var mapFormData = new Map<String, dynamic>();
    mapFormData['tipoDoc'] = tipoDoc;
    mapFormData['nroDoc'] = nroDoc;
    mapFormData['placa'] = placa;
    mapFormData['codOperacion'] = codOperacion;

    try {
      final resp = await http.post(Uri.parse(url), body: mapFormData).timeout(
        Duration(seconds: 10), // Establece el tiempo de espera en segundos
        onTimeout: () {
          throw check.mensaje = "La solicitud excedió el tiempo de espera";
        },
      );

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        check = ValidarEditCheckList.fromJson(decodedData);
      }
    } catch (e) {
      check.rpta = "${400}";
      check.mensaje = "${e.toString()}";
    }
    return check;
  }

  Future<ValidarCheckList> Guardar_Editar_CheckList({required String body}) async {
    ValidarCheckList check = ValidarCheckList(rpta: "", mensaje: "", nroViaje: 0, tipoChecklist: "", descVehiculo: "", codVehiculo: "", hoseCodigo: 0, hoseRegistro: "", maxFiles: 0, maxSizeFiles: 0);

    // final url = _url + 'Guardar_Editar_CheckList';
    final url = _url + 'Guardar_Editar_CheckList_v2';
    try {
      final resp = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json"}, body: body);

      if (resp.statusCode == 200) {
        final decodedData = json.decode(resp.body);
        check = ValidarCheckList.fromJson(decodedData);
      }
    } catch (e) {
      String mensajeSeguro = "Error inesperado. Inténtelo nuevamente.";

      // 🔍 Sin conexión a Internet
      if (e is SocketException) {
        mensajeSeguro = "Sin conexión a Internet. Por favor verifique su red.";
      }

      // 🔍 Timeout de la solicitud
      if (e is TimeoutException) {
        mensajeSeguro = "El servidor no responde. Intente nuevamente.";
      }
      check = ValidarCheckList(rpta: "${400}", mensaje: mensajeSeguro, nroViaje: 0, tipoChecklist: "", descVehiculo: "", codVehiculo: "", hoseCodigo: 0, hoseRegistro: "", maxFiles: 0, maxSizeFiles: 0);
    }
    return check;
  }

  // List<CheckList> listaCheckList = [
  //   CheckList(orden: 0, categoria: "Servicio y Mantenimiento", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 1, categoria: "Servicio y Mantenimiento", nombre: "Lavar Motor", fotos: [], descripcion: "Todo muy bien"),
  //   CheckList(orden: 2, categoria: "Servicio y Mantenimiento", nombre: "Lavado y Engrase", fotos: [], descripcion: ""),
  //   CheckList(orden: 3, categoria: "Servicio y Mantenimiento", nombre: "Cambio de lubricantes", fotos: [], descripcion: ""),
  //   CheckList(orden: 4, categoria: "Servicio y Mantenimiento", nombre: "Mantenimiento preventivo", fotos: [], descripcion: ""),
  //   CheckList(orden: 104, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML01", fotos: [], descripcion: ""),
  //   CheckList(orden: 105, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML02", fotos: [], descripcion: ""),
  //   CheckList(orden: 106, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML03", fotos: [], descripcion: ""),
  //   CheckList(orden: 107, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML04", fotos: [], descripcion: ""),
  //   CheckList(orden: 108, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML05", fotos: [], descripcion: ""),
  //   CheckList(orden: 109, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML06", fotos: [], descripcion: ""),
  //   CheckList(orden: 110, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML07", fotos: [], descripcion: ""),
  //   CheckList(orden: 111, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML08", fotos: [], descripcion: ""),
  //   CheckList(orden: 112, categoria: "Servicio y Mantenimiento", nombre: "Plan de Mantenimiento - PML09", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Motor", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 5, categoria: "Motor", nombre: "Temperatura", fotos: [], descripcion: ""),
  //   CheckList(orden: 6, categoria: "Motor", nombre: "Presion de aceite", fotos: [], descripcion: ""),
  //   CheckList(orden: 7, categoria: "Motor", nombre: "Consumo de aceite", fotos: [], descripcion: ""),
  //   CheckList(orden: 8, categoria: "Motor", nombre: "Consumo de agua", fotos: [], descripcion: ""),
  //   CheckList(orden: 9, categoria: "Motor", nombre: "Potencia", fotos: [], descripcion: ""),
  //   CheckList(orden: 10, categoria: "Motor", nombre: "Golpe", fotos: [], descripcion: ""),
  //   CheckList(orden: 11, categoria: "Motor", nombre: "Emision de humo", fotos: [], descripcion: ""),
  //   CheckList(orden: 12, categoria: "Motor", nombre: "Fuga de agua", fotos: [], descripcion: ""),
  //   CheckList(orden: 13, categoria: "Motor", nombre: "Fuga de aceite", fotos: [], descripcion: ""),
  //   CheckList(orden: 14, categoria: "Motor", nombre: "Mezcla agua - aceite", fotos: [], descripcion: ""),
  //   CheckList(orden: 15, categoria: "Motor", nombre: "Mezcla aceite - combustible", fotos: [], descripcion: ""),
  //   CheckList(orden: 16, categoria: "Motor", nombre: "Estado Refrigerante", fotos: [], descripcion: ""),
  //   CheckList(orden: 17, categoria: "Motor", nombre: "Turbo", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Electricordenad e Instrumentos", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 18, categoria: "Electricordenad e Instrumentos", nombre: "Bateria", fotos: [], descripcion: ""),
  //   CheckList(orden: 19, categoria: "Electricordenad e Instrumentos", nombre: "Arrancador", fotos: [], descripcion: ""),
  //   CheckList(orden: 20, categoria: "Electricordenad e Instrumentos", nombre: "Alternador", fotos: [], descripcion: ""),
  //   CheckList(orden: 21, categoria: "Electricordenad e Instrumentos", nombre: "Alumbrado", fotos: [], descripcion: ""),
  //   CheckList(orden: 22, categoria: "Electricordenad e Instrumentos", nombre: "Mecanismos limpia y lava parabrisas", fotos: [], descripcion: ""),
  //   CheckList(orden: 23, categoria: "Electricordenad e Instrumentos", nombre: "Testigos", fotos: [], descripcion: ""),
  //   CheckList(orden: 24, categoria: "Electricordenad e Instrumentos", nombre: "Relojes", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Transmision", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 25, categoria: "Transmision", nombre: "Embrague", fotos: [], descripcion: ""),
  //   CheckList(orden: 26, categoria: "Transmision", nombre: "Ronquordeno caja de cambios", fotos: [], descripcion: ""),
  //   CheckList(orden: 27, categoria: "Transmision", nombre: "Se desengancha algun cambio", fotos: [], descripcion: ""),
  //   CheckList(orden: 28, categoria: "Transmision", nombre: "No entra algun cambio", fotos: [], descripcion: ""),
  //   CheckList(orden: 29, categoria: "Transmision", nombre: "Ronquordeno corona", fotos: [], descripcion: ""),
  //   CheckList(orden: 30, categoria: "Transmision", nombre: "Cardanes", fotos: [], descripcion: ""),
  //   CheckList(orden: 31, categoria: "Transmision", nombre: "Fuga de aceite de caja de cambios", fotos: [], descripcion: ""),
  //   CheckList(orden: 32, categoria: "Transmision", nombre: "Fuga de aceite de corona", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Frenos", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 33, categoria: "Frenos", nombre: "Frenos de servicio", fotos: [], descripcion: ""),
  //   CheckList(orden: 34, categoria: "Frenos", nombre: "Freno de estacionamiento", fotos: [], descripcion: ""),
  //   CheckList(orden: 35, categoria: "Frenos", nombre: "Tiempo de Carga de aire", fotos: [], descripcion: ""),
  //   CheckList(orden: 36, categoria: "Frenos", nombre: "Compresora", fotos: [], descripcion: ""),
  //   CheckList(orden: 37, categoria: "Frenos", nombre: "Fugas de aire", fotos: [], descripcion: ""),
  //   CheckList(orden: 38, categoria: "Frenos", nombre: "Valvulas de aire", fotos: [], descripcion: ""),
  //   CheckList(orden: 39, categoria: "Frenos", nombre: "Freno de motor", fotos: [], descripcion: ""),
  //   CheckList(orden: 40, categoria: "Frenos", nombre: "Retardador", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Direccion y Ruedas", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 41, categoria: "Direccion y Ruedas", nombre: "Direccion", fotos: [], descripcion: ""),
  //   CheckList(orden: 42, categoria: "Direccion y Ruedas", nombre: "Bomba Servo", fotos: [], descripcion: ""),
  //   CheckList(orden: 43, categoria: "Direccion y Ruedas", nombre: "Fuga de aceite (Hordenrolina)", fotos: [], descripcion: ""),
  //   CheckList(orden: 44, categoria: "Direccion y Ruedas", nombre: "Ruedas", fotos: [], descripcion: ""),
  //   CheckList(orden: 45, categoria: "Direccion y Ruedas", nombre: "Neumáticos", fotos: [], descripcion: ""),
  //   CheckList(orden: 87, categoria: "Direccion y Ruedas", nombre: "Casco golpeado o rozado", fotos: [], descripcion: ""),
  //   CheckList(orden: 88, categoria: "Direccion y Ruedas", nombre: "Desgaste de hombros", fotos: [], descripcion: ""),
  //   CheckList(orden: 89, categoria: "Direccion y Ruedas", nombre: "Incrustacion de piedras", fotos: [], descripcion: ""),
  //   CheckList(orden: 90, categoria: "Direccion y Ruedas", nombre: "Valvula sin tapa", fotos: [], descripcion: ""),
  //   CheckList(orden: 91, categoria: "Direccion y Ruedas", nombre: "Corte en banda y/o casco", fotos: [], descripcion: ""),
  //   CheckList(orden: 92, categoria: "Direccion y Ruedas", nombre: "Sin extensiones o en mal estado", fotos: [], descripcion: ""),
  //   CheckList(orden: 93, categoria: "Direccion y Ruedas", nombre: "Cocada desgastada o picoteada", fotos: [], descripcion: ""),
  //   CheckList(orden: 94, categoria: "Direccion y Ruedas", nombre: "Presion elevada o baja", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Bastordenor, Suspension y Amortiguacion", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 46, categoria: "Bastordenor, Suspension y Amortiguacion", nombre: "Barras de direccion", fotos: [], descripcion: ""),
  //   CheckList(orden: 47, categoria: "Bastordenor, Suspension y Amortiguacion", nombre: "Barras estabilizadoras", fotos: [], descripcion: ""),
  //   CheckList(orden: 48, categoria: "Bastordenor, Suspension y Amortiguacion", nombre: "Muelles", fotos: [], descripcion: ""),
  //   CheckList(orden: 49, categoria: "Bastordenor, Suspension y Amortiguacion", nombre: "Bolsas", fotos: [], descripcion: ""),
  //   CheckList(orden: 50, categoria: "Bastordenor, Suspension y Amortiguacion", nombre: "Amortiguadores", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Carroceria", nombre: "0", fotos: [], descripcion: ""),
  //   CheckList(orden: 51, categoria: "Carroceria", nombre: "Puertas", fotos: [], descripcion: ""),
  //   CheckList(orden: 52, categoria: "Carroceria", nombre: "Parabrisas y Vordenrios", fotos: [], descripcion: ""),
  //   CheckList(orden: 53, categoria: "Carroceria", nombre: "Bodegas", fotos: [], descripcion: ""),
  //   CheckList(orden: 54, categoria: "Carroceria", nombre: "Asientos", fotos: [], descripcion: ""),
  //   CheckList(orden: 55, categoria: "Carroceria", nombre: "Baño", fotos: [], descripcion: ""),
  //   CheckList(orden: 56, categoria: "Carroceria", nombre: "Equipos interiores", fotos: [], descripcion: ""),
  //   CheckList(orden: 57, categoria: "Carroceria", nombre: "Equipos de segurordenad", fotos: [], descripcion: ""),
  //   CheckList(orden: 58, categoria: "Carroceria", nombre: "Herramientas", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Aire Acondicionado", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 59, categoria: "Aire Acondicionado", nombre: "Aire acondicionado", fotos: [], descripcion: ""),
  //   CheckList(orden: 0, categoria: "Audio y Vordeneo", nombre: "", fotos: [], descripcion: ""),
  //   CheckList(orden: 60, categoria: "Audio y Vordeneo", nombre: "Audio y vordeneo", fotos: [], descripcion: ""),
  //   CheckList(orden: 61, categoria: "Otros", nombre: "Otro", fotos: [], descripcion: ""),
  //   CheckList(orden: 62, categoria: "Otros", nombre: "Otro", fotos: [], descripcion: ""),
  // ];
}
