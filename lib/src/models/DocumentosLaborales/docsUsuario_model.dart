import 'package:embarques_tdp/src/models/DocumentosLaborales/docsAcciones_model.dart';
import 'package:embarques_tdp/src/models/usuario.dart';

class DocsUsuario {
  String rpta;
  String mensaje;
  String tipoDoc;
  String numDoc;
  List<AccionId> docsAcciones;

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
        docsAcciones: List<AccionId>.from(json["auth_acciones"].map((x) {
          final doc = DocsAccion.fromJson(x);
          return AccionId(
            id: doc.id,
            accion: doc.nombre,
            orden: doc.orden.toString(),
            pendientes: doc.pendientes,
            icono: doc.icono,
            accionPredecesora: 0,
            url: '',
          );
        })),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "auth_acciones": List<dynamic>.from(docsAcciones.map((x) => x.toJson())),
      };
}