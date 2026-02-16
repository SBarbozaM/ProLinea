import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:embarques_tdp/src/models/logger_model.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class Log {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/bitacora.txt');
  }

  static ingreso(BuildContext context, String Mensaje) async {
    var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    await AppDatabase.instance.NuevoRegistroBitacora(
      context,
      "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
      "${usuarioLogin.codOperacion}",
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "Embarque ${usuarioLogin.perfil}: ${Mensaje}",
      "Exitoso",
    );
  }

  static insertarLogDomicilio({
    required BuildContext context,
    required String mensaje,
    required String rpta,
  }) async {
    var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    await AppDatabase.instance.NuevoRegistroBitacora(
      context,
      "${usuarioLogin.perfil} - ${usuarioLogin.tipoDoc}${usuarioLogin.numDoc}",
      "${usuarioLogin.codOperacion}",
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "${mensaje}",
      "${rpta}",
    );
  }

  Future<String> convertBase64() async {
    try {
      final file = await _localFile;
      Uint8List imagebytes = await file.readAsBytes(); //convert to bytes
      String base64string = base64.encode(imagebytes); //convert bytes to base64 string
      print(base64string);
      return base64string;
    } catch (e) {
      return "";
    }
  }

  initDebug(BuildContext context, Usuario usuarioLog, Usuario usuarioRegistro) async {
    if (usuarioLog.Log == "1") {
      List<LoggerModel> listaModel = await AppDatabase.instance.ListarBitacora();

      print("lista model $listaModel");

      var lista = [];

      for (var model in listaModel) {
        lista.add(model.toJson());
      }

      if (listaModel.isNotEmpty) {
        UsuarioServicio servicioUsuario = UsuarioServicio();
        String idDispositivo = Provider.of<UsuarioProvider>(context, listen: false).idDispositivo;

        String status = await servicioUsuario.GuardarArchivoLog(
          usuarioRegistro.tipoDoc,
          usuarioRegistro.numDoc,
          idDispositivo,
          lista.toString(),
        );

        if (status == "0") {
          // final file = await _localFile;
          // file.delete();
          await AppDatabase.instance.EliminarRegistrosBitacora();
        } else {
          // final file = await _localFile;
          // file.delete();
        }
      }
    }
  }

  initLogApp(BuildContext context, Usuario usuarioRegistro) async {
    List<LoggerModel> listaModel = await AppDatabase.instance.ListarBitacora();
    if (listaModel.isNotEmpty) {
      var lista = [];

      for (var model in listaModel) {
        lista.add(model.toJson());
      }

      UsuarioServicio servicioUsuario = UsuarioServicio();
      String idDispositivo = Provider.of<UsuarioProvider>(context, listen: false).idDispositivo;
      String status = await servicioUsuario.GuardarArchivoLog(
        usuarioRegistro.tipoDoc,
        usuarioRegistro.numDoc,
        idDispositivo,
        lista.toString(),
      );

      if (status == "0") {
        // final file = await _localFile;
        // file.delete();
        await AppDatabase.instance.EliminarRegistrosBitacora();
      } else {
        // final file = await _localFile;
        // file.delete();
      }
    }
  }
}
