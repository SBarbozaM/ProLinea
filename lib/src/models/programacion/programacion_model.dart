class ProgramacionModel {
  String rpta;
  String mensaje;
  List<ProgramacionElement> programacion;

  ProgramacionModel({
    required this.rpta,
    required this.mensaje,
    required this.programacion,
  });

  factory ProgramacionModel.fromJson(Map<String, dynamic> json) => ProgramacionModel(
        rpta: json["rpta"],
        mensaje: json["mensaje"],
        programacion: List<ProgramacionElement>.from(json["programacion"].map((x) => ProgramacionElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rpta": rpta,
        "mensaje": mensaje,
        "programacion": List<dynamic>.from(programacion.map((x) => x.toJson())),
      };
}

class ProgramacionElement {
  String bus;
  String ruta;
  String servicio;
  String salida;
  String nombreConductor1;
  String nombreConductor2;
  String nombreAuxiliarViaje;
  String inicio;
  String fin;
  String camino;
  String mapa;
  String h_Salida;
  String h_Llegada;

  bool desplegable = false;

  ProgramacionElement({
    required this.bus,
    required this.ruta,
    required this.servicio,
    required this.salida,
    required this.nombreConductor1,
    required this.nombreConductor2,
    required this.nombreAuxiliarViaje,
    this.inicio = '',
    this.fin = '',
    this.camino = '',
    this.mapa = '',
    this.h_Salida = '',
    this.h_Llegada = '',
  });

  factory ProgramacionElement.fromJson(Map<String, dynamic> json) => ProgramacionElement(
        bus: json["bus"],
        ruta: json["ruta"],
        servicio: json["servicio"],
        salida: json["salida"],
        nombreConductor1: json["nombreConductor1"],
        nombreConductor2: json["nombreConductor2"],
        //nombreConductor2: "Juan Rosas Perez",
        nombreAuxiliarViaje: json["nombreAuxiliarViaje"],
        inicio: json["inicio"]?.toString() ?? '',
        fin: json["fin"]?.toString() ?? '',
        camino: json["camino"]?.toString() ?? '',
        mapa: json["mapa"]?.toString() ?? '',
        h_Salida: json["h_Salida"]?.toString() ?? '',
        h_Llegada: json["h_Llegada"]?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        "bus": bus,
        "ruta": ruta,
        "servicio": servicio,
        "salida": salida,
        "nombreConductor1": nombreConductor1,
        "nombreConductor2": nombreConductor2,
        "nombreAuxiliarViaje": nombreAuxiliarViaje,
        "inicio": inicio,
        "fin": fin,
        "camino": camino,
        "mapa": mapa,
        "h_Salida": h_Salida,
        "h_Llegada": h_Llegada,
      };
}
