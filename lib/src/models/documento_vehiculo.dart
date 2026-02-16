import 'dart:io';

class DocumentoVehiculo {
  DocumentoVehiculo({
    required this.rpta,
    required this.mensaje,
    required this.nombre,
    required this.numeroDoc,
    required this.estado,
    required this.fechaVencimiento,
    required this.tipoDoc,
    required this.estadoDescripcion,
    required this.documento,
    required this.idDocOpenVehi,
  });

  String rpta;
  String mensaje;
  String nombre;
  String numeroDoc;
  String estado;
  String fechaVencimiento;
  String tipoDoc;
  String estadoDescripcion;
  String documento;
  String idDocOpenVehi;
  bool isExpanded = false;
  String file = "";

  factory DocumentoVehiculo.fromJson(Map<String, dynamic> json) =>
      DocumentoVehiculo(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        nombre: json["nombre"],
        numeroDoc: json["numero_doc"],
        estado: json["estado"],
        fechaVencimiento: json["fecha_vencimiento"],
        tipoDoc: json["tipo_doc"],
        estadoDescripcion: json["estado_descripcion"],
        documento: json["documento"],
        idDocOpenVehi: json["idDocOpenVehi"],
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "nombre": nombre,
        "numero_doc": numeroDoc,
        "estado": estado,
        "fecha_vencimiento": fechaVencimiento,
        "tipo_doc": tipoDoc,
        "estado_descripcion": estadoDescripcion,
        "documento": documento,
        "idDocOpenVehi": idDocOpenVehi,
      };
}
