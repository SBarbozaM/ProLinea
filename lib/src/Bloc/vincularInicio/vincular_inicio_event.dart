part of 'vincular_inicio_bloc.dart';

@immutable
abstract class VincularInicioEvent {}

class VincularConductor extends VincularInicioEvent {
  final String nroViaje;
  final String NDocConductor;
  final String TDocUsuario;
  final String NDocUsuario;
  final String CodOperacion;

  VincularConductor(this.nroViaje, this.NDocConductor, this.TDocUsuario, this.NDocUsuario, this.CodOperacion);
}

class resetEstadoVincularInitial extends VincularInicioEvent {}

class EditarEstadoVincularSuccess extends VincularInicioEvent {
  final String tDocConducto1;
  final String nDocConducto1;
  EditarEstadoVincularSuccess(this.tDocConducto1, this.nDocConducto1);
}
