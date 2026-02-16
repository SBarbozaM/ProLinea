import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

part 'embarques_sup_scaner_event.dart';
part 'embarques_sup_scaner_state.dart';

class EmbarquesSupScanerBloc
    extends Bloc<EmbarquesSupScanerEvent, EmbarquesSupScanerState> {
  final EmbarquesSupScanerServicio _embarquesSupScanerServicio;

  EmbarquesSupScanerBloc({
    required EmbarquesSupScanerServicio embarquesSupScanerServicio,
  })  : _embarquesSupScanerServicio = embarquesSupScanerServicio,
        super(EmbarquesSupScanerInitial()) {
    on<EscanearUnidad>(_escanearUnidad);
    on<resetEstadoEscanearUnidadInitial>(
        (event, emit) => emit(EmbarquesSupScanerInitial()));
    on<EditarEstadoEscanearUnidadSuccessSup>(
      (event, emit) => emit(
          EmbarquesSupScanerSuccess(event.numConductor, event.numViaje, "")),
    );
  }

  _escanearUnidad(
    EscanearUnidad event,
    Emitter<EmbarquesSupScanerState> emit,
  ) async {
    emit(EmbarquesSupScanerProgress());

    Response? response = await _embarquesSupScanerServicio.ScanearUnidad(
        event.textQR, event.codigoOperacion);

    if (response != null) {
      final data = json.decode(response.body);
      print(data);
      if (data["rpta"] == '0') {
        emit(EmbarquesSupScanerSuccess(
            data["conductores"], data["nroViaje"], data["rpta"]));
      } else {
        emit(EmbarquesSupScanerFailure(data["conductores"] ?? "",
            data["nroViaje"] ?? "", data["rpta"], data["mensaje"]));
      }
    } else {
      emit(EmbarquesSupScanerFailure("0", "0", "9", "Error al consultar"));
    }
  }
}
