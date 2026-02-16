part of 'checklist_bloc.dart';

enum statusLista { initial, progress, failure, success }

enum StatusValidarCheck { initial, progress, failure, success }

enum StatusGuardarEditarCheck { initial, progress, failure, success }

class ChecklistState extends Equatable {
  final List<CheckList> listaCheck;
  final List<TipoCheckList> listaTipoCheck;

  final List<HojaServicio> listaHojaServicio;

  final statusLista statuslista;
  final StatusValidarCheck statusValidarCheck;
  final ValidarCheckList validarCheck;
  final StatusGuardarEditarCheck statusGuardarEditarCheck;
  final ValidarCheckList guardarEditarCheck;
  final String mensaje;

  const ChecklistState({
    this.listaCheck = const <CheckList>[],
    this.listaTipoCheck = const <TipoCheckList>[],
    this.listaHojaServicio = const <HojaServicio>[],
    this.statuslista = statusLista.initial,
    this.statusValidarCheck = StatusValidarCheck.initial,
    this.validarCheck = ValidarCheckList.empty,
    this.statusGuardarEditarCheck = StatusGuardarEditarCheck.initial,
    this.guardarEditarCheck = ValidarCheckList.empty,
    this.mensaje = "",
  });

  ChecklistState copyWith({
    List<CheckList>? listaCheck,
    List<TipoCheckList>? listaTipoCheck,
    List<HojaServicio>? listaHojaServicio,
    statusLista? statuslista,
    StatusValidarCheck? statusValidarCheck,
    ValidarCheckList? validarCheck,
    StatusGuardarEditarCheck? statusGuardarEditarCheck,
    ValidarCheckList? guardarEditarCheck,
    String? mensaje,
  }) =>
      ChecklistState(
        statuslista: statuslista ?? this.statuslista,
        listaTipoCheck: listaTipoCheck ?? this.listaTipoCheck,
        listaHojaServicio: listaHojaServicio ?? this.listaHojaServicio,
        statusValidarCheck: statusValidarCheck ?? this.statusValidarCheck,
        listaCheck: listaCheck ?? this.listaCheck,
        validarCheck: validarCheck ?? this.validarCheck,
        statusGuardarEditarCheck: statusGuardarEditarCheck ?? this.statusGuardarEditarCheck,
        guardarEditarCheck: guardarEditarCheck ?? this.guardarEditarCheck,
        mensaje: mensaje ?? this.mensaje,
      );

  @override
  List<Object> get props => [
        listaCheck,
        listaHojaServicio,
        listaTipoCheck,
        statuslista,
        statusValidarCheck,
        validarCheck,
        statusGuardarEditarCheck,
        guardarEditarCheck,
        mensaje,
      ];
}
