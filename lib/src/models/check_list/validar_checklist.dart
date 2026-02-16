class ValidarCheckList {
  final String rpta;
  final String mensaje;
  final String tipoChecklist;
  final int nroViaje;
  final String descVehiculo;
  final String codVehiculo;
  final int hoseCodigo;
  final String hoseRegistro;
  final int maxSizeFiles;
  final int maxFiles;

  const ValidarCheckList({required this.rpta, required this.mensaje, required this.tipoChecklist, required this.nroViaje, required this.descVehiculo, required this.codVehiculo, required this.hoseCodigo, required this.hoseRegistro, required this.maxSizeFiles, required this.maxFiles});

  static const ValidarCheckList empty = ValidarCheckList(rpta: "", mensaje: "", nroViaje: 0, tipoChecklist: "", descVehiculo: "", codVehiculo: "", hoseRegistro: "", hoseCodigo: 0, maxSizeFiles: 0, maxFiles: 0);

  factory ValidarCheckList.fromJson(Map<String, dynamic> json) => ValidarCheckList(rpta: json["rpta"], mensaje: json["mensaje"], tipoChecklist: json["tipoChecklist"], nroViaje: json["nroViaje"], descVehiculo: json["descVehiculo"], codVehiculo: json["codVehiculo"], hoseCodigo: json["hoseCodigo"], hoseRegistro: json["hoseRegistro"], maxSizeFiles: json["maxSizeFiles"], maxFiles: json["maxFiles"]);
}
