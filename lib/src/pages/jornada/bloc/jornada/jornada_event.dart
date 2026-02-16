part of 'jornada_bloc.dart';

@immutable
abstract class JornadaEvent {}

class AddTripulante extends JornadaEvent {
  final String nroViaje;
  final String tDocConducto;
  final String nDocConducto;
  final String nombreConductor;
  AddTripulante(
    this.nroViaje,
    this.tDocConducto,
    this.nDocConducto,
    this.nombreConductor,
  );
}

class Iniciarjornada extends JornadaEvent {
  final String nDocConducto;
  final String nrViaje;
  final String cordenadas;
  final String usuarioLogeo;
  Iniciarjornada(this.nDocConducto, this.nrViaje, this.cordenadas, this.usuarioLogeo);
}

class Listarjornadas extends JornadaEvent {
  final String nroViaje;
  Listarjornadas(this.nroViaje);
}

class FinalizarJornada extends JornadaEvent {
  final String nDocConducto;
  final String nrViaje;
  final String cordenadas;

  FinalizarJornada(this.nDocConducto, this.nrViaje, this.cordenadas);
}

class resetJornadaActual extends JornadaEvent {
  resetJornadaActual();
}

class ContinuarVinculacion extends JornadaEvent {
  final String numViaje;
  final String codOperacion;
  final String tDocUsuario;
  final String nDocUsuario;
  final List<Tripulante> list;
  final String odometroInicio;
  final String coordenadas;

  ContinuarVinculacion(
    this.numViaje,
    this.tDocUsuario,
    this.nDocUsuario,
    this.codOperacion,
    this.list,
    this.odometroInicio,
    this.coordenadas,
  );
}
