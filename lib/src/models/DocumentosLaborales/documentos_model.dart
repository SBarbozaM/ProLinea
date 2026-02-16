class DocLaboralDetalle {
  final String periodo;
  final String visualizada; // "SI" | "NO"
  final String ultVisualizada; // "03/12/2025 17:30" o ""
  final String codigo;

  // Opcionales (tipo 6 u otros)
  final String? categoria;
  final String? documento;
  final String? publicado;
  final String? estado;
  final String? mensaje;

  // Campos extra (tipo 1)
  final String? mesAnio; // "31/10/2025"
  final String? tipoPlanilla; // "N"
  final int tieneDescuento; // 0/1 (o más)

  DocLaboralDetalle({
    required this.periodo,
    required this.visualizada,
    required this.ultVisualizada,
    required this.mensaje,
    required this.codigo,
    this.categoria,
    this.documento,
    this.publicado,
    this.estado,
    this.mesAnio,
    this.tipoPlanilla,
    required this.tieneDescuento,
  });

  bool get estaVisualizada => visualizada.toUpperCase() == 'SI';
  bool get conDescuento => tieneDescuento != 0;

  factory DocLaboralDetalle.fromJson(Map<String, dynamic> json) {
    // Manejo seguro de int (por si viene "0" como string)
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return DocLaboralDetalle(
      periodo: (json['periodo'] ?? '').toString(),
      visualizada: (json['visualizada'] ?? '').toString(),
      ultVisualizada: (json['ultVisualizada'] ?? '').toString(),
      codigo: (json['codigo'] ?? '').toString(),
      mensaje: (json['mensaje'] ?? '').toString(),
      categoria: json['categoria']?.toString(),
      documento: json['documento']?.toString(),
      publicado: json['publicado']?.toString(),
      estado: json['estado']?.toString(),
      mesAnio: json['mesAnio']?.toString(),
      tipoPlanilla: json['tipoPlanilla']?.toString(),
      tieneDescuento: parseInt(json['tieneDescuento']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodo': periodo,
      'visualizada': visualizada,
      'ultVisualizada': ultVisualizada,
      'codigo': codigo,
      'mensaje': mensaje,
      'categoria': categoria,
      'documento': documento,
      'publicado': publicado,
      'estado': estado,
      'mesAnio': mesAnio,
      'tipoPlanilla': tipoPlanilla,
      'tieneDescuento': tieneDescuento,
    };
  }
}
