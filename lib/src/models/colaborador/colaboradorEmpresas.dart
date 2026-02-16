// To parse this JSON data, do
//
//     final colaboradorEmpresas = colaboradorEmpresasFromJson(jsonString);

import 'package:equatable/equatable.dart';

class ColaboradorEmpresas extends Equatable {
  String id;
  String nombre;

  ColaboradorEmpresas({
    required this.id,
    required this.nombre,
  });

  factory ColaboradorEmpresas.fromJson(Map<String, dynamic> json) => ColaboradorEmpresas(
        id: json["id"],
        nombre: json["nombre"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
      };

  @override
  List<Object?> get props => [id, nombre];
}
