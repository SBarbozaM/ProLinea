part of 'conductor3_bloc.dart';

@immutable
abstract class Conductor3Event {}

class VincularConductor3 extends Conductor3Event {
  final String nroViaje;
  final String NDocConductor;
  final String OrdenConductor;
  final String TDocUsuario;
  final String NDocUsuario;
  final String CodOperacion;

  VincularConductor3(this.nroViaje, this.NDocConductor, this.OrdenConductor,
      this.TDocUsuario, this.NDocUsuario, this.CodOperacion);
}

class resetEstadoConductor3Initial extends Conductor3Event {}

class EditarEstadoConducto3Success extends Conductor3Event {
  final String tDocConducto3;
  final String nDocConducto3;
  EditarEstadoConducto3Success(this.tDocConducto3, this.nDocConducto3);
}
