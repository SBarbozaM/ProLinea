class DatosApp {
  //int? id = 0;
  String? rpta = "";
  String id = "";
  String numero_version = "";
  String direccion_url = "";
  String nombreCorto = "";
  String descripcion = "";

  DatosApp();

  DatosApp.fromJsonMap(Map<String, dynamic> json) {
    rpta = json['rpta'];
    numero_version = json['numero_version'];
    direccion_url = json['direccion_url'];
  }
}
