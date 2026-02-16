import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/warning_widget_internet.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../providers/providers.dart';
import '../../services/viaje_servicio.dart';

class ViajeDomicilioCerrarPage extends StatefulWidget {
  const ViajeDomicilioCerrarPage({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioCerrarPage> createState() => _ViajeDomicilioCerrarPageState();
}

class _ViajeDomicilioCerrarPageState extends State<ViajeDomicilioCerrarPage> {
  bool _cambioDependencia = false;
  late NavigatorState _navigator;
  late Usuario _usuario;
  bool _mostrarCarga = false;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    super.initState();
  }

  @override
  void dispose() {
    Provider.of<DomicilioProvider>(_navigator.context, listen: false).reiniciarProvider();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    setState(() {
      _cambioDependencia = true;
    });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ModalProgressHUD(
                  opacity: 0.0,
                  color: AppColors.whiteColor,
                  progressIndicator: const CircularProgressIndicator(
                    color: AppColors.mainBlueColor,
                  ),
                  inAsyncCall: _mostrarCarga,
                  child: Column(
                    children: [
                      SizedBox(
                        height: height * 0.45,
                      ),
                      // Center(
                      //   child: TextButton(
                      //     style: ButtonStyle(
                      //       foregroundColor: MaterialStateProperty.all<Color>(
                      //           AppColors.whiteColor),
                      //       backgroundColor: MaterialStateProperty.all<Color>(
                      //           _hayConexion2()
                      //               ? AppColors.blueDarkColor
                      //               : AppColors.greyColor),
                      //     ),
                      //     onPressed: !_hayConexion2()
                      //         ? null
                      //         : () async {
                      //             if (_hayConexion()) {
                      //               if (await _puedeCerrarViaje()) {
                      //                 _mostrarModalFinalizar("Finalizar Viaje",
                      //                         "¿Está seguro que desea finalizar el viaje?")
                      //                     .show();
                      //               } else {
                      //                 _mostrarModalRespuesta(
                      //                         "Error",
                      //                         "Desembarque a todos los pasajeros",
                      //                         false)
                      //                     .show();
                      //               }
                      //             } else {
                      //               _mostrarModalRespuesta(
                      //                       "Error",
                      //                       "No tiene conexión a internet",
                      //                       false)
                      //                   .show();
                      //             }
                      //           },
                      //     child: const Text(
                      //       'FINALIZAR VIAJE',
                      //       style: TextStyle(fontSize: 20),
                      //     ),
                      //   ),
                      // ),
                      SizedBox(
                        height: height * 0.1,
                      ),
                      InkWell(
                        child: Text(
                          "SALIR",
                          style: TextStyle(fontSize: 18),
                        ),
                        onTap: () {
                          _cerrarPagina(context);
                          //Navigator.pushNamed(context, 'inicio');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            WarningWidgetInternet(),
          ],
        ),
      ),
    );
  }

  Future<bool> _puedeCerrarViaje() async {
    int pasajerosNoRegistrados = 0;
    int pasajerosEmbarcados = 0;
    int pasajerosDesembarcados = 0;

    ViajeDomicilio viaje = await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 2) {
        pasajerosNoRegistrados++;
      }
      if (viaje.pasajeros[i].embarcado == 1) {
        pasajerosEmbarcados++;
      }
      if (viaje.pasajeros[i].fechaDesembarque != "") {
        pasajerosDesembarcados++;
      }
    }

    if (pasajerosNoRegistrados > 0) return false;

    if (pasajerosEmbarcados == pasajerosDesembarcados)
      return true;
    else
      return false;
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  bool _hayConexion2() {
    if (Provider.of<ConnectionStatusProvider>(context).status.name == 'online')
      return true;
    else
      return false;
  }

  void _cerrarPagina(context) {
    if (_cambioDependencia) context = _navigator.context;

    Navigator.popAndPushNamed(context, 'inicio');
  }

  AwesomeDialog _mostrarModalFinalizar(String titulo, String cuerpo) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      showCloseIcon: true,
      reverseBtnOrder: true,
      buttonsTextStyle: TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        ViajeDomicilio _viajeCerrar = Provider.of<DomicilioProvider>(context, listen: false).viaje;
        ViajeServicio servicio = new ViajeServicio();
        String rpta = "";
        setState(() {
          _mostrarCarga = true;
        });
        rpta = await servicio.finalizarViaje(_viajeCerrar.nroViaje, _viajeCerrar.codOperacion, _usuario);
        setState(() {
          _mostrarCarga = false;
        });
        switch (rpta) {
          case "0":
            _mostrarModalRespuestaCerrarPagina("Finalizado", "Se ha finalizado correctamente el viaje", true).show();
            break;
          case "1":
            _mostrarModalRespuestaCerrarPagina("Error", "Este viaje ya ha sido finalizado", false).show();
            break;
          case "2":
            _mostrarModalRespuestaCerrarPagina("Error", "Al parecer este viaje ya no existe", false).show();
            break;
          case "3":
            _mostrarModalRespuestaCerrarPagina("Error", "Se cerrará la página", false).show();

            break;
          case "9":
            _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
            break;
          default:
            _mostrarModalRespuesta("Error", "Error al procesar la consulta", false).show();
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 2), dismissOnBackKeyPress: false, dismissOnTouchOutside: false);
  }

  AwesomeDialog _mostrarModalRespuestaCerrarPagina(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      autoHide: Duration(seconds: 3),
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      onDismissCallback: (type) async {
        await Provider.of<UsuarioProvider>(context, listen: false).emparejar("", "", "", "", "");
        Navigator.popAndPushNamed(context, 'inicio');
      },
    );
  }
}
