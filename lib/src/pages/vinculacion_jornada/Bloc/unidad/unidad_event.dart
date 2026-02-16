part of 'unidad_bloc.dart';

@immutable
abstract class UnidadEvent {}

class EscanearUnidadJornada extends UnidadEvent {
  final String textQR;
  final String codigoOperacion;
  final String usuarioAuth;
  EscanearUnidadJornada(this.textQR, this.codigoOperacion, this.usuarioAuth);
}

class resetEstadoUnidadInitial extends UnidadEvent {}

class EditarEstadoEscanearUnidadSuccess extends UnidadEvent {
  final String numConductor;
  final String numViaje;
  EditarEstadoEscanearUnidadSuccess(this.numConductor, this.numViaje);
}

class SetStateUnidadSuccess extends UnidadEvent {
  final String placa;
  final String codUnidad;
  final String numViaje;

  SetStateUnidadSuccess(this.placa, this.codUnidad, this.numViaje);
}

class ResetListTripulantes extends UnidadEvent {
  ResetListTripulantes();
}
