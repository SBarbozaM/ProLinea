import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/warning_widget_internet.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../models/viaje.dart';
import '../../providers/providers.dart';
import '../../services/viaje_servicio.dart';

class ViajeBolsaCerrarPage extends StatefulWidget {
  const ViajeBolsaCerrarPage({Key? key}) : super(key: key);

  @override
  State<ViajeBolsaCerrarPage> createState() => _ViajeBolsaCerrarPageState();
}

class _ViajeBolsaCerrarPageState extends State<ViajeBolsaCerrarPage> {
  late Timer _timer;
  bool _cambioDependencia = false;
  bool _mostrarCarga = false;

  late NavigatorState _navigator;
  late Usuario _usuario;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _timer = new Timer.periodic(Duration(seconds: 2), (timer) {
      /*Provider.of<ViajeProvider>(context, listen: false)
          .sincronizacionContinuaDeViaje(_usuario.tipoDoc, _usuario.numDoc);*/
      //setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();

    Provider.of<ViajeProvider>(_navigator.context, listen: false).reiniciarProvider();
    Provider.of<PrereservaProvider>(_navigator.context, listen: false).reiniciarProvider();
    Provider.of<PasajeroProvider>(_navigator.context, listen: false).reiniciarProvider();

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
        body: ModalProgressHUD(
          opacity: 0.0,
          color: AppColors.whiteColor,
          progressIndicator: const CircularProgressIndicator(
            color: AppColors.mainBlueColor,
          ),
          inAsyncCall: _mostrarCarga,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: height * 0.45,
                      ),
                      Center(
                        child: TextButton(
                          style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(AppColors.whiteColor),
                            backgroundColor: MaterialStateProperty.all<Color>(_hayConexion2() ? AppColors.blueDarkColor : AppColors.greyColor),
                          ),
                          onPressed: !_hayConexion2()
                              ? null
                              : () async {
                                  if (_hayConexion()) {
                                    _mostrarModalFinalizar("Finalizar Viaje", "¿Estás seguro que desea finalizar el viaje?").show();
                                  } else {
                                    _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
                                  }
                                },
                          child: const Text(
                            'FINALIZAR VIAJE',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: height * 0.1,
                      ),
                      InkWell(
                        child: Text(
                          "SALIR",
                          style: TextStyle(fontSize: 18),
                        ),
                        onTap: () {
                          _cerrarSoloPagina(context);
                          //Navigator.pushNamed(context, 'inicio');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              WarningWidgetInternet(),
            ],
          ),
        ),
      ),
    );
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

  void _cerrarSoloPagina(context) {
    if (_cambioDependencia) context = _navigator.context;

    Navigator.popAndPushNamed(context, 'inicio');
  }
  //finalizarviaje-gps
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
        Viaje _viajeCerrar = Provider.of<ViajeProvider>(context, listen: false).viaje;
        ViajeServicio servicio = new ViajeServicio();
        String rpta = "";
        setState(() {
          _mostrarCarga = true;
        });

        if (await Permission.location.request().isGranted) {}

        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        rpta = await servicio.finalizarViajeV5(
          _viajeCerrar.nroViaje,
          _viajeCerrar.codOperacion,
          _usuario,
          _viajeCerrar.odometroFinal.toString(),
          posicionActual,
          'NOGPS',
        );

        setState(() {
          _mostrarCarga = false;
        });
        switch (rpta) {
          case "0":
            _mostrarModalRespuestaCerrarPagina("Finalizado", "Se ha finalizado correctamente el viaje", true, _viajeCerrar).show();
            break;
          case "1":
            _mostrarModalRespuestaCerrarPagina("Error", "Este viaje ya ha sido finalizado", false, _viajeCerrar).show();
            break;
          case "2":
            /*_mensajeCerrado(
                                                            "Al parecer este viaje ya no existe.",
                                                            true);*/

            _mostrarModalRespuestaCerrarPagina("Error", "Al parecer este viaje ya no existe", false, _viajeCerrar).show();
            break;
          case "3":
            _mostrarModalRespuestaCerrarPagina("Error", "Se cerrará la página", false, _viajeCerrar).show();

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

  AwesomeDialog _mostrarModalRespuestaCerrarPagina(String titulo, String cuerpo, bool success, Viaje viaje) {
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
        await AppDatabase.instance.eliminarTodoDeUnViaje(viaje.nroViaje);
        Navigator.popAndPushNamed(context, 'inicio');
      },
    );
  }
}
