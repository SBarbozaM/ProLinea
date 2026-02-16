part of 'conductor1_bloc.dart';

@immutable
abstract class Conductor1Event {}

class VincularConductor1 extends Conductor1Event {
  final String nroViaje;
  final String NDocConductor;
  final String OrdenConductor;
  final String TDocUsuario;
  final String NDocUsuario;
  final String CodOperacion;

  VincularConductor1(this.nroViaje, this.NDocConductor, this.OrdenConductor,
      this.TDocUsuario, this.NDocUsuario, this.CodOperacion);
}

class resetEstadoConductor1Initial extends Conductor1Event {}

class EditarEstadoConducto1Success extends Conductor1Event {
  final String tDocConducto1;
  final String nDocConducto1;
  EditarEstadoConducto1Success(this.tDocConducto1, this.nDocConducto1);
}
