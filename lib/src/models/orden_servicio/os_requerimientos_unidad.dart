class OsRequerimientosUnidad {
  String rpta = "";
  String mensaje = "";
  List<OsRequerimientos> lista = [];

  OsRequerimientosUnidad.constructor();

  OsRequerimientosUnidad({
    required this.rpta,
    required this.mensaje,
    required this.lista,
  });

  factory OsRequerimientosUnidad.fromJson(Map<String, dynamic> json) => OsRequerimientosUnidad(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        lista: List<OsRequerimientos>.from(json["lista"].map((x) => OsRequerimientos.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "lista": List<dynamic>.from(lista.map((x) => x.toJson())),
      };
}

class OsRequerimientos {
  String trabajoVerificacion;
  String ultimoReporte;
  int codTra;
  int cantReport;
  int codTv;
  String fechaI;
  String fechaF;
  String prioridad;
  int codIni;
  int codFin;
  String estIni;
  String estFin;
  String obsv;
  String prog;
  String usuarioProg;
  String detPro;
  String detProTipo;
  String pro;
  String tipo;
  int codHsIni;
  int codHsFin;
  String responsable;
  int codPm;
  int cambiar;
  bool selecionado = false;

  OsRequerimientos({
    required this.trabajoVerificacion,
    required this.ultimoReporte,
    required this.codTra,
    required this.cantReport,
    required this.codTv,
    required this.fechaI,
    required this.fechaF,
    required this.prioridad,
    required this.codIni,
    required this.codFin,
    required this.estIni,
    required this.estFin,
    required this.obsv,
    required this.prog,
    required this.usuarioProg,
    required this.detPro,
    required this.detProTipo,
    required this.pro,
    required this.tipo,
    required this.codHsIni,
    required this.codHsFin,
    required this.responsable,
    required this.codPm,
    required this.cambiar,
  });

  factory OsRequerimientos.fromJson(Map<String, dynamic> json) => OsRequerimientos(
        trabajoVerificacion: json["trabajoVerificacion"],
        ultimoReporte: json["ultimoReporte"],
        codTra: json["codTra"],
        cantReport: json["cantReport"],
        codTv: json["codTV"],
        fechaI: json["fechaI"],
        fechaF: json["fechaF"],
        prioridad: json["prioridad"],
        codIni: json["codIni"],
        codFin: json["codFin"],
        estIni: json["estIni"],
        estFin: json["estFin"],
        obsv: json["obsv"],
        prog: json["prog"],
        usuarioProg: json["usuarioProg"],
        detPro: json["detPro"],
        detProTipo: json["detProTipo"],
        pro: json["pro"],
        tipo: json["tipo"],
        codHsIni: json["codHSIni"],
        codHsFin: json["codHSFin"],
        responsable: json["responsable"],
        codPm: json["codPM"],
        cambiar: json["cambiar"],
      );

  Map<String, dynamic> toJson() => {
        "trabajoVerificacion": trabajoVerificacion,
        "ultimoReporte": ultimoReporte,
        "codTra": codTra,
        "cantReport": cantReport,
        "codTV": codTv,
        "fechaI": fechaI,
        "fechaF": fechaF,
        "prioridad": prioridad,
        "codIni": codIni,
        "codFin": codFin,
        "estIni": estIni,
        "estFin": estFin,
        "obsv": obsv,
        "prog": prog,
        "usuarioProg": usuarioProg,
        "detPro": detPro,
        "detProTipo": detProTipo,
        "pro": pro,
        "tipo": tipo,
        "codHSIni": codHsIni,
        "codHSFin": codHsFin,
        "responsable": responsable,
        "codPM": codPm,
        "cambiar": cambiar,
      };
}
