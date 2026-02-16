import 'dart:ffi';

import 'package:flutter/material.dart';

class CheckListModel {
  String rpta = "";
  String mensaje = "";
  List<CheckList> listaCheck = [];

  CheckListModel({
    required this.rpta,
    required this.mensaje,
    required this.listaCheck,
  });

  CheckListModel.empty();

  factory CheckListModel.fromJson(Map<String, dynamic> json) => CheckListModel(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        listaCheck: List<CheckList>.from(
          json["listaCheck"].map(
            (x) => CheckList.fromJson(x),
          ),
        ),
      );
}

class CheckList {
  String sCod;
  String orden;
  String trabajo;
  String estado;
  String observacion;
  String atencion;
  String prioridad;
  String hosECODIGO;
  String dehSCodigo;
  List<Recurso> recursos;
  int ope_Id;
  bool obligatorio;
  int tipoCheckList;
  //---------------------
  int estadolike = 0; //0: inicial, 1:like , 2:no Like
  bool guardado = false;

  String grupos = "";

  CheckList({
    required this.sCod,
    required this.orden,
    required this.trabajo,
    required this.estado,
    required this.observacion,
    required this.atencion,
    required this.prioridad,
    required this.hosECODIGO,
    required this.dehSCodigo,
    required this.obligatorio,
    required this.ope_Id,
    required this.tipoCheckList,
    required this.recursos,
    this.estadolike = 0,
    this.guardado = false,
  });

  factory CheckList.fromJson(Map<String, dynamic> json) => CheckList(
      sCod: json["sCod"],
      orden: json["orden"],
      trabajo: json["trabajo"],
      estado: json["estado"],
      estadolike: int.parse(json["estado"]),
      guardado: json["dehS_Codigo"] != "0" ? true : false,
      observacion: json["observacion"],
      atencion: json["atencion"],
      prioridad: json["prioridad"],
      hosECODIGO: json["hosE_CODIGO"],
      dehSCodigo: json["dehS_Codigo"],
      recursos: List<Recurso>.from(json["recursos"].map((x) => Recurso.fromJson(x))),
      obligatorio: json["obligatorio"] != null ? json["obligatorio"] : false,
      ope_Id: json["ope_Id"] != null ? json["ope_Id"] : 0,
      tipoCheckList: json["tipoCheckList"] != null ? json["tipoCheckList"] : 0);
}

class Recurso {
  String dehSCodigo;
  String viaJNroViaje;
  String redehSArchivo;
  String redehSTipoArchivo;
  String redehSFechaRegistrada;

  Recurso({
    required this.dehSCodigo,
    required this.viaJNroViaje,
    required this.redehSArchivo,
    required this.redehSTipoArchivo,
    required this.redehSFechaRegistrada,
  });

  factory Recurso.fromJson(Map<String, dynamic> json) => Recurso(
        dehSCodigo: json["dehS_Codigo"],
        viaJNroViaje: json["viaJ_Nro_Viaje"],
        redehSArchivo: json["redehS_Archivo"],
        redehSTipoArchivo: json["redehS_TipoArchivo"],
        redehSFechaRegistrada: json["redehS_FechaRegistrada"],
      );

  Map<String, dynamic> toJson() => {
        "dehS_Codigo": dehSCodigo,
        "viaJ_Nro_Viaje": viaJNroViaje,
        "redehS_Archivo": redehSArchivo,
        "redehS_TipoArchivo": redehSTipoArchivo,
        "redehS_FechaRegistrada": redehSFechaRegistrada,
      };
}

class TipoCheckListModel {
  String rpta = "";
  String mensaje = "";
  List<TipoCheckList> listaTipoCheck = [];

  TipoCheckListModel();

  TipoCheckListModel.constructor({
    required this.rpta,
    required this.mensaje,
    required this.listaTipoCheck,
  });
  TipoCheckListModel.empty();
  factory TipoCheckListModel.fromJson(Map<String, dynamic> json) => TipoCheckListModel.constructor(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        listaTipoCheck: List<TipoCheckList>.from(json["listaTipoCheck"].map((x) => TipoCheckList.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "listaCheck": List<dynamic>.from(listaTipoCheck.map((x) => x.toJson())),
      };
}

class TipoCheckList {
  int codigo;
  String tipo;
  String ico;

  TipoCheckList({required this.codigo, required this.tipo, required this.ico});

  factory TipoCheckList.fromJson(Map<String, dynamic> json) => TipoCheckList(
        codigo: json["codigo"],
        tipo: json["tipo"],
        ico: json["ico"],
      );

  Map<String, dynamic> toJson() => {
        "codigo": codigo,
        "tipo": tipo,
        "ico": ico,
      };
}
