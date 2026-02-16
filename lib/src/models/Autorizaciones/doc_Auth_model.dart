// To parse this JSON data, do
//
//     final docAuthModel = docAuthModelFromJson(jsonString);

import 'dart:convert';


DocAuthModel docAuthModelFromJson(String str) => DocAuthModel.fromJson(json.decode(str));

String docAuthModelToJson(DocAuthModel data) => json.encode(data.toJson());

class DocAuthModel {
  int count;
  String rpta;
  String mensaje;
  String tipoDoc;
  String numDoc;
  int idSubAuth;
  List<AuthDoc> authDocs;

  DocAuthModel({
    required this.count,
    required this.rpta,
    required this.mensaje,
    required this.tipoDoc,
    required this.numDoc,
    required this.idSubAuth,
    required this.authDocs,
  });

  factory DocAuthModel.fromJson(Map<String, dynamic> json) => DocAuthModel(
        count: json["count"],
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        tipoDoc: json["tipoDoc"],
        numDoc: json["numDoc"],
        idSubAuth: json["idSubAuth"],
        authDocs: List<AuthDoc>.from(json["auth_Docs"].map((x) => AuthDoc.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "rpta": rpta,
        "mensaje": mensaje,
        "tipoDoc": tipoDoc,
        "numDoc": numDoc,
        "idSubAuth": idSubAuth,
        "auth_Docs": List<dynamic>.from(authDocs.map((x) => x.toJson())),
      };
}

class AuthDoc {
  String pkOrden;
  String tipoDoc;
  String documento;
  String fecha;
  String precioVenta;
  String moneda;
  String tipoPago;
  String motivo;
  String proveedor;
  String beneficiado;
  String canalizador;
  String preAutorizador;
  bool _desplegable = false;
  bool _showFullText = false;

  // Getters y setters para el estado de despliegue
  bool get desplegable => _desplegable;

  set desplegable(bool value) {
    _desplegable = value;
  }

  bool get showFullText => _showFullText;

  set showFullText(bool value) {
    _showFullText = value;
  }

  AuthDoc({
    required this.pkOrden,
    required this.tipoDoc,
    required this.documento,
    required this.fecha,
    required this.precioVenta,
    required this.moneda,
    required this.tipoPago,
    required this.motivo,
    required this.proveedor,
    required this.beneficiado,
    required this.canalizador,
    required this.preAutorizador,
  });

  factory AuthDoc.fromJson(Map<String, dynamic> json) => AuthDoc(
        pkOrden: json["pkOrden"],
        tipoDoc: json["tipoDoc"],
        documento: json["documento"],
        fecha: json["fecha"],
        precioVenta: json["precioVenta"],
        moneda: json["moneda"],
        tipoPago: json["tipoPago"],
        motivo: json["motivo"],
        proveedor: json["proveedor"],
        beneficiado: json["beneficiado"],
        canalizador: json["canalizador"],
        preAutorizador: json["preAutorizador"],
      );

  Map<String, dynamic> toJson() => {
        "pkOrden": pkOrden,
        "tipoDoc": tipoDoc,
        "documento": documento,
        "fecha": fecha,
        "precioVenta": precioVenta,
        "moneda": moneda,
        "tipoPago": tipoPago,
        "motivo": motivo,
        "proveedor": proveedor,
        "beneficiado": beneficiado,
        "canalizador": canalizador,
        "preAutorizador": preAutorizador,
      };
}



// // To parse this JSON data, do
// //
// //     final docAuthModel = docAuthModelFromJson(jsonString);

// import 'dart:convert';

// DocAuthModel docAuthModelFromJson(String str) => DocAuthModel.fromJson(json.decode(str));

// String docAuthModelToJson(DocAuthModel data) => json.encode(data.toJson());

// class DocAuthModel {
//   int count;
//   String rpta;
//   String mensaje;
//   String tipoDoc;
//   String numDoc;
//   int idSubAuth;
//   List<AuthDoc> authDocs;

//   DocAuthModel({
//     required this.count,
//     required this.rpta,
//     required this.mensaje,
//     required this.tipoDoc,
//     required this.numDoc,
//     required this.idSubAuth,
//     required this.authDocs,
//   });

//   factory DocAuthModel.fromJson(Map<String, dynamic> json) => DocAuthModel(
//         count: json["count"],
//         rpta: json["rpta"],
//         mensaje: json["mensaje"],
//         tipoDoc: json["tipoDoc"],
//         numDoc: json["numDoc"],
//         idSubAuth: json["idSubAuth"],
//         authDocs: List<AuthDoc>.from(json["auth_Docs"].map((x) => AuthDoc.fromJson(x))),
//       );

//   Map<String, dynamic> toJson() => {
//         "count": count,
//         "rpta": rpta,
//         "mensaje": mensaje,
//         "tipoDoc": tipoDoc,
//         "numDoc": numDoc,
//         "idSubAuth": idSubAuth,
//         "auth_Docs": List<dynamic>.from(authDocs.map((x) => x.toJson())),
//       };
// }

// class AuthDoc {
//   String pkOrden;
//   String tipoDoc;
//   String documento;
//   String fecha;
//   String moneda;
//   double precioVenta;
//   String motivo;
//   String nombre;
//   String responsable;
//   String pkGrupo;
//   String preAutorizador;
//   String tipoPago;
//   String estado;
//   bool _desplegable = false;
//   bool _showFullText = true;

//   // Getters y setters para el estado de despliegue
//   bool get desplegable => _desplegable;

//   set desplegable(bool value) {
//     _desplegable = value;
//   }

//   bool get showFullText => _showFullText;

//   set showFullText(bool value) {
//     _showFullText = value;
//   }

//   AuthDoc({
//     required this.pkOrden,
//     required this.tipoDoc,
//     required this.documento,
//     required this.fecha,
//     required this.moneda,
//     required this.precioVenta,
//     required this.motivo,
//     required this.nombre,
//     required this.responsable,
//     required this.pkGrupo,
//     required this.preAutorizador,
//     required this.tipoPago,
//     required this.estado,
//   });

//   factory AuthDoc.fromJson(Map<String, dynamic> json) => AuthDoc(
//         pkOrden: json["pkOrden"],
//         tipoDoc: json["tipoDoc"],
//         documento: json["documento"],
//         fecha: json["fecha"],
//         moneda: json["moneda"],
//         precioVenta: json["precioVenta"]?.toDouble(),
//         motivo: json["motivo"],
//         nombre: json["nombre"],
//         responsable: json["responsable"],
//         pkGrupo: json["pkGrupo"],
//         preAutorizador: json["preAutorizador"],
//         tipoPago: json["tipoPago"],
//         estado: json["estado"],
//       );

//   Map<String, dynamic> toJson() => {
//         "pkOrden": pkOrden,
//         "tipoDoc": tipoDoc,
//         "documento": documento,
//         "fecha": fecha,
//         "moneda": moneda,
//         "precioVenta": precioVenta,
//         "motivo": motivo,
//         "nombre": nombre,
//         "responsable": responsable,
//         "pkGrupo": pkGrupo,
//         "preAutorizador": preAutorizador,
//         "tipoPago": tipoPago,
//         "estado": estado,
//       };
// }
