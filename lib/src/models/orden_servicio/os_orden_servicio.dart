class OsOrdenServicio {
  String rpta = "";
  String mensaje = "";
  List<OsOrden> lista = [];

  OsOrdenServicio.constructor();

  OsOrdenServicio({
    required this.rpta,
    required this.mensaje,
    required this.lista,
  });

  factory OsOrdenServicio.fromJson(Map<String, dynamic> json) => OsOrdenServicio(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        lista: List<OsOrden>.from(json["lista"].map((x) => OsOrden.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "lista": List<dynamic>.from(lista.map((x) => x.toJson())),
      };
}

class OsOrden {
  int nro;
  String piloto;
  String fechaEntrada;
  String horaEntrada;
  String estado;
  String codVeh;
  String fechaSalida;
  String horaSalida;
  String tipo;
  int dni;
  int kmMant;
  String descEst;
  int codPro;
  String operacion;
  int codGasto;
  String tipoGasto;
  String taller;
  String codTaller;

  OsOrden({
    required this.nro,
    required this.piloto,
    required this.fechaEntrada,
    required this.horaEntrada,
    required this.estado,
    required this.codVeh,
    required this.fechaSalida,
    required this.horaSalida,
    required this.tipo,
    required this.dni,
    required this.kmMant,
    required this.descEst,
    required this.codPro,
    required this.operacion,
    required this.codGasto,
    required this.tipoGasto,
    required this.taller,
    required this.codTaller,
  });

  factory OsOrden.fromJson(Map<String, dynamic> json) => OsOrden(
        nro: json["nro"],
        piloto: json["piloto"],
        fechaEntrada: json["fechaEntrada"],
        horaEntrada: json["horaEntrada"],
        estado: json["estado"],
        codVeh: json["codVeh"],
        fechaSalida: json["fechaSalida"],
        horaSalida: json["horaSalida"],
        tipo: json["tipo"],
        dni: json["dni"],
        kmMant: json["kmMant"],
        descEst: json["descEst"],
        codPro: json["codPro"],
        operacion: json["operacion"],
        codGasto: json["codGasto"],
        tipoGasto: json["tipoGasto"],
        taller: json["taller"],
        codTaller: json["codTaller"],
      );

  Map<String, dynamic> toJson() => {
        "nro": nro,
        "piloto": piloto,
        "fechaEntrada": fechaEntrada,
        "horaEntrada": horaEntrada,
        "estado": estado,
        "codVeh": codVeh,
        "fechaSalida": fechaSalida,
        "horaSalida": horaSalida,
        "tipo": tipo,
        "dni": dni,
        "kmMant": kmMant,
        "descEst": descEst,
        "codPro": codPro,
        "operacion": operacion,
        "codGasto": codGasto,
        "tipoGasto": tipoGasto,
        "taller": taller,
        "codTaller": codTaller,
      };
}
