class RespuestaMensaje {
  String rpta = "";
  String mensaje = "";

  RespuestaMensaje();

  RespuestaMensaje.fromJsonMap(Map<String, dynamic> json) {
    rpta = json['rpta'];
    mensaje = json['mensaje'];
  }
}
