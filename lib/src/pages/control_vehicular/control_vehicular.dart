import 'package:embarques_tdp/src/pages/control_ingreso/control_ingreso.dart';
import 'package:embarques_tdp/src/pages/control_ingreso/control_ingreso_lista.dart';
import 'package:embarques_tdp/src/pages/control_salida/control_salida.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_data.dart';
import 'package:embarques_tdp/src/utils/geo_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

class ControlVehicularPage extends StatefulWidget {
  const ControlVehicularPage({super.key});

  @override
  State<ControlVehicularPage> createState() => _ControlVehicularPageState();
}

class _ControlVehicularPageState extends State<ControlVehicularPage> {
  bool control = false;
  final geo = GeoManager();
  final ValueNotifier<Position?> posicionNotifier = ValueNotifier(null);

  @override
  void initState() {
    geo.iniciar(
      onActualizar: (pos) {
        posicionNotifier.value = pos;
      },
      accuracy: AppData.accuracy,
      distanceFilter: AppData.radioGeocerca,
    );
    super.initState();
  }

  @override
  void dispose() {
    geo.detener();
    posicionNotifier.dispose(); // 🔥 liberar recursos
    super.dispose();
  }

  void cambiarControl(bool nuevoValor) {
    setState(() {
      control = nuevoValor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future(() => true),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    control ? "Control de llegadas" : "Control de salidas",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              CupertinoSwitch(
                applyTheme: true,
                thumbColor: control ? AppColors.greenColor : AppColors.redColor,
                activeColor: Colors.white,
                trackColor: Colors.white,
                value: control,
                onChanged: (bool value) {
                  setState(() {
                    control = value;
                  });
                },
              ),
            ],
          ),
          backgroundColor: control ? AppColors.greenColor : AppColors.redColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          ),
        ),
        body: control ? ControlIngresoPage(posicionNotifier: posicionNotifier) : ControlSalidaPage(posicionNotifier: posicionNotifier),
      ),
    );
  }
}
