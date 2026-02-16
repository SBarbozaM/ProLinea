part of 'conductor3_bloc.dart';

@immutable
abstract class Conductor3State {}

class Conductor3Initial extends Conductor3State {}

class Conductor3Progress extends Conductor3State {}

class Conductor3Success extends Conductor3State {
  final String tDocConducto3;
  final String nDocConducto3;
  final String nombreConductor3;
  final String fechaEmp;
  final String mensaje;
  final String rpta;
  Conductor3Success(
    this.tDocConducto3,
    this.nDocConducto3,
    this.nombreConductor3,
    this.fechaEmp,
    this.mensaje,
    this.rpta,
  );
}

class Conductor3Failure extends Conductor3State {
  final String rpta;
  final String mensaje;
  Conductor3Failure(this.rpta, this.mensaje);
}
