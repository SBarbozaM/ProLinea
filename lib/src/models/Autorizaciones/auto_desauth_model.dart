// To parse this JSON data, do
//
//     final autorizaRechazaModel = autorizaRechazaModelFromJson(jsonString);

import 'dart:convert';

AutorizaRechazaModel autorizaRechazaModelFromJson(String str) => AutorizaRechazaModel.fromJson(json.decode(str));

String autorizaRechazaModelToJson(AutorizaRechazaModel data) => json.encode(data.toJson());

class AutorizaRechazaModel {
  String rpta;
  String mensaje;
  String tipoDoc;
  String numDoc;
  String subAccion;
  String idDoc;
  String tipoDocumento;
  String estado;
  String motivo;
  String documento;

  AutorizaRechazaModel({
    required this.rpta,
    required this.mensaje,
    required this.tipoDoc,
    required this.numDoc,
    required this.subAccion,
    required this.idDoc,
    required this.tipoDocumento,
    required this.estado,
    required this.motivo,
    required this.documento,
  });

  factory AutorizaRechazaModel.fromJson(Map<String, dynamic> json) => AutorizaRechazaModel(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tipoDoc: json["tipoDoc"],
        numDoc: json["numDoc"],
        subAccion: json["subAccion"],
        idDoc: json["idDoc"],
        tipoDocumento: json["tipoDocumento"],
        estado: json["estado"],
        motivo: json["motivo"],
        documento: json["documento"],
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "subAccion": subAccion,
        "idDoc": idDoc,
        "tipoDocumento": tipoDocumento,
        "estado": estado,
        "motivo": motivo,
        "documento": documento,
      };
}
