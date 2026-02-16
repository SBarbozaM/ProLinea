import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

part 'conductor1_event.dart';
part 'conductor1_state.dart';

class Conductor1Bloc extends Bloc<Conductor1Event, Conductor1State> {
  final EmbarquesSupScanerServicio _embarquesSupScanerServicio;

  Conductor1Bloc({
    required EmbarquesSupScanerServicio embarquesSupScanerServicio,
  })  : _embarquesSupScanerServicio = embarquesSupScanerServicio,
        super(Conductor1Initial()) {
    on<VincularConductor1>(_vincularConductor1);
  }

  _vincularConductor1(
    VincularConductor1 event,
    Emitter<Conductor1State> emit,
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
    //     emit(
    //       Conductor1Success(
    //         data["tDocConducto1"],
    //         data["nDocConducto1"],
    //         data["nombreConductor"],
    //         data["fechaEmp"],
    //         data["mensaje"],
    //         data["rpta"],
    //       ),
    //     );
    //   } else {
    //     emit(Conductor1Failure(
    //       data["rpta"],
    //       data["mensaje"],
    //     ));
    //   }
    // } else {
    //   emit(Conductor1Failure(
    //     "500",
    //     "Error al consultar",
    //   ));
    // }
  }
}
