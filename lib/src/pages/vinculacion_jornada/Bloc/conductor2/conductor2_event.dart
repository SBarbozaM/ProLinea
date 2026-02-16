part of 'conductor2_bloc.dart';

@immutable
abstract class Conductor2Event {}

class VincularConductor2 extends Conductor2Event {
  final String nroViaje;
  final String NDocConductor;
  final String OrdenConductor;
  final String TDocUsuario;
  final String NDocUsuario;
  final String CodOperacion;

  VincularConductor2(this.nroViaje, this.NDocConductor, this.OrdenConductor,
      this.TDocUsuario, this.NDocUsuario, this.CodOperacion);
}

class resetEstadoConductor2Initial extends Conductor2Event {}

class EditarEstadoConducto2Success extends Conductor2Event {
  final String tDocConducto2;
  final String nDocConducto2;
  EditarEstadoConducto2Success(this.tDocConducto2, this.nDocConducto2);
}
