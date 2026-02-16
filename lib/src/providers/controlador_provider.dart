import 'package:embarques_tdp/src/models/control_salida.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/controlador_servicio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class ControladorProvider extends ChangeNotifier {
  // ControlSalida controlSalida = ControlSalida();

  // String? errorTextConductor = '';
  // void validateConductorText(String? value) {
  //   value ??= textUnidadController.text;
  //   final text = textConductorController.text;
  //   (text.length < 7) ? errorTextConductor = 'El documento tiene que tener a 8 caracteres' : errorTextConductor = null;
  //   notifyListeners();
  // }

  // String? errorTextUnidad = '';
  // void validateUnidadText(String? value) {
  //   value ??= textUnidadController.text;
  //   final text = textUnidadController.text;
  //   (text.length < 5) ? errorTextUnidad = 'La placa tiene que ser mayor a 5 caracteres' : errorTextUnidad = null;
  //   notifyListeners();
  // }
}
