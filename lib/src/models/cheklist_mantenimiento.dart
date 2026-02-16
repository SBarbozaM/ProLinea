class ChecklistMantenimiento {
  String rpta = "";
  String mensaje = "";
  List<ListaCheck> listaCheck = [];

  ChecklistMantenimiento();

  ChecklistMantenimiento.constructor({
    required this.rpta,
    required this.mensaje,
    required this.listaCheck,
  });

  factory ChecklistMantenimiento.fromJson(Map<String, dynamic> json) => ChecklistMantenimiento.constructor(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        listaCheck: List<ListaCheck>.from(json["listaCheck"].map((x) => ListaCheck.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "listaCheck": List<dynamic>.from(listaCheck.map((x) => x.toJson())),
      };
}

class ListaCheck {
  int sCod;
  int orden;
  String trabajo;
  String estado;
  String observacion;
  String atencion;
  int prioridad;

  ListaCheck({
    required this.sCod,
    required this.orden,
    required this.trabajo,
    required this.estado,
    required this.observacion,
    required this.atencion,
    required this.prioridad,
  });

  factory ListaCheck.fromJson(Map<String, dynamic> json) => ListaCheck(
        sCod: json["sCod"],
        orden: json["orden"],
        trabajo: json["trabajo"],
        estado: json["estado"],
        observacion: json["observacion"],
        atencion: json["atencion"],
        prioridad: json["prioridad"],
      );

  Map<String, dynamic> toJson() => {
        "sCod": sCod,
        "orden": orden,
        "trabajo": trabajo,
        "estado": estado,
        "observacion": observacion,
        "atencion": atencion,
        "prioridad": prioridad,
      };
}


