// models/Autorizaciones/backo/RespuestaAccion.dart
class RespuestaAccion {
  final bool resultado;
  final String mensaje;
  final int? data;
  final String? codigoError;
  final bool email;

  RespuestaAccion({
    required this.resultado,
    required this.mensaje,
    this.data,
    this.codigoError,
    required this.email,
  });

  factory RespuestaAccion.fromJson(Map<String, dynamic> json) {
    return RespuestaAccion(
      resultado: json['resultado'] ?? false,
      mensaje: json['mensaje'] ?? '',
      data: json['data'] as int?,
      codigoError: json['codigoError'],
      email: json['email'] ?? false,
    );
  }
}