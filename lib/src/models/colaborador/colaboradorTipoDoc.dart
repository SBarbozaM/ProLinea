import 'package:equatable/equatable.dart';

class ColaboradorTipoDoc extends Equatable {
  String codigo;
  String nombre;

  ColaboradorTipoDoc({
    required this.codigo,
    required this.nombre,
  });

  factory ColaboradorTipoDoc.fromJson(Map<String, dynamic> json) => ColaboradorTipoDoc(
        codigo: json["codigo"],
        nombre: json["nombre"],
      );

  Map<String, dynamic> toJson() => {
        "codigo": codigo,
        "nombre": nombre,
      };

  @override
  List<Object?> get props => [codigo, nombre];
}
