part of 'conductor1_bloc.dart';

@immutable
abstract class Conductor1State {}

class Conductor1Initial extends Conductor1State {}

class Conductor1Progress extends Conductor1State {}

class Conductor1Success extends Conductor1State {
  final String tDocConducto1;
  final String nDocConducto1;
  final String nombreConductor1;
  final String fechaEmp;
  final String mensaje;
  final String rpta;
  Conductor1Success(
    this.tDocConducto1,
    this.nDocConducto1,
    this.nombreConductor1,
    this.fechaEmp,
    this.mensaje,
    this.rpta,
  );
}

class Conductor1Failure extends Conductor1State {
  final String rpta;
  final String mensaje;
  Conductor1Failure(this.rpta, this.mensaje);
}
