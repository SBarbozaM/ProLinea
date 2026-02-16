part of 'conductor2_bloc.dart';

@immutable
abstract class Conductor2State {}

class Conductor2Initial extends Conductor2State {}

class Conductor2Progress extends Conductor2State {}

class Conductor2Success extends Conductor2State {
  final String tDocConducto2;
  final String nDocConducto2;
  final String nombreConductor2;
  final String fechaEmp;
  final String mensaje;
  final String rpta;
  Conductor2Success(
    this.tDocConducto2,
    this.nDocConducto2,
    this.nombreConductor2,
    this.fechaEmp,
    this.mensaje,
    this.rpta,
  );
}

class Conductor2Failure extends Conductor2State {
  final String rpta;
  final String mensaje;
  Conductor2Failure(this.rpta, this.mensaje);
}
