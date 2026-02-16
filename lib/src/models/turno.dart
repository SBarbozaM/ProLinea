class Turno {
  String nroViaje;
  String dehOTurno;
  String viaJDni;
  String dehOInicio;
  String dehOFin;
  String dehOCordenadasInicio;
  String dehOCordenadasFin;

  Turno({
    required this.nroViaje,
    required this.dehOTurno,
    required this.viaJDni,
    required this.dehOInicio,
    required this.dehOFin,
    required this.dehOCordenadasInicio,
    required this.dehOCordenadasFin,
  });

  factory Turno.fromJson(Map<String, dynamic> json) => Turno(
        nroViaje: json["nroViaje"] ?? "",
        dehOTurno: json["dehO_Turno"] ?? "",
        viaJDni: json["viaJ_Dni"] ?? "",
        dehOInicio: json["dehO_Inicio"] ?? "",
        dehOFin: json["dehO_Fin"] ?? "",
        dehOCordenadasInicio: json["dehO_Cordenadas_Inicio"] ?? "",
        dehOCordenadasFin: json["dehO_Cordenadas_Fin"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "nroViaje": nroViaje,
        "dehO_Turno": dehOTurno,
        "viaJ_Dni": viaJDni,
        "dehO_Inicio": dehOInicio,
        "dehO_Fin": dehOFin,
        "dehO_Cordenadas_Inicio": dehOCordenadasInicio,
        "dehO_Cordenadas_Fin": dehOCordenadasFin,
      };
}
