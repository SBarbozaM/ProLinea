part of 'ayudante_bloc.dart';

@immutable
abstract class AyudanteState {}

class AyudanteInitial extends AyudanteState {}

class AyudanteProgress extends AyudanteState {}

class AyudanteSuccess extends AyudanteState {
  final String tDocAyudante;
  final String nDocAyudante;
  final String nombreAyudante;
  final String fechaEmp;
  final String mensaje;
  final String rpta;
  AyudanteSuccess(
    this.tDocAyudante,
    this.nDocAyudante,
    this.nombreAyudante,
    this.fechaEmp,
    this.mensaje,
    this.rpta,
  );
}

class AyudanteFailure extends AyudanteState {
  final String rpta;
  final String mensaje;
  AyudanteFailure(this.rpta, this.mensaje);
}
