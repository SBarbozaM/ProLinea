class Jornada {
  int id = 0;
  String viajNroViaje = "";
  String dehoTurno = "";
  String viajTipoDoc = "";
  String viajNombre = "";
  String viajDni = "";
  String decoInicio = "";
  String decoFin = "";
  String dehoCordenadasInicio = "";
  String dehoCordenadasFin = "";
  String dehoUsuario = "";
  String dehoPc = "";
  String dehoFecha = "";
  String dehoTipo = "";
  String estado = "0";
  String estadobdinicio = ""; // O: SICRONIZADO CON BD, 1: NO SINCRONIZADO BD
  String estadobdfin = ""; // O: SICRONIZADO CON BD, 1: NO SINCRONIZADO BD

  Jornada() {}

  Jornada.constructor({
    required this.id,
    required this.viajNroViaje,
    required this.dehoTurno,
    required this.viajTipoDoc,
    required this.viajNombre,
    required this.viajDni,
    required this.decoInicio,
    required this.decoFin,
    required this.dehoCordenadasInicio,
    required this.dehoCordenadasFin,
    required this.dehoUsuario,
    required this.dehoPc,
    required this.dehoFecha,
    required this.dehoTipo,
    required this.estado,
    required this.estadobdinicio,
    required this.estadobdfin,
  });

  Jornada.fromJson(Map<String, dynamic> json) {
    id = json["ID"];
    viajNroViaje = json["VIAJ_Nro_Viaje"] ?? "";
    dehoTurno = json["DEHO_Turno"] ?? "";
    viajTipoDoc = json["VIAJ_TipoDoc"] ?? "";
    viajNombre = json["VIAJ_NOMBRE"] ?? "";
    viajDni = json["VIAJ_Dni"] ?? "";
    decoInicio = json["DECO_Inicio"] ?? "";
    decoFin = json["DECO_Fin"] ?? "";
    dehoCordenadasInicio = json["DEHO_Corde;adas_Inicio"] ?? "";
    dehoCordenadasFin = json["DEHO_Cordenadas_Fin"] ?? "";
    dehoUsuario = json["DEHO_Usuario"] ?? "";
    dehoPc = json["DEHO_PC"] ?? "";
    dehoFecha = json["DEHO_Fecha"] ?? "";
    dehoTipo = json["DEHO_Tipo"] ?? "";
    estado = json["Estado"] ?? "";
    estadobdinicio = json["EstadoBDInicio"] ?? "";
    estadobdfin = json["EstadoBDFin"] ?? "";
  }

  Map<String, dynamic> toJson() => {
        "VIAJ_Nro_Viaje": viajNroViaje,
        "DEHO_Turno": dehoTurno,
        "VIAJ_TipoDoc": viajTipoDoc,
        "VIAJ_Dni": viajDni,
        "DECO_Inicio": decoInicio,
        "DECO_Fin": decoFin,
        "DEHO_Usuario": dehoUsuario,
        "DEHO_PC": dehoPc,
        "DEHO_Fecha": dehoFecha,
        "DEHO_Tipo": dehoTipo,
        "Estado": estado,
      };
}
