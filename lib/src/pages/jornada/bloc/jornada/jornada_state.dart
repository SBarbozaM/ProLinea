part of 'jornada_bloc.dart';

class JornadaState extends Equatable {
  final List<Tripulante> listaTributales;
  final String idJornadaActual;
  final String NombreJornadaActual;
  final List<Jornada> listJornada;
  final String vinculacion;
  final String mensaje;
  final String code;

  JornadaState(
      {this.listaTributales = const <Tripulante>[],
      this.idJornadaActual = "",
      this.NombreJornadaActual = "",
      this.vinculacion = "",
      this.mensaje = "",
      this.code = "0",
      this.listJornada = const []});

  JornadaState copyWith({
    List<Tripulante>? listaTributales,
    String? idJornadaActual,
    String? NombreJornadaActual,
    String? vinculacion,
    List<Jornada>? listJornada,
    String? mensaje,
    String? code,
  }) =>
      JornadaState(
        listaTributales: listaTributales ?? this.listaTributales,
        idJornadaActual: idJornadaActual ?? this.idJornadaActual,
        vinculacion: vinculacion ?? this.vinculacion,
        NombreJornadaActual: NombreJornadaActual ?? this.NombreJornadaActual,
        listJornada: listJornada ?? this.listJornada,
        mensaje: mensaje ?? this.mensaje,
        code: code ?? this.code,
      );

  @override
  List<Object> get props => [
        listaTributales,
        idJornadaActual,
        vinculacion,
        NombreJornadaActual,
        listJornada,
        mensaje,
        code,
      ];
}
