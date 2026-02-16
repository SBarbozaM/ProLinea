import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

part 'conductor2_event.dart';
part 'conductor2_state.dart';

class Conductor2Bloc extends Bloc<Conductor2Event, Conductor2State> {
  final EmbarquesSupScanerServicio _embarquesSupScanerServicio;

  Conductor2Bloc({
    required EmbarquesSupScanerServicio embarquesSupScanerServicio,
  })  : _embarquesSupScanerServicio = embarquesSupScanerServicio,
        super(Conductor2Initial()) {
    on<VincularConductor2>(_vincularConductor2);
  }

  _vincularConductor2(
    VincularConductor2 event,
    Emitter<Conductor2State> emit,
  ) async {
    // String docConductor = event.NDocConductor;

    // int tamCadena = docConductor.length;

    // String ultimoCaracter = docConductor[tamCadena - 1];

    // RegExp _isLetterRegExp = RegExp(r'[a-z]', caseSensitive: false);
    // bool isLetter(String letter) => _isLetterRegExp.hasMatch(letter);

    // if (isLetter(ultimoCaracter)) {
    //   docConductor = docConductor.substring(0, tamCadena - 1);
    // }

    // Response? response =
    //     await _embarquesSupScanerServicio.vincularInicioJornada(
    //         event.nroViaje,
    //         docConductor.trim(),
    //         event.OrdenConductor,
    //         event.TDocUsuario,
    //         event.NDocUsuario,
    //         event.CodOperacion);

    // if (response != null) {
    //   final data = json.decode(response.body);
    //   print(data);
    //   if (data["rpta"] == '0') {
    //     emit(Conductor2Success(
    //       data["tDocConducto1"],
    //       data["nDocConducto1"],
    //       data["nombreConductor"],
    //       data["fechaEmp"],
    //       data["mensaje"],
    //       data["rpta"],
    //     ));
    //   } else {
    //     emit(Conductor2Failure(
    //       data["rpta"],
    //       data["mensaje"],
    //     ));
    //   }
    // } else {
    //   emit(Conductor2Failure(
    //     "500",
    //     "Error al consultar",
    //   ));
    // }
  }
}
