class Paraderos {
  List<Paradero> paraderos = [];

  Paraderos.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var element in jsonList) {
      final paradero = Paradero.fromJsonMap(element);
      paraderos.add(paradero);
    }
  }
}

class Paradero {
  String id = "";
  String nombre = "";

  Paradero();

  Paradero.fromJsonMap(Map<String, dynamic> json) {
    id = json['id'];
    nombre = json['nombre'];
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
      };
}
