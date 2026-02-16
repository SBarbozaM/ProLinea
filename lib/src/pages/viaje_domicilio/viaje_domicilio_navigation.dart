import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_cerrar.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_embarque.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_manifiesto.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_mapa.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ViajeDomicilioNavigationBar extends StatefulWidget {
  const ViajeDomicilioNavigationBar({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioNavigationBar> createState() =>
      _ViajeDomicilioNavigationBarState();
}

class _ViajeDomicilioNavigationBarState
    extends State<ViajeDomicilioNavigationBar> {
  int indexActual = 0;
  final paginas = [
    const ViajeDomicilioEmbarquePage(),
    const ViajeDomicilioMapaPage(),
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
            label: "Embarque",
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
