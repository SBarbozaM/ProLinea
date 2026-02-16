import 'dart:convert';

AuthUsuario authUsuarioFromJson(String str) => AuthUsuario.fromJson(json.decode(str));

String authUsuarioToJson(AuthUsuario data) => json.encode(data.toJson());

class AuthUsuario {
  String rpta;
  String mensaje;
  String tipoDoc;
  String numDoc;
  List<AuthAccione> authAcciones;

  AuthUsuario({
    required this.rpta,
    required this.mensaje,
    required this.tipoDoc,
    required this.numDoc,
    required this.authAcciones,
  });

  factory AuthUsuario.fromJson(Map<String, dynamic> json) => AuthUsuario(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tipoDoc: json["tipoDoc"],
        numDoc: json["numDoc"],
        authAcciones: List<AuthAccione>.from(json["auth_acciones"].map((x) => AuthAccione.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "auth_acciones": List<dynamic>.from(authAcciones.map((x) => x.toJson())),
      };
}

class AuthAccione {
  String id;
  String accion;
  String orden;
  int pendientes;
  String icono;

  AuthAccione({
    required this.id,
    required this.accion,
    required this.orden,
    required this.pendientes,
    required this.icono,
  });

  factory AuthAccione.fromJson(Map<String, dynamic> json) => AuthAccione(
        id: json["id"],
        accion: json["accion"],
        orden: json["orden"],
        pendientes: json["pendientes"],
        icono: json["icono"],
      );

  Map<String, dynamic> toJson() => {"id": id, "accion": accion, "orden": orden, "pendientes": pendientes, "icono": icono};
}
