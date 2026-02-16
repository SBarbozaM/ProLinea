class OsTrabajosUnidad {
  String rpta = "";
  String mensaje = "";
  List<OsTrabajos> lista = [];

  OsTrabajosUnidad.constructor();

  OsTrabajosUnidad({
    required this.rpta,
    required this.mensaje,
    required this.lista,
  });

  factory OsTrabajosUnidad.fromJson(Map<String, dynamic> json) => OsTrabajosUnidad(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        lista: List<OsTrabajos>.from(json["lista"].map((x) => OsTrabajos.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "lista": List<dynamic>.from(lista.map((x) => x.toJson())),
      };
}

class OsTrabajos {
  int codTrabajo;
  String trabajo;
  String codResponsable;
  String nombre;
  String fechaIni;
  String horaIni;
  String fechaFin;
  String horaFin;
  bool estado;
  String observacion;
  int codProgramacion;
  int codTv;
  int codTipoGasto;
  int codOs;
  int pendiente;
  int delete;

  OsTrabajos({
    required this.codTrabajo,
    required this.trabajo,
    required this.codResponsable,
    required this.nombre,
    required this.fechaIni,
    required this.horaIni,
    required this.fechaFin,
    required this.horaFin,
    required this.estado,
    required this.observacion,
    required this.codProgramacion,
    required this.codTv,
    required this.codTipoGasto,
    required this.codOs,
    required this.pendiente,
    required this.delete,
  });

  factory OsTrabajos.fromJson(Map<String, dynamic> json) => OsTrabajos(
        codTrabajo: json["codTrabajo"],
        trabajo: json["trabajo"],
        codResponsable: json["codResponsable"],
        nombre: json["nombre"],
        fechaIni: json["fechaIni"]!,
        horaIni: json["horaIni"]!,
        fechaFin: json["fechaFin"]!,
        horaFin: json["horaFin"]!,
        estado: json["estado"],
        observacion: json["observacion"],
        codProgramacion: json["codProgramacion"],
        codTv: json["codTV"],
        codTipoGasto: json["codTipoGasto"],
        codOs: json["codOS"],
        pendiente: json["pendiente"],
        delete: json["delete"],
      );

  Map<String, dynamic> toJson() => {
        "codTrabajo": codTrabajo,
        "trabajo": trabajo,
        "codResponsable": codResponsable,
        "nombre": nombre,
        "fechaIni": fechaIni,
        "horaIni": horaIni,
        "fechaFin": fechaFin,
        "horaFin": horaFin,
        "estado": estado,
        "observacion": observacion,
        "codProgramacion": codProgramacion,
        "codTV": codTv,
        "codTipoGasto": codTipoGasto,
        "codOS": codOs,
        "pendiente": pendiente,
        "delete": delete,
      };
}
