import 'dart:convert';

import 'package:embarques_tdp/src/models/usuario.dart';

SubAuthUsuarioModel subAuthUsuarioModelFromJson(String str) => SubAuthUsuarioModel.fromJson(json.decode(str));

String subAuthUsuarioModelToJson(SubAuthUsuarioModel data) => json.encode(data.toJson());

class SubAuthUsuarioModel {
  String rpta;
  String mensaje;
  String tipoDoc;
  String numDoc;
  int idAuth;
  List<AccionId> authSubAcciones;

  SubAuthUsuarioModel({
    required this.rpta,
    required this.mensaje,
    required this.tipoDoc,
    required this.numDoc,
    required this.idAuth,
    required this.authSubAcciones,
  });

  factory SubAuthUsuarioModel.fromJson(Map<String, dynamic> json) => SubAuthUsuarioModel(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tipoDoc: json["tipoDoc"],
        numDoc: json["numDoc"],
        idAuth: json["idAuth"],
        authSubAcciones: List<AccionId>.from(json["auth_sub_acciones"].map((x) => AccionId.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "idAuth": idAuth,
        "auth_sub_acciones": List<dynamic>.from(authSubAcciones.map((x) => x.toJson())),
      };
}

class AuthSubAccione {
  String id;
  String accion;
  String orden;
  int pendientes;
  String icono;

  AuthSubAccione({
    required this.id,
    required this.accion,
    required this.orden,
    required this.pendientes,
    required this.icono,
  });

  factory AuthSubAccione.fromJson(Map<String, dynamic> json) => AuthSubAccione(
        id: json["id"],
        accion: json["accion"],
        orden: json["orden"],
        pendientes: json["pendientes"],
        icono: json["icono"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "accion": accion,
        "orden": orden,
        "pendientes": pendientes,
        "icono": icono,
      };
}
