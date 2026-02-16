import 'package:collection/collection.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/viaje_bolsa_cerrar.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/viaje_bolsa_embarque_conductor.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/viaje_bolsa_embarque_embarcador.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/viaje_bolsa_embarque_supervisor.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/viaje_bolsa_manifiesto.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/viaje_bolsa_sincronizacion.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViajeBolsaNavigationBar extends StatefulWidget {
  const ViajeBolsaNavigationBar({Key? key}) : super(key: key);

  @override
  State<ViajeBolsaNavigationBar> createState() => _ViajeBolsaNavigationBarState();
}

class _ViajeBolsaNavigationBarState extends State<ViajeBolsaNavigationBar> {
  late Usuario _usuario;
  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    super.initState();
  }

  int indexActual = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: paginas[indexActual],
      body: IndexedStack(
        index: indexActual,
        children: [
          //const ViajeInformacionPage(),
          if (_usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUECONDUCTOR") != null) ViajeBolsaEmbarquePage_Conductor(),
          if (_usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUESUPERVISOR") != null) ViajeBolsaEmbarquePage_Supervisor(),
          if (_usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUEEMBARCADOR") != null) ViajeBolsaEmbarquePage_Embarcador(),
          // const ViajeBolsaManifiestoPage(),
          // const ViajeBolsaSincronizacionPage(),
          // const ViajeBolsaCerrarPage()
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.whiteColor,
        selectedItemColor: AppColors.redColor,
        unselectedItemColor: AppColors.greyColor,
        iconSize: 30,
        //selectedFontSize: 15,
        //unselectedFontSize: 10,
        showUnselectedLabels: false,
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
            icon: Icon(Icons.people),
            label: "Manifiesto",
            backgroundColor: Colors.blue,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.cloud_sync),
          //   label: "Sincronizar",
          //   backgroundColor: Colors.blue,
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.logout),
          //   label: "Salir",
          //   backgroundColor: Colors.blue,
          // ),
        ],
      ),
    );
  }
}
