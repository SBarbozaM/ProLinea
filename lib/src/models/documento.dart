class Documentos {
  List<Documento> documentos = [];

  Documentos.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var element in jsonList) {
      final documento = Documento.fromJsonMap(element);
      documentos.add(documento);
    }
  }
}

class Documento {
  String numeroDoc = "";
  String nombre = "";
  String estado = "";
  String fechaVencimiento = "";
  String tipo = "";
  String estado_descripcion = "";

  Documento();

  Documento.fromJsonMap(Map<String, dynamic> json) {
    numeroDoc = json['numero_doc'];
    nombre = json['nombre'];
    estado = json['estado'];
    fechaVencimiento = json['fecha_vencimiento'];
    tipo = json['tipo_doc'];
    estado_descripcion = json['estado_descripcion'];
  }
}
