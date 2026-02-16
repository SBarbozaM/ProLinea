import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:embarques_tdp/src/models/check_list/checklist.dart';
import 'package:embarques_tdp/src/models/check_list/validar_checklist.dart';
import 'package:embarques_tdp/src/models/check_list/validar_edit_checkList.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/services/checklist_mantenimiento_servico.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
part 'checklist_event.dart';
part 'checklist_state.dart';

class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  ChecklistServicio _sChecklist = ChecklistServicio();

  ChecklistBloc({required ChecklistServicio sChecklist})
      : _sChecklist = sChecklist,
        super(ChecklistState()) {
    //--------validar checklist

    on<ValidarListarCheckConductorEvent>(_validarUnidadCheck);
    on<ValidarListarEditarCheckConductorEvent>(_validarListarEditarUnidadCheck);

    //--------listar checklist
    on<ListarCheckListEvent>((event, emit) async {
      emit(state.copyWith(
        statuslista: statusLista.progress,
        //statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
        statusValidarCheck: StatusValidarCheck.initial,
      ));
      if (event.tipoCheckList == 0) {
        emit(state.copyWith(
          statuslista: statusLista.failure,
          listaCheck: [],
        ));
      }
      CheckListModel check = await _sChecklist.GET_CheckList(Hs_codigo: event.hoseCode, tDoc: event.tDoc, nDoc: event.nDoc, placa: event.placa, tipoCheckList: event.tipoCheckList);

      if (check.rpta == "0" || check.rpta == "1") {
        emit(state.copyWith(
          statuslista: statusLista.success,
          listaCheck: check.listaCheck,
        ));
      } else {
        emit(state.copyWith(
          statuslista: statusLista.failure,
          listaCheck: [],
        ));
      }
    });

    on<ListarTipoCheckListEvent>((event, emit) async {
      emit(state.copyWith(
        statuslista: statusLista.progress,
        statusValidarCheck: StatusValidarCheck.initial,
      ));
      TipoCheckListModel check = await _sChecklist.GET_TipoCheckList(tDoc: event.tDoc, nDoc: event.nDoc);

      if (check.rpta == "0" || check.rpta == "200") {
        emit(state.copyWith(
          statuslista: statusLista.success,
          listaTipoCheck: check.listaTipoCheck,
        ));
      } else {
        emit(state.copyWith(
          statuslista: statusLista.failure,
          listaTipoCheck: [],
        ));
      }
    });

    on<LikeEvent>((event, emit) {
      emit(state.copyWith(
        statuslista: statusLista.progress,
        statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
      ));
      CheckList? checkmodel = state.listaCheck.firstWhereOrNull((element) => element.orden == event.checkmodel.orden);

      if (checkmodel != null) {
        checkmodel.estadolike = 1;
        checkmodel.guardado = true;

        emit(state.copyWith(statuslista: statusLista.success, listaCheck: state.listaCheck));
      }
    });

    on<NoLikeCompletadoEvent>((event, emit) {
      emit(state.copyWith(
        statuslista: statusLista.progress,
        statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
      ));
      CheckList? checkmodel = state.listaCheck.firstWhereOrNull((element) => element.orden == event.checkmodel.orden);

      if (checkmodel != null) {
        checkmodel.estadolike = 2;
        checkmodel.guardado = true;

        emit(
          state.copyWith(
            statuslista: statusLista.success,
            statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
            listaCheck: state.listaCheck,
          ),
        );
      }
    });

    on<NoLikeNoCompletadoEvent>((event, emit) {
      emit(state.copyWith(
        statuslista: statusLista.progress,
        statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
      ));
      CheckList? checkmodel = state.listaCheck.firstWhereOrNull((element) => element.orden == event.checkmodel.orden);

      if (checkmodel != null) {
        checkmodel.estadolike = 0;
        checkmodel.guardado = false;

        emit(
          state.copyWith(
            statuslista: statusLista.success,
            listaCheck: state.listaCheck,
          ),
        );
      }
    });

    //--GUARDAR CHECKLIST
    on<GuardarEditarCheckListEvent>((event, emit) async {
      emit(state.copyWith(
        statusGuardarEditarCheck: StatusGuardarEditarCheck.progress,
        statusValidarCheck: StatusValidarCheck.initial,
      ));

      ValidarCheckList response;

      var listaChe = [];
      for (var check in state.listaCheck) {
        if (check.trabajo.trim() != 'Otro' && check.orden != "0" && check.estadolike == 0 && check.obligatorio == true) {
          response = ValidarCheckList(rpta: "1", mensaje: "Tienes trabajos obligatorios sin verificar", nroViaje: 0, tipoChecklist: "", descVehiculo: "", codVehiculo: "", hoseCodigo: 0, hoseRegistro: "", maxFiles: 0, maxSizeFiles: 0);
          return emit(
            state.copyWith(
              statusGuardarEditarCheck: StatusGuardarEditarCheck.failure,
              guardarEditarCheck: response,
              statusValidarCheck: StatusValidarCheck.initial,
            ),
          );
        }

        if (check.orden != "0" && check.estadolike == 2 && check.guardado == false) {
          response = ValidarCheckList(rpta: "1", mensaje: "Tiene trabajos sin guardar", nroViaje: 0, tipoChecklist: "", descVehiculo: "", hoseCodigo: 0, hoseRegistro: "", codVehiculo: "", maxFiles: 0, maxSizeFiles: 0);
          return emit(
            state.copyWith(
              statusGuardarEditarCheck: StatusGuardarEditarCheck.failure,
              guardarEditarCheck: response,
              statusValidarCheck: StatusValidarCheck.initial,
            ),
          );
        }
        if (check.orden != "0" && check.estadolike != 0) {
          // --- RECURSOS ---
          List<Map<String, dynamic>> recursosLista = [];

          // Validación para evitar null
          if (check.recursos != null && check.recursos.isNotEmpty) {
            for (var recurso in check.recursos) {
              recursosLista.add({
                "DEHS_Codigo": recurso.dehSCodigo,
                "VIAJ_Nro_Viaje": recurso.viaJNroViaje,
                "REDEHS_Archivo": recurso.redehSArchivo,
                "REDEHS_TipoArchivo": recurso.redehSTipoArchivo,
                "REDEHS_FechaRegistrada": recurso.redehSFechaRegistrada,
              });
            }
          }

          // --- AGREGAR ITEM PRINCIPAL ---
          listaChe.add({
            "SCod": check.sCod,
            "Orden": check.orden,
            "Trabajo": check.trabajo,
            "Estado": "${check.estadolike}",
            "Observacion": check.observacion,
            "Atencion": check.atencion,
            "Prioridad": check.prioridad,
            "DEHS_Codigo": check.dehSCodigo,
            "recursos": recursosLista, // SIEMPRE ES LISTA, NUNCA NULL
            "Obligatorio": check.obligatorio,
            "Ope_Id": check.ope_Id,
            "TipoCheckList": check.tipoCheckList
          });
        }
      }

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);

      Map body = {
        "HOSE_Codigo": state.validarCheck.hoseCodigo,
        "VIAJ_Nro_Viaje": state.validarCheck.nroViaje,
        "PERS_TDOC": event.usuario.tipoDoc,
        "PERS_NDOC": event.usuario.numDoc,
        "ITEM_ALTA": 0,
        "ITEM_MEDIA": 0,
        "ITEM_BAJA": 0,
        "COD_VEHICULO": state.validarCheck.codVehiculo,
        "TIPO": state.validarCheck.tipoChecklist,
        "FEC_REP": formattedDate,
        "TIPOCHECKLIST": state.listaCheck.first.tipoCheckList,
        "OPEID": state.listaCheck.first.ope_Id,
        "listaCheck": listaChe,
      };
      String bodyString = json.encode(body);

      ValidarCheckList check = await _sChecklist.Guardar_Editar_CheckList(body: bodyString);

      if (check.rpta == "0") {
        emit(state.copyWith(
          statusGuardarEditarCheck: StatusGuardarEditarCheck.success,
          guardarEditarCheck: check,
        ));
      } else {
        emit(state.copyWith(
          statusGuardarEditarCheck: StatusGuardarEditarCheck.failure,
          guardarEditarCheck: check,
        ));
      }
    });
  }

  _validarUnidadCheck(
    ValidarListarCheckConductorEvent event,
    Emitter<ChecklistState> emit,
  ) async {
    emit(state.copyWith(
      statusValidarCheck: StatusValidarCheck.progress,
      statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
    ));

    ValidarCheckList check = await _sChecklist.Validar_CheckList(tipoDoc: event.tipoDoc, nroDoc: event.nroDoc, placa: event.placa, codOperacion: event.codOperacion, tipoCheckList: event.tipoCheckList);

    if (check.rpta == "0") {
      emit(state.copyWith(
        statusValidarCheck: StatusValidarCheck.success,
        validarCheck: check,
        statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
      ));
    } else {
      emit(state.copyWith(
        statusValidarCheck: StatusValidarCheck.failure,
        validarCheck: check,
        statusGuardarEditarCheck: StatusGuardarEditarCheck.initial,
      ));
    }
  }

  _validarListarEditarUnidadCheck(
    ValidarListarEditarCheckConductorEvent event,
    Emitter<ChecklistState> emit,
  ) async {
    emit(state.copyWith(
      statusValidarCheck: StatusValidarCheck.progress,
      statuslista: statusLista.progress,
      statusGuardarEditarCheck: StatusGuardarEditarCheck.progress,
    ));

    ValidarEditCheckList check = await _sChecklist.ValidarListarEditarCheckList(
      tipoDoc: event.tipoDoc,
      nroDoc: event.nroDoc,
      placa: event.placa,
      codOperacion: event.codOperacion,
    );

    if (check.rpta == "0") {
      emit(state.copyWith(
        statusValidarCheck: StatusValidarCheck.success,
        listaHojaServicio: check.listaCheck,
        mensaje: check.mensaje,
      ));
    } else {
      emit(
        state.copyWith(
          statusValidarCheck: StatusValidarCheck.failure,
          listaHojaServicio: [],
          mensaje: check.mensaje,
        ),
      );
    }
  }
}
