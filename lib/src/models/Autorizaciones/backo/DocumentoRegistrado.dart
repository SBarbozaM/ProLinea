// models/Autorizaciones/backo/DocumentoRegistrado.dart
class DocumentoRegistrado {
  final int id;
  final String codigo;
  final int empresaId;
  final String empresa;
  final String sede;
  final String despacho;
  final String area;
  final String solicitante;
  final String fechaSolicitud;
  final String fechaRequerida;
  final String motivo;
  final String observacion;
  final String estado;
  final String estadoColor;
  final String estadoCodigo;
  final String? ordenServicio;
  final bool sincronizado;
  final String almacen;
  final String fechaSincronizacion;
  final int almacenId;

  DocumentoRegistrado({
    required this.id,
    required this.codigo,
    required this.empresaId,
    required this.empresa,
    required this.sede,
    required this.despacho,
    required this.area,
    required this.solicitante,
    required this.fechaSolicitud,
    required this.fechaRequerida,
    required this.motivo,
    required this.observacion,
    required this.estado,
    required this.estadoColor,
    required this.estadoCodigo,
    this.ordenServicio,
    required this.sincronizado,
    required this.almacen,
    required this.fechaSincronizacion,
    required this.almacenId,
  });

  factory DocumentoRegistrado.fromJson(Map<String, dynamic> json) {
    return DocumentoRegistrado(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      empresaId: json['empresa_Id'] ?? 0,
      empresa: json['empresa'] ?? '',
      sede: json['sede'] ?? '',
      despacho: json['despacho'] ?? '',
      area: json['area'] ?? '',
      solicitante: json['solicitante'] ?? '',
      fechaSolicitud: json['fechaSolicitud'] ?? '',
      fechaRequerida: json['fechaRequerida'] ?? '',
      motivo: json['motivo'] ?? '',
      observacion: json['observacion'] ?? '',
      estado: json['estado'] ?? '',
      estadoColor: json['estadoColor'] ?? '',
      estadoCodigo: json['estado_Codigo'] ?? '',
      ordenServicio: json['orden_servicio'],
      sincronizado: json['sincronizado'] ?? false,
      almacen: json['almacen'] ?? '',
      fechaSincronizacion: json['fechaSincronizacion'] ?? '',
      almacenId: json['almacenId'] ?? 0,
    );
  }
}