class Usuario {
  //int? id = 0;
  String? rpta;
  String mensaje = "";
  String tipoDoc = "";
  String numDoc = "";
  String clave = "";
  String apellidoPat = "";
  String apellidoMat = "";
  String nombres = "";
  String perfil = "";
  String codOperacion = "";
  String viajeEmp = "";
  String unidadEmp = "";
  String placaEmp = "";
  String fechaEmp = "";
  String? Log = "";
  String? claveMaestra = "";
  String domicilio = "";
  String nombreOperacion = "";
  String vinculacionActiva = "0";
  String sesionActiva = "0"; //0: sesion no activa //1: sesionActiva
  String sesionSincronizada = "0"; //0: sincronizado // 1: no sincronizado usuario
  String logSincronizado = "0"; //0: log sincronizando // 1: log no sincronizado
  String idPerfil = "";
  List<AccionId> accionesId = [];
  List<String> acciones = [];
  String? equipo = "";
  String? usuarioId = "0";
  int? tipoListSelected = 0;

  Usuario({required this.tipoDoc, required this.numDoc, required this.rpta, required this.clave, required this.apellidoPat, required this.apellidoMat, required this.nombres, required this.perfil, required this.nombreOperacion, required this.codOperacion, this.Log, this.equipo, this.claveMaestra, this.usuarioId, this.tipoListSelected});

  Usuario.empty();

  Usuario.fromJsonMap(Map<String, dynamic> json) {
    rpta = json['rpta'] ?? '';
    mensaje = json['mensaje'] ?? '';
    tipoDoc = json['tipoDoc'] ?? '';
    numDoc = json['numDoc'] ?? '';
    usuarioId = json["idUsuario"] == null ? '0' : json["idUsuario"].toString();
    apellidoPat = json['apellidoPat'] ?? '';
    apellidoMat = json['apellidoMat'] ?? '';
    nombres = json['nombres'] ?? '';
    perfil = json['perfil'] ?? '';
    codOperacion = json['codOperacion'] ?? '';
    nombreOperacion = json['nombreOperacion'] ?? '';
    viajeEmp = json['viajeEmp'] ?? '';
    unidadEmp = json['unidadEmp'] ?? '';
    placaEmp = json['placaEmp'] ?? '';
    fechaEmp = json['fechaEmp'] ?? '';
    domicilio = json['domicilio'] ?? '';
    idPerfil = json["idperfil"] == null ? '' : json["idperfil"].toString();
    vinculacionActiva = (json['viajeEmp'] ?? '') == '' ? '0' : '1';

    Log = json["log"] ?? '';
    equipo = json["equipo"] ?? "";
    claveMaestra = json["claveMaestra"] ?? '';

    var accionesJson = json['acciones'] as List;

    if (accionesJson.isNotEmpty) {
      for (var i = 0; i < accionesJson.length; i++) {
        acciones.add(accionesJson[i]['accion']);
      }
    }
  }

  Usuario.fromJsonMapLocal(Map<String, dynamic> json) {
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    apellidoPat = json['apellidoPat'];
    apellidoMat = json['apellidoMat'];
    nombres = json['nombres'];
    perfil = json['perfil'];
    codOperacion = json['codOperacion'];
  }

  Usuario.fromJsonBDLocal(Map<String, dynamic> json) {
    tipoDoc = json['tipoDoc'];
    numDoc = json['numDoc'];
    usuarioId = json["idUsuario"] == null ? '0' : json["idUsuario"].toString();
    apellidoPat = json['apellidoPat'];
    apellidoMat = json['apellidoMat'];
    nombres = json['nombres'];
    perfil = json['perfil'];
    codOperacion = json['codOperacion'];
    viajeEmp = json['viajeEmp'];
    unidadEmp = json['unidadEmp'];
    placaEmp = json['placaEmp'];
    fechaEmp = json['fechaEmp'];
    domicilio = json['domicilio'];
    idPerfil = json["idperfil"].toString();
    vinculacionActiva = json["vinculacionActiva"].toString();
    sesionActiva = json["sesionActiva"].toString();
    sesionSincronizada = json["sesionSincronizada"].toString();
    logSincronizado = json["logSincronizado"].toString();
    Log = json["Log"].toString();
    equipo = json["equipo"].toString();
    claveMaestra = json["claveMaestra"].toString();
  }

  Map<String, dynamic> toMapDatabase() {
    return {
      //'id': id,
      'tipoDoc': tipoDoc.trim(),
      'numDoc': numDoc.trim(),
      'usuarioId': usuarioId,
      'apellidoPat': apellidoPat,
      'apellidoMat': apellidoMat,
      'nombres': nombres,
      'perfil': perfil,
      'codOperacion': codOperacion,
      'nombreOperacion': nombreOperacion,
      'viajeEmp': viajeEmp,
      "unidadEmp": unidadEmp,
      "placaEmp": placaEmp,
      "fechaEmp": fechaEmp,
      "domicilio": domicilio,
      "idperfil": idPerfil,
      "vinculacionActiva": vinculacionActiva,
      "sesionActiva": sesionActiva,
      "sesionSincronizada": sesionSincronizada,
      "logSincronizado": logSincronizado,
      "Log": Log,
      "equipo": equipo,
      "claveMaestra": claveMaestra,
    };
  }
}
class AccionId {
  final String accion;
  final int id;

  AccionId({
    required this.accion,
    required this.id,
  });
}
