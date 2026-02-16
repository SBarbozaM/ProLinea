class ValidarEditCheckList {
  String rpta = "";
  String mensaje = "";
  List<HojaServicio> listaCheck = [];

  ValidarEditCheckList({
    required this.rpta,
    required this.mensaje,
    required this.listaCheck,
  });

  ValidarEditCheckList.empty();

  factory ValidarEditCheckList.fromJson(Map<String, dynamic> json) => ValidarEditCheckList(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        listaCheck: List<HojaServicio>.from(json["listaCheck"].map((x) => HojaServicio.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "listaCheck": List<dynamic>.from(listaCheck.map((x) => x.toJson())),
      };
}

class HojaServicio {
  int hosECodigo;
  int viaJNroViaje;
  String perSTdoc;
  String perSNdoc;
  int iteMAlta;
  int iteMMedia;
  int iteMBaja;
  String coDVehiculo;
  String tipo;
  String feCRep;

  HojaServicio({
    required this.hosECodigo,
    required this.viaJNroViaje,
    required this.perSTdoc,
    required this.perSNdoc,
    required this.iteMAlta,
    required this.iteMMedia,
    required this.iteMBaja,
    required this.coDVehiculo,
    required this.tipo,
    required this.feCRep,
  });

  factory HojaServicio.fromJson(Map<String, dynamic> json) => HojaServicio(
        hosECodigo: json["hosE_Codigo"],
        viaJNroViaje: json["viaJ_Nro_Viaje"],
        perSTdoc: json["perS_TDOC"],
        perSNdoc: json["perS_NDOC"],
        iteMAlta: json["iteM_ALTA"],
        iteMMedia: json["iteM_MEDIA"],
        iteMBaja: json["iteM_BAJA"],
        coDVehiculo: json["coD_VEHICULO"],
        tipo: json["tipo"],
        feCRep: json["feC_REP"],
      );

  Map<String, dynamic> toJson() => {
        "hosE_Codigo": hosECodigo,
        "viaJ_Nro_Viaje": viaJNroViaje,
        "perS_TDOC": perSTdoc,
        "perS_NDOC": perSNdoc,
        "iteM_ALTA": iteMAlta,
        "iteM_MEDIA": iteMMedia,
        "iteM_BAJA": iteMBaja,
        "coD_VEHICULO": coDVehiculo,
        "tipo": tipo,
        "feC_REP": feCRep,
      };
}
