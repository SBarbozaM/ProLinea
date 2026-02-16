import 'package:equatable/equatable.dart';

class ColaboradorDatos extends Equatable {
  final String paterno;
  final String materno;
  final String nombres;
  final String idEmpresa;
  final String empresa;
  final String idArea;
  final String area;
  final String codigoExterno;
  final String activo;

  const ColaboradorDatos({
    required this.paterno,
    required this.materno,
    required this.nombres,
    required this.idEmpresa,
    required this.empresa,
    required this.idArea,
    required this.area,
    required this.codigoExterno,
    required this.activo,
  });

  static const empty = ColaboradorDatos(
    paterno: "",
    materno: "",
    nombres: "",
    idEmpresa: "",
    empresa: "",
    idArea: "",
    area: "",
    codigoExterno: "",
    activo: "",
  );

  factory ColaboradorDatos.fromJson(Map<String, dynamic> json) => ColaboradorDatos(
        paterno: json["paterno"],
        materno: json["materno"],
        nombres: json["nombres"],
        idEmpresa: json["idEmpresa"],
        empresa: json["empresa"],
        idArea: json["idArea"],
        area: json["area"],
        codigoExterno: json["codigoExterno"],
        activo: json["activo"],
      );

  Map<String, dynamic> toJson() => {
        "paterno": paterno,
        "materno": materno,
        "nombres": nombres,
        "idEmpresa": idEmpresa,
        "Empresa": empresa,
        "idArea": idArea,
        "Area": area,
        "codigoExterno": codigoExterno,
        "activo": activo,
      };

  @override
  List<Object?> get props => [
        paterno,
        materno,
        nombres,
        idEmpresa,
        empresa,
        idArea,
        area,
        codigoExterno,
        activo,
      ];
}
