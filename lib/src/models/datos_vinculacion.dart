class DatosVinculacion {
  DatosVinculacion({
    required this.rpta,
    this.mensaje = "",
    required this.viajeEmp,
    required this.unidadEmp,
    required this.placaEmp,
    required this.fechaEmp,
  });

  String rpta;
  String mensaje;
  String viajeEmp;
  String unidadEmp;
  String placaEmp;
  String fechaEmp;

  factory DatosVinculacion.fromJson(Map<String, dynamic> json) =>
      DatosVinculacion(
        rpta: json["rpta"],
        mensaje: json["mensaje"] ?? "",
        viajeEmp: json["viajeEmp"],
        unidadEmp: json["unidadEmp"],
        placaEmp: json["placaEmp"],
        fechaEmp: json["fechaEmp"],
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "viajeEmp": viajeEmp,
        "unidadEmp": unidadEmp,
        "placaEmp": placaEmp,
        "fechaEmp": fechaEmp,
      };
}
