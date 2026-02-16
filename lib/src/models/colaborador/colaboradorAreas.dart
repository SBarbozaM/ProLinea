import 'package:equatable/equatable.dart';

class ColaboradorAreas extends Equatable {
  String id;
  String nombre;

  ColaboradorAreas({
    required this.id,
    required this.nombre,
  });

  factory ColaboradorAreas.fromJson(Map<String, dynamic> json) => ColaboradorAreas(
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
