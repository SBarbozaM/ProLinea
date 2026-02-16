part of 'checklist_bloc.dart';

sealed class ChecklistEvent extends Equatable {
  const ChecklistEvent();

  @override
  List<Object> get props => [];
}

class ListarCheckListEvent extends ChecklistEvent {
  final int hoseCode;
  final String tDoc;
  final String nDoc;
  final String placa;
  final int tipoCheckList;
  ListarCheckListEvent({required this.hoseCode, required this.tDoc, required this.nDoc, required this.placa, required this.tipoCheckList}) {}

  @override
  List<Object> get props => [];
}

class ValidarListarCheckConductorEvent extends ChecklistEvent {
  final String tipoDoc;
  final String nroDoc;
  final String placa;
  final String codOperacion;
  final int tipoCheckList;

  ValidarListarCheckConductorEvent({
    required this.tipoDoc,
    required this.nroDoc,
    required this.placa,
    required this.codOperacion,
    required this.tipoCheckList
  }) {}

  @override
  List<Object> get props => [];
}

class ValidarListarEditarCheckConductorEvent extends ChecklistEvent {
  final String tipoDoc;
  final String nroDoc;
  final String placa;
  final String codOperacion;

  ValidarListarEditarCheckConductorEvent({
    required this.tipoDoc,
    required this.nroDoc,
    required this.placa,
    required this.codOperacion,
  }) {}

  @override
  List<Object> get props => [];
}

class LikeEvent extends ChecklistEvent {
  final CheckList checkmodel;
  LikeEvent({required this.checkmodel}) {}

  @override
  List<Object> get props => [checkmodel];
}

class NoLikeNoCompletadoEvent extends ChecklistEvent {
  final CheckList checkmodel;
  NoLikeNoCompletadoEvent({required this.checkmodel}) {}

  @override
  List<Object> get props => [];
}

class NoLikeCompletadoEvent extends ChecklistEvent {
  final CheckList checkmodel;
  NoLikeCompletadoEvent({required this.checkmodel}) {}
  @override
  List<Object> get props => [];
}

class GuardarEditarCheckListEvent extends ChecklistEvent {
  final Usuario usuario;
  GuardarEditarCheckListEvent({required this.usuario}) {}
  @override
  List<Object> get props => [];
}

class ListarTipoCheckListEvent extends ChecklistEvent {
  final String tDoc;
  final String nDoc;
  ListarTipoCheckListEvent({required this.tDoc, required this.nDoc}) {}

  @override
  List<Object> get props => [];
}
