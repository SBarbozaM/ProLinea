class ControlSalida {
  String rpta = "";
  String mensaje = "";
  String errorConductor = "";
  String errorUnidad = "";
  int cantDocConductor = 0;
  int cantDocUnidad = 0;
  int idControl = 0;

  ControlSalida();

  ControlSalida.fromJsonMap(Map<String, dynamic> json) {
    rpta = json["rpta"];
    mensaje = json["mensaje"];
    errorConductor = json["errorConductor"];
    errorUnidad = json["errorUnidad"];
    cantDocConductor = json["cantDocConductor"];
    cantDocUnidad = json["cantDocUnidad"];
    idControl = json["idControl"];
  }
}

class DocumentosValidar {
  String titulo = "";
  List<String> documentos = [];
  DocumentosValidar();
}

class ControlSalidaUsuario {
  int id;
  String codOperacion;
  String tDoc_Usuario;
  String nDoc_Usuario;
  String tDoc_Conductor;
  String nDoc_Conductor;
  String placa;
  String fecha;
  String obs;
  String correcto;
  int nroViaje;
  String apellidoP;
  String apellidoM;
  String nombre;

  ControlSalidaUsuario({
    required this.id,
    required this.codOperacion,
    required this.tDoc_Usuario,
    required this.nDoc_Usuario,
    required this.tDoc_Conductor,
    required this.nDoc_Conductor,
    required this.placa,
    required this.fecha,
    required this.obs,
    required this.correcto,
    required this.nroViaje,
    required this.apellidoP,
    required this.apellidoM,
    required this.nombre,
  });

  factory ControlSalidaUsuario.fromJson(Map<String, dynamic> json) => ControlSalidaUsuario(
        id: json["id"],
        codOperacion: json["codOperacion"],
        tDoc_Usuario: json["tDoc_Usuario"],
        nDoc_Usuario: json["nDoc_Usuario"],
        tDoc_Conductor: json["tDoc_Conductor"],
        nDoc_Conductor: json["nDoc_Conductor"],
        placa: json["placa"],
        fecha: json["fecha"],
        obs: json["obs"],
        correcto: json["correcto"],
        nroViaje: json["nroViaje"],
        apellidoP: json["apellidoP"],
        apellidoM: json["apellidoM"],
        nombre: json["nombre"],
      );
}
