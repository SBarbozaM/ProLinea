import 'package:intl/intl.dart';

class formatFecha {
  String cambiarFormatoFeha(String fecha) {
    final fechaSplit = fecha.split(" ");
    final fechaSp = fechaSplit[0].split("/");
    final dia = fechaSp[0];
    final mes = fechaSp[1];
    final anio = fechaSp[2];

    final fechaDate =
        DateTime.parse("${anio}-${mes}-${dia} ${fechaSplit[2].trim()}");
    String fechaFormateada =
        DateFormat("yyyy-mm-dd HH:mm:ss").format(fechaDate).toString();

    return fechaFormateada;
  }
}
