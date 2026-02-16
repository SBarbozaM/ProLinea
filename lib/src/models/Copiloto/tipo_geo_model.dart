class TipoGeo {
  final String nombre;
  final int value;

  TipoGeo({required this.nombre, required this.value});

  // Crear una instancia de Operacion a partir de un Map (JSON)
  // factory Operacion.fromJson(Map<String, dynamic> json) {
  //   return Operacion(
  //     idOperacion: json['idOperacion'].toString(),
  //     nombre: json['nombre'].toString(),
  //   );
  // }

  // Convertir una instancia de Operacion a un Map
  // Map<String, dynamic> toJson() {
  //   return {
  //     'idOperacion': idOperacion,
  //     'nombre': nombre,
  //   };
  // }
}