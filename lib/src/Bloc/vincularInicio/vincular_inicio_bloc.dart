import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';

part 'vincular_inicio_event.dart';
part 'vincular_inicio_state.dart';

class VincularInicioBloc extends Bloc<VincularInicioEvent, VincularInicioState> {
  final EmbarquesSupScanerServicio _embarquesSupScanerServicio;

  VincularInicioBloc({
    required EmbarquesSupScanerServicio embarquesSupScanerServicio,
  })  : _embarquesSupScanerServicio = embarquesSupScanerServicio,
        super(VincularInicioInitial()) {
    on<VincularConductor>(_vincularConductor);
    on<resetEstadoVincularInitial>((event, emit) => emit(VincularInicioInitial()));

    on<EditarEstadoVincularSuccess>((event, emit) => emit(VincularInicioSuccess(event.tDocConducto1, event.nDocConducto1, "", "")));
  }

  _vincularConductor(
    VincularConductor event,
    Emitter<VincularInicioState> emit,
  ) async {
    emit(VincularInicioProgress());

    String docConductor = event.NDocConductor;

    int tamCadena = docConductor.length;

    String ultimoCaracter = docConductor[tamCadena - 1];

    RegExp _isLetterRegExp = RegExp(r'[a-z]', caseSensitive: false);
    bool isLetter(String letter) => _isLetterRegExp.hasMatch(letter);

    if (isLetter(ultimoCaracter)) {
      docConductor = docConductor.substring(0, tamCadena - 1);
    }

    if (await Permission.location.request().isGranted) {}

    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    Response? response = await _embarquesSupScanerServicio.vincularInicio_v2(
      event.nroViaje,
      docConductor.trim(),
      event.TDocUsuario,
      event.NDocUsuario,
      event.CodOperacion,
      posicionActual,
    );

    if (response != null) {
      final data = json.decode(response.body);
      print(data);
      if (data["rpta"] == '0') {
        emit(VincularInicioSuccess(
          data["tDocConducto1"],
          data["nDocConducto1"],
          data["mensaje"],
          data["rpta"],
        ));
      } else {
        emit(VincularInicioFailure(
          data["rpta"],
          data["mensaje"],
        ));
      }
    } else {
      emit(VincularInicioFailure(
        "500",
        "Error al consultar",
      ));
    }
  }
}
