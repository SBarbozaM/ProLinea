// models/Autorizaciones/backo/GrupoDocumento.dart
class GrupoDocumento {
  final int documentoId;
  final String documento;
  final List<DetalleDocumento> detalle;

  GrupoDocumento({
    required this.documentoId,
    required this.documento,
    required this.detalle,
  });

  factory GrupoDocumento.fromJson(Map<String, dynamic> json) {
    return GrupoDocumento(
      documentoId: json['documento_Id'] ?? 0,
      documento: json['documento'] ?? '',
      detalle: (json['detalle'] as List<dynamic>?)?.map((e) => DetalleDocumento.fromJson(e)).toList() ?? [],
    );
  }
}

class DetalleDocumento {
  final int id;
  final String motivoMovimiento;
  final String almacen;
  final double totalSoles;
  final String moneda;
  final String proveedor;
  final int documentoId;
  final int nivel;
  final String codigoDocumento;
  final String nombreDocumento;
  final String nombreEmpresa;
  final String solicitanteApellidos;
  final String solicitanteNombres;
  final String fechaSolicitud;
  final String fechaLimite;
  final String descripcionEstado;
  final String colorEstado;
  final String nivelDocumento;
  final String observacion;
  final String docDescripcionCorta;

  DetalleDocumento({
    required this.id,
    required this.motivoMovimiento,
    required this.almacen,
    required this.totalSoles,
    required this.moneda,
    required this.proveedor,
    required this.documentoId,
    required this.nivel,
    required this.codigoDocumento,
    required this.nombreDocumento,
    required this.nombreEmpresa,
    required this.solicitanteApellidos,
    required this.solicitanteNombres,
    required this.fechaSolicitud,
    required this.fechaLimite,
    required this.descripcionEstado,
    required this.colorEstado,
    required this.nivelDocumento,
    required this.observacion,
    required this.docDescripcionCorta,
  });

  factory DetalleDocumento.fromJson(Map<String, dynamic> json) {
    return DetalleDocumento(
      id: json['id'] ?? 0,
      motivoMovimiento: json['motivoMovimiento'] ?? '',
      almacen: json['almacen'] ?? '',
      totalSoles: (json['totalSoles'] ?? 0).toDouble(),
      moneda: json['moneda'] ?? '',
      proveedor: json['proveedor'] ?? '',
      documentoId: json['documento_Id'] ?? 0,
      nivel: json['nivel'] ?? 0,
      codigoDocumento: json['codigoDocumento'] ?? '',
      nombreDocumento: json['nombreDocumento'] ?? '',
      nombreEmpresa: json['nombreEmpresa'] ?? '',
      solicitanteApellidos: json['solicitanteApellidos'] ?? '',
      solicitanteNombres: json['solicitanteNombres'] ?? '',
      fechaSolicitud: json['fechaSolicitud'] ?? '',
      fechaLimite: json['fecha_Limite'] ?? '',
      descripcionEstado: json['descripcion_Estado'] ?? '',
      colorEstado: json['color_Estado'] ?? '',
      nivelDocumento: json['nivelDocumento'] ?? '',
      observacion: json['observacion'] ?? '',
      docDescripcionCorta: json['docDescripcion_Corta'] ?? '',
    );
  }
}
