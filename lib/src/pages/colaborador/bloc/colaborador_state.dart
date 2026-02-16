part of 'colaborador_bloc.dart';

class ColaboradorState extends Equatable {
  ColaboradorState({
    this.listaTipoDoc = const <ColaboradorTipoDoc>[],
    this.listaEmpresas = const <ColaboradorEmpresas>[],
    this.listaAreas = const <ColaboradorAreas>[],
    this.colaboradorDatos = ColaboradorDatos.empty,
    this.rpta = "",
    this.initialEmpresa = "",
    this.initialArea = "",
    this.rptaGuardarEditar = "",
  });

  final List<ColaboradorTipoDoc> listaTipoDoc;
  final List<ColaboradorEmpresas> listaEmpresas;
  final List<ColaboradorAreas> listaAreas;
  final ColaboradorDatos colaboradorDatos;
  final String rpta;
  final String initialEmpresa;
  final String initialArea;
  final String rptaGuardarEditar;

  ColaboradorState copyWith({
    List<ColaboradorTipoDoc>? listaTipoDoc,
    List<ColaboradorEmpresas>? listaEmpresas,
    List<ColaboradorAreas>? listaAreas,
    ColaboradorDatos? colaboradorDatos,
    String? rpta,
    String? initialEmpresa,
    String? initialArea,
    String? rptaGuardarEditar,
  }) {
    return ColaboradorState(
      listaTipoDoc: listaTipoDoc ?? this.listaTipoDoc,
      listaEmpresas: listaEmpresas ?? this.listaEmpresas,
      listaAreas: listaAreas ?? this.listaAreas,
      colaboradorDatos: colaboradorDatos ?? this.colaboradorDatos,
      rpta: rpta ?? this.rpta,
      initialEmpresa: initialEmpresa ?? this.initialEmpresa,
      initialArea: initialArea ?? this.initialArea,
      rptaGuardarEditar: rptaGuardarEditar ?? this.rptaGuardarEditar,
    );
  }

  @override
  List<Object> get props => [
        listaTipoDoc,
        listaEmpresas,
        listaAreas,
        colaboradorDatos,
        rpta,
        initialEmpresa,
        initialArea,
        rptaGuardarEditar,
      ];
}
