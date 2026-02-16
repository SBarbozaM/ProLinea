// To parse this JSON data, do
//
//     final detailDocModel = detailDocModelFromJson(jsonString);

import 'dart:convert';

DetailDocModel detailDocModelFromJson(String str) => DetailDocModel.fromJson(json.decode(str));

String detailDocModelToJson(DetailDocModel data) => json.encode(data.toJson());

class DetailDocModel {
    String rpta;
    String mensaje;
    String tipoDoc;
    String numDoc;
    String pkOrden;
    String tipoDocOrden;
    List<AuthDetail> authDetail;

    DetailDocModel({
        required this.rpta,
        required this.mensaje,
        required this.tipoDoc,
        required this.numDoc,
        required this.pkOrden,
        required this.tipoDocOrden,
        required this.authDetail,
    });

    factory DetailDocModel.fromJson(Map<String, dynamic> json) => DetailDocModel(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tipoDoc: json["tipoDoc"],
        numDoc: json["numDoc"],
        pkOrden: json["pkOrden"],
        tipoDocOrden: json["tipoDocOrden"],
        authDetail: List<AuthDetail>.from(json["auth_Detail"].map((x) => AuthDetail.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "pkOrden": pkOrden,
        "tipoDocOrden": tipoDocOrden,
        "auth_Detail": List<dynamic>.from(authDetail.map((x) => x.toJson())),
    };
}

class AuthDetail {
    String pkDetalleOrden;
    String fkItem;
    int cantidad;
    double precio;
    double precioVenta;
    String descuento;
    String fkCentro;
    String fkOrdenServicio;
    String observacion;
    String fkOrden;
    String descProd;
    String nombre;
    String descripcion;
    String afecto;
    String varDsc;

    AuthDetail({
        required this.pkDetalleOrden,
        required this.fkItem,
        required this.cantidad,
        required this.precio,
        required this.precioVenta,
        required this.descuento,
        required this.fkCentro,
        required this.fkOrdenServicio,
        required this.observacion,
        required this.fkOrden,
        required this.descProd,
        required this.nombre,
        required this.descripcion,
        required this.afecto,
        required this.varDsc,
    });

    factory AuthDetail.fromJson(Map<String, dynamic> json) => AuthDetail(
        pkDetalleOrden: json["pkDetalleOrden"],
        fkItem: json["fkItem"],
        cantidad: json["cantidad"],
        precio: json["precio"]?.toDouble(),
        precioVenta: json["precioVenta"]?.toDouble(),
        descuento: json["descuento"],
        fkCentro: json["fkCentro"],
        fkOrdenServicio: json["fkOrdenServicio"],
        observacion: json["observacion"],
        fkOrden: json["fkOrden"],
        descProd: json["descProd"],
        nombre: json["nombre"],
        descripcion: json["descripcion"],
        afecto: json["afecto"],
        varDsc: json["varDsc"],
    );

    Map<String, dynamic> toJson() => {
        "pkDetalleOrden": pkDetalleOrden,
        "fkItem": fkItem,
        "cantidad": cantidad,
        "precio": precio,
        "precioVenta": precioVenta,
        "descuento": descuento,
        "fkCentro": fkCentro,
        "fkOrdenServicio": fkOrdenServicio,
        "observacion": observacion,
        "fkOrden": fkOrden,
        "descProd": descProd,
        "nombre": nombre,
        "descripcion": descripcion,
        "afecto": afecto,
        "varDsc": varDsc,
    };
}
