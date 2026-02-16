class ControlAsistencia {
  String rpta;
  String mensaje;
  String hora;

  ControlAsistencia({
    required this.rpta,
    required this.mensaje,
    required this.hora,
  });

  factory ControlAsistencia.fromJson(Map<String, dynamic> json) => ControlAsistencia(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        hora: json["hora"],
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "hora": hora,
      };
}
