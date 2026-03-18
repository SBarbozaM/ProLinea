// models/Autorizaciones/backo/DocumentoDetalleNormalizado.dart
class DocumentoDetalleNormalizado {
  final int id;
  final String codigo;
  final String empresa;
  final String empresaRuc;
  final String fechaSolicitud;
  final String fechaEntrega;
  final String solicitante;
  final String area;
  final String centroCosto;
  final String estado;
  final String estadoColor;
  final String TipoDocAproCodigo;
  final String motivo;
  final String observacion;
  final String motivo_Movimiento_Codigo;
  final int nivelActual;
  final int ultimoNivel;
  final String? comentario;
  final String proveedorNombre;
  final String proveedorRuc;
  final String condicionPago;
  final String formaPago;
  final String almacen;
  final String sede;
  final String comprobante;
  final String tipoComprobante;
  final String notaCredito;
  final String ordenCompra;
  final String moneda;
  final double subtotal;
  final double impuesto;
  final double total;
  final List<ItemNormalizado> items;
  final List<AprobadorNormalizado> aprobadores;

  DocumentoDetalleNormalizado({
    required this.id,
    required this.codigo,
    required this.empresa,
    required this.empresaRuc,
    required this.TipoDocAproCodigo,
    required this.motivo_Movimiento_Codigo,
    required this.fechaSolicitud,
    required this.fechaEntrega,
    required this.solicitante,
    required this.area,
    required this.centroCosto,
    required this.estado,
    required this.estadoColor,
    required this.motivo,
    required this.observacion,
    required this.nivelActual,
    required this.ultimoNivel,
    this.comentario,
    required this.proveedorNombre,
    required this.proveedorRuc,
    required this.condicionPago,
    required this.formaPago,
    required this.almacen,
    required this.sede,
    required this.comprobante,
    required this.notaCredito,
    required this.ordenCompra,
    required this.tipoComprobante,
    required this.moneda,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.items,
    required this.aprobadores,
  });

  factory DocumentoDetalleNormalizado.fromJson(Map<String, dynamic> json) {
    return DocumentoDetalleNormalizado(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      empresa: json['empresa'] ?? '',
      TipoDocAproCodigo: json['tipoDocAproCodigo'] ?? '',
      empresaRuc: json['empresaRuc'] ?? '',
      fechaSolicitud: json['fechaSolicitud'] ?? '',
      motivo_Movimiento_Codigo: json['motivo_Movimiento_Codigo'] ?? '',
      fechaEntrega: json['fechaEntrega'] ?? '',
      solicitante: json['solicitante'] ?? '',
      area: json['area'] ?? '',
      centroCosto: json['centroCosto'] ?? '',
      estado: json['estado'] ?? '',
      estadoColor: json['estadoColor'] ?? '',
      motivo: json['motivo'] ?? '',
      observacion: json['observacion'] ?? '',
      nivelActual: json['nivelActual'] ?? 0,
      ultimoNivel: json['ultimoNivel'] ?? 0,
      comentario: json['comentario'],
      proveedorNombre: json['proveedorNombre'] ?? '',
      proveedorRuc: json['proveedorRuc'] ?? '',
      condicionPago: json['condicionPago'] ?? '',
      formaPago: json['formaPago'] ?? '',
      almacen: json['almacen'] ?? '',
      sede: json['sede'] ?? '',
      comprobante: json['comprobante'] ?? '',
      notaCredito: json['notaCredito'] ?? '',
      tipoComprobante: json['tipoComprobante'] ?? '',
      ordenCompra: json['ordenCompra'] ?? '',
      moneda: json['moneda'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      impuesto: (json['impuesto'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      items: (json['items'] as List<dynamic>?)?.map((e) => ItemNormalizado.fromJson(e)).toList() ?? [],
      aprobadores: (json['aprobadores'] as List<dynamic>?)?.map((e) => AprobadorNormalizado.fromJson(e)).toList() ?? [],
    );
  }
}

class ItemNormalizado {
  final int id;
  final int item;
  final String codigo;
  final String descripcion;
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final double total;
  final String centroCosto;
  final String almacen;
  final String estadoRecepcion;
  final String estadoColor;
  final bool esServicio;
  final String proyectoDescripcion;
  final String subCategoria;

  ItemNormalizado({
    required this.id,
    required this.item,
    required this.codigo,
    required this.descripcion,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
    required this.total,
    required this.centroCosto,
    required this.almacen,
    required this.estadoRecepcion,
    required this.proyectoDescripcion,
    required this.esServicio,
    required this.estadoColor,
    required this.subCategoria,
  });

  factory ItemNormalizado.fromJson(Map<String, dynamic> json) {
    return ItemNormalizado(
      id: json['id'] ?? 0,
      item: json['item'] ?? 0,
      codigo: json['codigo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      unidad: json['unidad'] ?? '',
      precioUnitario: (json['precioUnitario'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      centroCosto: json['centroCosto'] ?? '',
      almacen: json['almacen'] ?? '',
      estadoRecepcion: json['estadoRecepcion'] ?? '',
      proyectoDescripcion: json['proyectoDescripcion'] ?? '',
      estadoColor: json['estadoColor'] ?? '',
      esServicio: json['esServicio'] == true,
      subCategoria: json['subCategoria'] ?? '',
    );
  }
}

class AprobadorNormalizado {
  final int id;
  final int nivel;
  final String nombre;
  final String? email;
  final String? aprobacion;
  final String fechaAprobacion;
  final String? fechaLimite;
  final String comentario;
  final String? motivoRechazo;
  final String? motivoObservacion;
  final bool finalizado;
  final bool obligatorio;

  AprobadorNormalizado({
    required this.id,
    required this.nivel,
    required this.nombre,
    this.email,
    this.aprobacion,
    required this.fechaAprobacion,
    this.fechaLimite,
    required this.comentario,
    this.motivoRechazo,
    this.motivoObservacion,
    required this.finalizado,
    required this.obligatorio,
  });

  factory AprobadorNormalizado.fromJson(Map<String, dynamic> json) {
    return AprobadorNormalizado(
      id: json['id'] ?? 0,
      nivel: json['nivel'] ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'],
      aprobacion: json['aprobacion'],
      fechaAprobacion: json['fechaAprobacion'] ?? '',
      fechaLimite: json['fechaLimite'],
      comentario: json['comentario'] ?? '',
      motivoRechazo: json['motivoRechazo'],
      motivoObservacion: json['motivoObservacion'],
      finalizado: json['finalizado'] ?? false,
      obligatorio: json['obligatorio'] ?? false,
    );
  }
}
