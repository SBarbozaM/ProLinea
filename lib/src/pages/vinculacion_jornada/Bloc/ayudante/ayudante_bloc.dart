import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

part 'ayudante_event.dart';
part 'ayudante_state.dart';

class AyudanteBloc extends Bloc<AyudanteEvent, AyudanteState> {
  final EmbarquesSupScanerServicio _embarquesSupScanerServicio;

  AyudanteBloc({
    required EmbarquesSupScanerServicio embarquesSupScanerServicio,
  })  : _embarquesSupScanerServicio = embarquesSupScanerServicio,
        super(AyudanteInitial()) {
    on<VincularAyudante>(_vincularAyudante);
  }

  _vincularAyudante(
    VincularAyudante event,
    Emitter<AyudanteState> emit,
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
    //       AyudanteSuccess(
    //         data["tDocConducto1"],
    //         data["nDocConducto1"],
    //         data["nombreConductor"],
    //         data["fechaEmp"],
    //         data["mensaje"],
    //         data["rpta"],
    //       ),
    //     );
    //   } else {
    //     emit(AyudanteFailure(
    //       data["rpta"],
    //       data["mensaje"],
    //     ));
    //   }
    // } else {
    //   emit(AyudanteFailure(
    //     "500",
    //     "Error al consultar",
    //   ));
    // }
  }
}
