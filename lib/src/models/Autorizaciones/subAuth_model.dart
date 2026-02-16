import 'dart:convert';

SubAuthUsuarioModel subAuthUsuarioModelFromJson(String str) => SubAuthUsuarioModel.fromJson(json.decode(str));

String subAuthUsuarioModelToJson(SubAuthUsuarioModel data) => json.encode(data.toJson());

class SubAuthUsuarioModel {
    String rpta;
    String mensaje;
    String tipoDoc;
    String numDoc;
    int idAuth;
    List<AuthSubAccione> authSubAcciones;

    SubAuthUsuarioModel({
        required this.rpta,
        required this.mensaje,
        required this.tipoDoc,
        required this.numDoc,
        required this.idAuth,
        required this.authSubAcciones,
    });

    factory SubAuthUsuarioModel.fromJson(Map<String, dynamic> json) => SubAuthUsuarioModel(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tipoDoc: json["tipoDoc"],
        numDoc: json["numDoc"],
        idAuth: json["idAuth"],
        authSubAcciones: List<AuthSubAccione>.from(json["auth_sub_acciones"].map((x) => AuthSubAccione.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "idAuth": idAuth,
        "auth_sub_acciones": List<dynamic>.from(authSubAcciones.map((x) => x.toJson())),
    };
}

class AuthSubAccione {
    String id;
    String accion;
    String orden;
    String icono;

    AuthSubAccione({
        required this.id,
        required this.accion,
        required this.orden,
        required this.icono,
        
    });

    factory AuthSubAccione.fromJson(Map<String, dynamic> json) => AuthSubAccione(
        id: json["id"],
        accion: json["accion"],
        orden: json["orden"],
        icono: json["icono"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "accion": accion,
        "orden": orden,
        "icono": icono,
    };
}
