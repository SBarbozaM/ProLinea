part of 'ayudante_bloc.dart';

@immutable
abstract class AyudanteEvent {}

class VincularAyudante extends AyudanteEvent {
  final String nroViaje;
  final String NDocConductor;
  final String OrdenConductor;
  final String TDocUsuario;
  final String NDocUsuario;
  final String CodOperacion;

  VincularAyudante(this.nroViaje, this.NDocConductor, this.OrdenConductor,
      this.TDocUsuario, this.NDocUsuario, this.CodOperacion);
}

class resetEstadoAyudanteInitial extends AyudanteEvent {}

class EditarEstadoAyudanteSuccess extends AyudanteEvent {
  final String tDocConducto1;
  final String nDocConducto1;
  EditarEstadoAyudanteSuccess(this.tDocConducto1, this.nDocConducto1);
}
