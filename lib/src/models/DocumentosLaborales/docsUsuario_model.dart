import 'package:embarques_tdp/src/models/DocumentosLaborales/docsAcciones_model.dart';

class DocsUsuario {
  String rpta;
  String mensaje;
  String tipoDoc;
  String numDoc;
  List<DocsAccion> docsAcciones;

  DocsUsuario({
    required this.rpta,
    required this.mensaje,
    required this.tipoDoc,
    required this.numDoc,
    required this.docsAcciones,
  });

  factory DocsUsuario.fromJson(Map<String, dynamic> json) => DocsUsuario(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tipoDoc: json["tipoDoc"],
        numDoc: json["numDoc"],
        docsAcciones: List<DocsAccion>.from(json["auth_acciones"].map((x) => DocsAccion.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "auth_acciones": List<dynamic>.from(docsAcciones.map((x) => x.toJson())),
      };
}