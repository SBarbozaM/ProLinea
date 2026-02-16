class OsObtenerTaller {
  String rpta = "";
  String mensaje = "";
  String tallerCodigo = "";

  OsObtenerTaller.constructor();

  OsObtenerTaller({
    required this.rpta,
    required this.mensaje,
    required this.tallerCodigo,
  });

  factory OsObtenerTaller.fromJson(Map<String, dynamic> json) => OsObtenerTaller(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tallerCodigo: json["tallerCordigo"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tallerCordigo": tallerCodigo,
      };
}
