part of 'unidad_bloc.dart';

@immutable
abstract class UnidadState {}

class UnidadInitial extends UnidadState {}

class UnidadProgress extends UnidadState {}

class UnidadSuccess extends UnidadState {
  final String numConductor;
  final String numViaje;
  final String codUnidad;
  final String placa;
  final String rpta;

  List<Tripulante> listTripulante;

  UnidadSuccess({
    required this.numConductor,
    required this.numViaje,
    required this.codUnidad,
    required this.placa,
    required this.rpta,
    this.listTripulante = const <Tripulante>[],
  });
}

class UnidadFailure extends UnidadState {
  final String numConductor;
  final String numViaje;
  final String rpta;
  final String mensaje;
  UnidadFailure(
    this.numConductor,
    this.numViaje,
    this.rpta,
    this.mensaje,
  );
}
