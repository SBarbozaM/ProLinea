class LoggerModel {
  int? id;
  String idDispositivo;
  String numDoc;
  String codOperacion;
  String fecha;
  String accion;
  String estado;

  LoggerModel({
    this.id,
    required this.idDispositivo,
    required this.numDoc,
    required this.codOperacion,
    required this.fecha,
    required this.accion,
    required this.estado,
  });

  factory LoggerModel.fromJson(Map<String, dynamic> json) => LoggerModel(
        id: json["ID"] ?? 0,
        idDispositivo: json["ID_Dispositivo"] ?? '',
        numDoc: json["NumDoc"] ?? '',
        codOperacion: json["CodOperacion"] ?? '',
        fecha: json["Fecha"] ?? '',
        accion: json["Accion"] ?? '',
        estado: json["Estado"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "ID_Dispositivo": "${idDispositivo}",
        "NumDoc": "${numDoc}",
        "CodOperacion": codOperacion,
        "Fecha": "${fecha}",
        "Accion": accion,
        "Estado": estado,
      };
}
