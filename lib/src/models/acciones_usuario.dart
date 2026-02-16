// To parse this JSON data, do
//
//     final acciones = accionesFromJson(jsonString);

import 'dart:convert';

AccionesUsuario accionesFromJson(String str) =>
    AccionesUsuario.fromJson(json.decode(str));

String accionesToJson(AccionesUsuario data) => json.encode(data.toJson());

class AccionesUsuario {
  String id = "";
  String accion = "";

  AccionesUsuario();

  AccionesUsuario.fromJson(Map<String, dynamic> json) {
    id = json["id"].toString();
    accion = json["accion"];
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "accion": accion,
      };
}
