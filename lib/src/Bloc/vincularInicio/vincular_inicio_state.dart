part of 'vincular_inicio_bloc.dart';

@immutable
abstract class VincularInicioState {}

class VincularInicioInitial extends VincularInicioState {}

class VincularInicioProgress extends VincularInicioState {}

class VincularInicioSuccess extends VincularInicioState {
  final String tDocConducto1;
  final String nDocConducto1;
  final String mensaje;
  final String rpta;
  VincularInicioSuccess(
    this.tDocConducto1,
    this.nDocConducto1,
    this.mensaje,
    this.rpta,
  );
}

class VincularInicioFailure extends VincularInicioState {
  final String rpta;
  final String mensaje;
  VincularInicioFailure(this.rpta, this.mensaje);
}
