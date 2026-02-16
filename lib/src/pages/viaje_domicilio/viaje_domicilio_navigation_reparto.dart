import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_cerrar.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_embarque_reparto.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_manifiesto.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_mapa_reparto.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';

class ViajeDomicilioNavigationReparto extends StatefulWidget {
  const ViajeDomicilioNavigationReparto({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioNavigationReparto> createState() => _ViajeDomicilioNavigationBarState();
}

class _ViajeDomicilioNavigationBarState extends State<ViajeDomicilioNavigationReparto> {
  int indexActual = 0;
  final paginas = [
    const ViajeDomicilioEmbarqueRepartoPage(),
    const ViajeDomicilioMapaRepartoPage(),
    const ViajeDomicilioManifiestoPage(),
    //const ViajeDomicilioSincronizacionPage(),
    // const ViajeDomicilioCerrarPage()
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //body: paginas[indexActual],
      body: IndexedStack(
        index: indexActual,
        children: paginas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.whiteColor,
        selectedItemColor: AppColors.redColor,
        unselectedItemColor: AppColors.greyColor,
        iconSize: 30,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        selectedFontSize: 14,
        unselectedFontSize: 13,
        showUnselectedLabels: true,
        currentIndex: indexActual,
        onTap: (index) {
          if (index == 0) {
            Log.insertarLogDomicilio(context: context, mensaje: "REPARTO: Ingresa a la pantalla reparto", rpta: "OK");
          }
          if (index == 1) {
            Log.insertarLogDomicilio(context: context, mensaje: "REPARTO: Ingresa a la pantalla del mapa", rpta: "OK");
          }
          if (index == 2) {
            Log.insertarLogDomicilio(context: context, mensaje: "REPARTO: Ingresa a la pantalla del manifiesto", rpta: "OK");
          }
          setState(() {
            indexActual = index;
          });
        },
        items: const [
          /*BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: "Información",
              backgroundColor: Colors.blue),*/
          BottomNavigationBarItem(
            icon: Icon(Icons.departure_board),
            label: "Reparto",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Mapa",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Manifiesto",
            backgroundColor: Colors.blue,
          ),
          /*BottomNavigationBarItem(
            icon: Icon(Icons.cloud_sync),
            label: "Sincronizar",
            backgroundColor: Colors.blue,
          ),*/
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.lock),
          //   label: "Finalizar",
          //   backgroundColor: Colors.blue,
          // ),
        ],
      ),
    );
  }
}
