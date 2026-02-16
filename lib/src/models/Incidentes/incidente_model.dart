import 'dart:convert';

class Incidente {
  final String id;
  final String titulo;
  final String tipoNoti;
  final String contenido;
  final String url;
  final String tituloWeb;
  final String fecha;
  final String color;
  final String icono;
  final int idTipo;

  Incidente({
    required this.id,
    required this.titulo,
    required this.tipoNoti,
    required this.contenido,
    required this.url,
    required this.tituloWeb,
    required this.fecha,
    required this.color,
    required this.icono,
    required this.idTipo
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      id: json['id'],
      titulo: json['titulo'] ?? 'Sin título',
      tipoNoti: json['tipoNoti'] ?? 'Sin tipo',
      contenido: json['contenido'] ?? 'Sin contenido',
      url: json['url'] ?? '',
      tituloWeb: json['tituloWeb'] ?? '',
      fecha: json['fecha'] ?? '',
      color: json['color'] ?? '',
      icono: json['icono'] ?? '',
      idTipo: json['idTipo'] ?? 0
    );
  }
}
