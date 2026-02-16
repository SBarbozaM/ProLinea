part of 'embarques_sup_scaner_bloc.dart';

@immutable
abstract class EmbarquesSupScanerEvent {}

class EscanearUnidad extends EmbarquesSupScanerEvent {
  final String textQR;
  final String codigoOperacion;
  EscanearUnidad(this.textQR, this.codigoOperacion);
}

class resetEstadoEscanearUnidadInitial extends EmbarquesSupScanerEvent {}

class EditarEstadoEscanearUnidadSuccessSup extends EmbarquesSupScanerEvent {
  final String numConductor;
  final String numViaje;
  EditarEstadoEscanearUnidadSuccessSup(this.numConductor, this.numViaje);
}
