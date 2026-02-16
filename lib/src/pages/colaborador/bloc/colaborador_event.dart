part of 'colaborador_bloc.dart';

class ColaboradorEvent extends Equatable {
  const ColaboradorEvent();

  @override
  List<Object> get props => [];
}

class ListarTipoDoc extends ColaboradorEvent {
  ListarTipoDoc();
}

class ListarEmpresas extends ColaboradorEvent {
  ListarEmpresas({
    required this.CodOperacion,
    required this.usuario,
    required this.initialEmpresa,
  });
  final String usuario;
  final String CodOperacion;
  final String initialEmpresa;
}

class ListarAreas extends ColaboradorEvent {
  ListarAreas({
    required this.CodOperacion,
    required this.usuario,
    required this.idEmpresa,
    required this.initialArea,
  });
  final String usuario;
  final String CodOperacion;
  final int idEmpresa;
  final String initialArea;
}

class GetColaboradorDatos extends ColaboradorEvent {
  final String CodOperacion;
  final String usuario;
  final String tDoc;
  final String nDoc;

  GetColaboradorDatos({
    required this.CodOperacion,
    required this.usuario,
    required this.tDoc,
    required this.nDoc,
  });
}

class CrearEditarColaborador extends ColaboradorEvent {
  final String CodOperacion;
  final String usuario;
  final String tDoc;
  final String nDoc;
  final String paterno;
  final String materno;
  final String nombres;
  final String idEmpresa;
  final String idArea;
  final String Activo;
  final String codExterno;

  CrearEditarColaborador({
    required this.CodOperacion,
    required this.usuario,
    required this.tDoc,
    required this.nDoc,
    required this.paterno,
    required this.materno,
    required this.nombres,
    required this.idEmpresa,
    required this.idArea,
    required this.Activo,
    required this.codExterno,
  });
}
