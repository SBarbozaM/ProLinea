class PuntosEmbarque {
  List<PuntoEmbarque> puntosEmbarque = [];

  PuntosEmbarque.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var element in jsonList) {
      final puntoEmbarque = PuntoEmbarque.fromJsonMap(element);
      puntosEmbarque.add(puntoEmbarque);
    }
  }

  /* NUEVO 05/05/23 */
  PuntosEmbarque.fromJsonListNombre(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (var element in jsonList) {
      final puntoEmbarque = PuntoEmbarque.fromJsonMapNombre(element);
      puntosEmbarque.add(puntoEmbarque);
    }
  }
}

class PuntoEmbarque {
  String id = "";
  String nombre = "";
  String nroViaje = "";
  int eliminado = 1; //0 no eliminado (abierto) 1 eliminado (cerrado)
  String fechaAccion = "";
  int modificado = 1; //1 -> no modificado, 0 -> modificado
  String impreso = "0"; //0 no impreso 1 impreso /* NUEVO 05/05/23 */
  String sincronizado = "0"; // 0: sincronizado 1: no sincronizado

  PuntoEmbarque({required this.id, required this.nombre, required this.nroViaje, required this.eliminado, this.fechaAccion = "", this.impreso = "0"}); /* NUEVO 05/05/23 */

  PuntoEmbarque.fromJsonMap(Map<String, dynamic> json) {
    id = json['id'];
    nombre = json['nombre'];
    eliminado = json['cerrado'] ?? 0;
  }

/* NUEVO 05/05/23 */
  PuntoEmbarque.fromJsonMapNombre(Map<String, dynamic> json) {
    nombre = json['nombre'];
  }
  PuntoEmbarque.fromJsonMapBDLocal(Map<String, dynamic> json) {
    id = json['id'];
    nombre = json['nombre'];
    nroViaje = json['nroViaje'];
    eliminado = json['eliminado'] ?? 0;
    sincronizado = json['sincronizado'];
  }

  Map<String, dynamic> toMapDatabase() {
    return {
      'id': id.trim(),
      'nombre': nombre.trim(),
      'nroViaje': nroViaje.trim(),
      'eliminado': eliminado,
      "sincronizado": sincronizado,
    };
  }
}
