class TiposDocumento {
  List<TipoDocumento> tiposDocumento = [];

  TiposDocumento.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var element in jsonList) {
      final tipoDoc = TipoDocumento.fromJsonMap(element);
      tiposDocumento.add(tipoDoc);
    }
  }
}

class TipoDocumento {
  String codigo = "";
  String nombre = "";

  TipoDocumento({required this.codigo, required this.nombre});

  TipoDocumento.fromJsonMap(Map<String, dynamic> json) {
    codigo = json['codigo'];
    nombre = json['nombre'];
  }
}
