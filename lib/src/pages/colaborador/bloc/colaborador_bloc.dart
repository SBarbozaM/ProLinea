import 'package:bloc/bloc.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorAreas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorDatos.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorEmpresas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorTipoDoc.dart';
import 'package:embarques_tdp/src/services/colaborador/colaborador_servicio.dart';
import 'package:equatable/equatable.dart';

part 'colaborador_event.dart';
part 'colaborador_state.dart';

class ColaboradorBloc extends Bloc<ColaboradorEvent, ColaboradorState> {
  final ColaboradorServicio _colaboradorServicio;

  ColaboradorBloc({
    required ColaboradorServicio colaboradorServicio,
  })  : _colaboradorServicio = colaboradorServicio,
        super(ColaboradorState()) {
    on<ListarTipoDoc>(_onListarTipoDoc);
    on<ListarEmpresas>(_onListarEmpresas);
    on<ListarAreas>(_onListarAreas);
    on<GetColaboradorDatos>(_onColaboradorDatos);
    on<CrearEditarColaborador>(_onGuardarEditar);
  }

  Future<void> _onListarTipoDoc(
    ListarTipoDoc event,
    Emitter<ColaboradorState> emit,
  ) async {
    try {
      List<ColaboradorTipoDoc> listaTipoDoc = await _colaboradorServicio.ColaboradorListarTipoDoc();
      emit(state.copyWith(
        listaTipoDoc: listaTipoDoc,
        rpta: "",
        rptaGuardarEditar: "-1",
      ));
    } catch (_) {}
  }

  Future<void> _onListarEmpresas(
    ListarEmpresas event,
    Emitter<ColaboradorState> emit,
  ) async {
    try {
      List<ColaboradorEmpresas> listaEmpresas = await _colaboradorServicio.ColaboradorListarEmpresas(
        usuario: event.usuario,
        codOperacion: event.CodOperacion,
      );

      String rpta = "";

      if (event.initialEmpresa.length > 0) {
        rpta = "1";
      }

      emit(state.copyWith(
        listaEmpresas: listaEmpresas,
        rpta: rpta,
        initialEmpresa: event.initialEmpresa,
        rptaGuardarEditar: "-1",
      ));
    } catch (_) {}
  }

  Future<void> _onListarAreas(
    ListarAreas event,
    Emitter<ColaboradorState> emit,
  ) async {
    try {
      List<ColaboradorAreas> listaAreas = await _colaboradorServicio.ColaboradorListarAreas(
        usuario: event.usuario,
        codOperacion: event.CodOperacion,
        idEmpresa: event.idEmpresa,
      );
      String rpta = "";

      if (event.initialArea.length > 0) {
        rpta = "1";
      }

      emit(state.copyWith(
        listaAreas: listaAreas,
        rpta: rpta,
        initialArea: event.initialArea,
        rptaGuardarEditar: "-1",
      ));
    } catch (_) {}
  }

  Future<void> _onColaboradorDatos(
    GetColaboradorDatos event,
    Emitter<ColaboradorState> emit,
  ) async {
    try {
      ColaboradorDatos colaborador = await _colaboradorServicio.colaboradorDatos(
        codOperacion: event.CodOperacion,
        usuario: event.usuario,
        tdoc: event.tDoc,
        ndoc: event.nDoc,
      );
      if (colaborador.idEmpresa != "") {
        add(ListarEmpresas(
          CodOperacion: event.CodOperacion,
          usuario: event.usuario,
          initialEmpresa: colaborador.idEmpresa,
        ));

        add(ListarAreas(
          CodOperacion: event.CodOperacion,
          usuario: event.usuario,
          idEmpresa: int.parse(colaborador.idEmpresa),
          initialArea: colaborador.idArea,
        ));
      }

      emit(state.copyWith(colaboradorDatos: colaborador, rpta: "1", rptaGuardarEditar: "-1"));
    } catch (_) {}
  }

  Future<void> _onGuardarEditar(
    CrearEditarColaborador event,
    Emitter<ColaboradorState> emit,
  ) async {
    try {
      String rpta = await _colaboradorServicio.colaborador_RegistrarModificar(
        codOperacion: event.CodOperacion,
        usuario: event.usuario,
        tdoc: event.tDoc,
        ndoc: event.nDoc,
        paterno: event.paterno,
        materno: event.materno,
        nombres: event.nombres,
        idEmpresa: event.idEmpresa,
        idArea: event.idArea,
        activo: event.Activo,
        codigoExterno: event.codExterno,
      );
      add(GetColaboradorDatos(
        CodOperacion: event.CodOperacion,
        usuario: event.usuario,
        tDoc: event.tDoc,
        nDoc: event.nDoc,
      ));
      emit(state.copyWith(rpta: "", rptaGuardarEditar: rpta));
    } catch (_) {}
  }
}
