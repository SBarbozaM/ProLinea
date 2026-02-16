part of 'embarques_sup_scaner_bloc.dart';

@immutable
abstract class EmbarquesSupScanerState {}

class EmbarquesSupScanerInitial extends EmbarquesSupScanerState {}

class EmbarquesSupScanerProgress extends EmbarquesSupScanerState {}

class EmbarquesSupScanerSuccess extends EmbarquesSupScanerState {
  final String numConductor;
  final String numViaje;
  final String rpta;
  EmbarquesSupScanerSuccess(this.numConductor, this.numViaje, this.rpta);
}

class EmbarquesSupScanerFailure extends EmbarquesSupScanerState {
  final String numConductor;
  final String numViaje;
  final String rpta;
  final String mensaje;
  EmbarquesSupScanerFailure(
      this.numConductor, this.numViaje, this.rpta, this.mensaje);
}
