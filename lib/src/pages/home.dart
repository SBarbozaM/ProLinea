// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:collection/collection.dart';
import 'package:embarques_tdp/src/components/webview_basica.dart';
import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:embarques_tdp/src/models/actual_version.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/models/usuario-geop.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/pages/inicio.dart';
import 'package:embarques_tdp/src/services/actual_version.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/usuario-geop.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/jornada.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/paradero.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/pages/jornada/bloc/jornada/jornada_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/unidad/unidad_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_jornadaPage.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:embarques_tdp/src/utils/app_data.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/providers.dart';

import 'package:embarques_tdp/src/Bloc/unidadScaner/embarques_sup_scaner_bloc.dart';
import 'package:embarques_tdp/src/Bloc/vincularInicio/vincular_inicio_bloc.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pasajero.dart';
import '../models/viaje.dart';
import '../services/google_services.dart';
import '../services/viaje_servicio.dart';
import '../utils/app_database.dart';
import '../services/onesignal_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OneSignalService oneSignalService = OneSignalService();
  Usuario usuarioActual = Usuario(
    tipoDoc: "",
    numDoc: "",
    rpta: "",
    clave: "",
    usuarioId: "0",
    apellidoPat: "",
    apellidoMat: "",
    nombres: "",
    perfil: "",
    codOperacion: "",
    nombreOperacion: "",
    equipo: "",
  );

  late NavigatorState _navigator;
  bool _cambioDependencia = false;
  late Usuario _usuario;
  final TextEditingController _odometroController = TextEditingController();
  TextEditingController textClaveMaestraController = TextEditingController();
  final FocusNode _focusOdometro = FocusNode();
  late Timer _timer;
  late Timer _timer2 = Timer(Duration.zero, () {});

  int pasajeroRecojoEmbarcados = 0;
  int pasajeroRecojoPendiente = 0;
  int pasajeroRecojoNoEmbarcado = 0;

  int pasajeroRepartoEmbarcados = 0;
  int pasajeroRepartoPendiente = 0;
  int pasajeroRepartoNoEmbarcado = 0;

  bool odometroObtenido = false;

  @override
  void initState() {
    super.initState();
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    if (_usuario.viajeEmp != "" && _usuario.idPerfil == '11') {
      context.read<JornadaBloc>().add(Listarjornadas(_usuario.viajeEmp));
      // SincronizarJornadasBD();
    }
    // ObtieneViajeDomicilioRemote();
    actualizarViajeLocal();
    actualizarViajeLocalBOlsa();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_timer2.isActive) {
        _timer2 = Timer.periodic(const Duration(seconds: 10), (timer2) {
          if (_hayConexion()) {
            if (_timer2.tick == 1) {
              sincronizarViaje();
              sincronizarViajeBolsa();
              sincronizarJornadasBD();
            }
          } else {
            _timer2.cancel();
          }

          setState(() {});
        });
      }

      //actualizar los datos del viaje cada 10 segundos
    });
    // oneSignalService.init(context);
    // super.initState();
    // OneSignal.shared.setNotificationWillShowInForegroundHandler((notification) {
    //   print('Notification received in foreground: ${notification.jsonRepresentation()}');
    //   notification.complete(notification.notification); // Muestra la notificación
    // });

    // OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    //   // Obtener datos adicionales de la notificación
    //   Map<String, dynamic> additionalData = result.notification.additionalData ?? {};

    //   // Imprimir los datos adicionales para depuración
    //   print('Notification opened: ${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}');
    //   print('Additional Data: $additionalData');

    //   // Navegar a la ruta especificada en los datos de la notificación

    //   // String? page = additionalData['page'];
    //   String? idsubauth = additionalData['idsubauth'];
    //   String? page = additionalData['page'];
    //   String? titulo = additionalData['titulo'];
    //   String? orden = additionalData['orden'];
    //   String? idauth = additionalData['idauth'];
    //   String? stitle = additionalData['stitle'];

    //   if (page != null && page.isNotEmpty) {
    //     final authIdModel = Provider.of<AuthIdModel>(context, listen: false);

    //     authIdModel.updateAuthData(idauth!, stitle!);

    //     final subauthIdModel = Provider.of<SubAuthIdModel>(context, listen: false);
    //     final subAuthAction = SubAuthActionModel(idsubauth!, titulo!, orden!);
    //     subauthIdModel.updateAuthAction(subAuthAction);

    //     Navigator.of(context).pushNamedAndRemoveUntil(page, (Route<dynamic> route) => false);
    //   }
    // });

    // OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    //   print('Notification opened3wdw3: \n${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}');
    //   print('Additional Data: ${result.notification.additionalData}');
    //   print('Additiondeal Data: ${result.action}');
    //   // print('data: \n${result.da}')
    //   reloadMainPage(context);
    // });
  }

  void reloadMainPage(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const InicioPage()), // Reemplaza MainPage con tu página principal
      (Route<dynamic> route) => false,
    );
  }

  // void recieveNotification(OSNotificationOpenedResult openedResult) {
  //   ///var pages = Pages();
  //   var data = openedResult.notification.additionalData;
  //   // print(openedResult.notification.additionalData);
  //   if (data != null && data["type"] != null) {
  //     if (data["type"] == "action") {
  //       pages.setToAction(
  //         type: data["page"],
  //         context: context,
  //         url: data["url"] ?? "",
  //         data: data["data"] ?? {},
  //       );
  //     }
  //     if (data["type"] == "page") {
  //       pages.setToPage(type: data["page"], context: context);
  //     }
  //   }
  //   // if (data["page"] == "track_bus") {
  //   //   Future.delayed(Duration(milliseconds: 500), () {
  //   //     _onItemTapped(3);
  //   //   });
  //   // }
  //   // if (data["page"] == "my_buys") {
  //   //   AnimationRoutes.animationRoute(
  //   //     context: context,
  //   //     widget: MyTravelPage(
  //   //       type: 1,
  //   //     ),
  //   //   );
  //   // }
  // }

  actualizarViajeLocal() async {
    List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio", where: "seleccionado = '1'");

    List<Map<String, Object?>> listaViajeDomi = [...listaViajeDomicilio];

    if (listaViajeDomi.isNotEmpty) {
      ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajeDomi[0]);

      await Provider.of<DomicilioProvider>(_navigator.context, listen: false).actualizarViaje(viaje);
    }
  }

  actualizarViajeLocalBOlsa() async {
    List<Map<String, Object?>> listaViaje = await AppDatabase.instance.Listar(tabla: "viaje", where: "seleccionado = '1'");

    List<Map<String, Object?>> listaViajeBolsa = [...listaViaje];

    if (listaViajeBolsa.isNotEmpty) {
      Viaje viaje = await actualizarViajeEmbarqueBolsaBDLocal(listaViajeBolsa[0]);

      await Provider.of<ViajeProvider>(_navigator.context, listen: false).viajeActual(viaje: viaje);
    }
  }

  sincronizarViaje() async {
    if (_hayConexion()) {
      List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");
      List<Map<String, Object?>> listaViajeDomi = [...listaViajeDomicilio];
      if (listaViajeDomi.isNotEmpty) {
        for (var i = 0; i < listaViajeDomi.length; i++) {
          ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajeDomi[i]);

          if (viaje.sentido == "I") {
            await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
          } else if (viaje.sentido == "R") {
            await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioRepartoDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
          }
        }
      }
    }
    _timer2.cancel();
  }

  sincronizarViajeBolsa() async {
    List<Map<String, Object?>> listaViajesBolsa = await AppDatabase.instance.Listar(tabla: "viaje");
    List<Map<String, Object?>> listaViajeBolsa = [...listaViajesBolsa];
    if (listaViajeBolsa.isNotEmpty) {
      for (var i = 0; i < listaViajeBolsa.length; i++) {
        Viaje viaje = await actualizarViajeEmbarqueBolsaBDLocal(listaViajeBolsa[i]);
        if (_hayConexion()) {
          Provider.of<ViajeProvider>(context, listen: false).sincronizacionContiniaDeViajeBolsaDesdeHome(
            _usuario.tipoDoc,
            _usuario.numDoc,
            _usuario.codOperacion,
            context,
            viaje,
          );
          setState(() {});
          //actualizar los datos del viaje cada 10 segundos
        }
      }
    }
    _timer2.cancel();
  }

  @override
  void dispose() {
    _timer.cancel();
    _timer2.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    setState(() {
      _cambioDependencia = true;
    });
    super.didChangeDependencies();

    verificarVersion();
  }

  bool _esEmbarque(ViajeDomicilio viaje) {
    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 2) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<UsuarioProvider>(context).usuario;
    usuarioActual = usuario;
    double width = MediaQuery.of(context).size.width;
    ViajeDomicilio viaje0 = Provider.of<DomicilioProvider>(context).viaje;
    bool esEmbarque = _esEmbarque(viaje0);

    return BlocListener<JornadaBloc, JornadaState>(
      listener: (context, state) {
        // if (state.code == "1") {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     new SnackBar(
        //       content: Text(
        //         state.mensaje,
        //         style: TextStyle(color: AppColors.whiteColor),
        //       ),
        //       backgroundColor: AppColors.redColor,
        //     ),
        //   );
        //   Navigator.pop(context);
        //   // Navigator.pop(context);
        // }

        if (state.code == "3") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.mensaje,
                style: const TextStyle(color: AppColors.whiteColor),
              ),
              backgroundColor: AppColors.greenColor,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.grey.shade200,
          // backgroundColor: Colors.red.shade500,
          body: SafeArea(
            child: CustomScrollView(
              primary: false,
              slivers: <Widget>[
                SliverAppBar(
                  shape: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.whiteColor,
                  toolbarHeight: 70,
                  pinned: true,
                  elevation: 20,
                  shadowColor: Colors.transparent,
                  title: GestureDetector(
                    onLongPress: () async {
                      _insertarEventoAnalytics('press_liberar', usuario, '');

                      _showDialogBDLimpiarLocalCONFIRMAR(
                        context: context,
                        titulo: "Liberar equipo",
                        mensaje: "Para forzar la liberación del equipo con el viaje iniciado, por favor, ingrese la contraseña de autorización.",
                      );
                    },
                    child: SizedBox(
                      height: 70,
                      width: width,
                      child: const Image(
                        image: AssetImage(
                          "assets/images/appBusLogo2.png",
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // actions: [
                  //   IconButton(
                  //     onPressed: () {},
                  //     icon: Icon(
                  //       Icons.cleaning_services,
                  //       color: Colors.green,
                  //     ),
                  //   )
                  // ],
                ),
                // SliverToBoxAdapter(
                //   child: BlocBuilder<JornadaBloc, JornadaState>(
                //     builder: (context, state) {
                //       if (_usuario.viajeEmp != "")
                //         return Container(
                //           padding: EdgeInsets.only(top: 5, bottom: 5),
                //           alignment: Alignment.center,
                //           width: width,
                //           decoration: BoxDecoration(
                //             color: AppColors.whiteColor,
                //           ),
                //           child: Text(
                //             "Vinculación Activada",
                //             style: TextStyle(
                //               color: AppColors.mainBlueColor,
                //               fontSize: 17,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         );
                //       return Container();
                //     },
                //   ),
                // ),
                //
                // SliverToBoxAdapter(
                //   child: BlocBuilder<JornadaBloc, JornadaState>(
                //     builder: (context, state) {
                //       if (state.idJornadaActual != "")
                //         return Container(
                //           padding: EdgeInsets.only(top: 5, bottom: 5),
                //           alignment: Alignment.center,
                //           width: width,
                //           decoration: BoxDecoration(
                //             color: AppColors.whiteColor,
                //           ),
                //           child: Text(
                //             "Jornada Actual: ${state.NombreJornadaActual}",
                //             style: TextStyle(
                //               color: AppColors.mainBlueColor,
                //               fontSize: 17,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         );
                //       return Container();
                //     },
                //   ),
                // ),
                SliverPadding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 43),
                  sliver: SliverGrid.count(
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 5,
                    crossAxisCount: 2,
                    children: <Widget>[
                      //VINCULAR JORNADA CONDUCTOR INTEPROVINCIAL
                      // if (_usuario.acciones.firstWhereOrNull((accion) =>
                      //         accion.toUpperCase() == "VERVINCULARJORNADA") !=
                      //     null)
                      //   GestureDetector(
                      //     onTap: _usuario.viajeEmp != ""
                      //         ? () {                      //
                      //             _showDialogFinalizarViaje(context).show();
                      //           }
                      //         : () {
                      //             //Navigator.pop(context);
                      //             //Navigator.popAndPushNamed(context, 'emparejarQR');
                      //
                      //             context
                      //                 .read<UnidadBloc>()
                      //                 .add(resetEstadoUnidadInitial());
                      //
                      //             Navigator.of(context).pushNamedAndRemoveUntil(
                      //                 'vinculacionJornada',
                      //                 (Route<dynamic> route) => false);
                      //           },
                      //     child: Card(
                      //       shape: const RoundedRectangleBorder(
                      //         borderRadius: const BorderRadius.all(
                      //           Radius.circular(20),
                      //         ),
                      //       ),
                      //       child: Column(
                      //         mainAxisAlignment: MainAxisAlignment.center,
                      //         crossAxisAlignment: CrossAxisAlignment.center,
                      //         children: [
                      //           SizedBox(
                      //             width:
                      //                 MediaQuery.of(context).size.width * 0.35,
                      //             height:
                      //                 MediaQuery.of(context).size.width * 0.32,
                      //             child: FittedBox(
                      //               child: ImagesCardHome(
                      //                   image:
                      //                       "${_usuario.viajeEmp != "" ? "assets/images/Iconos_Vincular_check.png" : "assets/images/Iconos_Vincular.png"}"),
                      //             ),
                      //           ),
                      //           Container(
                      //             width:
                      //                 MediaQuery.of(context).size.width * 0.35,
                      //             padding: EdgeInsets.symmetric(horizontal: 5),
                      //             decoration: BoxDecoration(
                      //               color: _usuario.viajeEmp != ""
                      //                   ? AppColors.greenColor
                      //                   : Color(0xFFe42313),
                      //               borderRadius: BorderRadius.circular(20),
                      //             ),
                      //             alignment: Alignment.center,
                      //             child: Text(
                      //               "${_usuario.viajeEmp != "" ? "${_usuario.placaEmp}" : "Vincular"}",
                      //               style: TextStyle(
                      //                 color: AppColors.whiteColor,
                      //                 fontWeight: FontWeight.bold,
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),

                      //VINCULAR CONDUCTOR BOLSA, INTERPROVINCIAL
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERVINCULAR") != null && usuario.domicilio == '0')
                        GestureDetector(
                          onTap: usuario.viajeEmp != "" && usuario.vinculacionActiva != "0"
                              ? () async {
                                  _insertarEventoAnalytics('opc_${usuario.viajeEmp}' != "" && usuario.vinculacionActiva != "0" ? "finalizar_viaje" : "iniciar_viaje", usuario, 'VERVINCULAR');

                                  _showDialogSincronizandoDatos(context, "Cargando...");
                                  setState(() {
                                    _odometroController.text = "";
                                  });

                                  Viaje viaje1 = Provider.of<ViajeProvider>(context, listen: false).viaje;

                                  // _showDialogFinalizarViajeBolsaORInteprovincial(context, _viaje).show();

                                  Map<String, dynamic> odometroDato = await obtenerOdometroViaje(usuario.unidadEmp);

                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }

                                  if (odometroDato["rpta"] == "0") {
                                    _showDialogFinalizarViajeBolsaORInteprovincialSinOdometro(context, viaje1, odometroDato["mensaje"]).show();
                                  } else {
                                    _showDialogFinalizarViajeBolsaORInteprovincial(context, viaje1).show();
                                  }
                                }
                              : () {
                                  //Navigator.pop(context);
                                  //Navigator.popAndPushNamed(context, 'emparejarQR');

                                  context.read<UnidadBloc>().add(resetEstadoUnidadInitial());
                                  Navigator.of(context).pushNamedAndRemoveUntil('vinculacionBolsa', (Route<dynamic> route) => false);
                                },
                          child: Card(
                            elevation: 1,
                            color: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 7,
                                  right: 12,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        height: MediaQuery.of(context).size.width * 0.32,
                                        child: FittedBox(
                                          child: ImagesCardHome(image: usuario.viajeEmp != "" && usuario.vinculacionActiva != "0" ? "assets/images/Iconos_Vincular_verde.png" : "assets/images/Iconos_Vincular.png"),
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        padding: const EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: usuario.viajeEmp != "" && usuario.vinculacionActiva != "0" ? const Color(0xFF0A5713) : const Color(0xFFe42313),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          usuario.viajeEmp != "" && usuario.vinculacionActiva != "0" ? "Finalizar viaje" : "Iniciar viaje",
                                          style: const TextStyle(
                                            color: AppColors.whiteColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    top: 5,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showDialogSincronizandoDatos(context, "Cargando...");

                                        _obtenerDatosVinculacion(context);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(color: AppColors.mainBlueColor, borderRadius: BorderRadius.circular(20)),
                                        width: 25,
                                        height: 25,
                                        child: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),

                      //VINCULAR EMBARCADOR BOLSA
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERVINCULAREMBARCADOR") != null && usuario.domicilio == '0')
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_${usuario.viajeEmp}' != "" ? "finalizar_embarque" : "iniciar_embarque", usuario, 'VERVINCULAREMBARCADOR');

                            ////Shared Preferences
                            final SharedPreferences pref = await SharedPreferences.getInstance();

                            String? usuarioVinculado = pref.getString("usuarioVinculado");

                            if (usuarioVinculado == null || jsonDecode(usuarioVinculado)["numViaje"] == "") {
                              context.read<EmbarquesSupScanerBloc>().add(resetEstadoEscanearUnidadInitial());

                              context.read<VincularInicioBloc>().add(resetEstadoVincularInitial());

                              Navigator.of(context).pushNamedAndRemoveUntil('embarquesSupervisorScaner', (Route<dynamic> route) => false);
                            } else {
                              ViajeDomicilio viaje2 = Provider.of<DomicilioProvider>(context, listen: false).viaje;

                              _showDialogFinalizarViajeBolsSupervisorEmbarcador(context, viaje2).show();
                            }
                          },
                          child: Card(
                            elevation: 1,
                            color: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 7,
                                  right: 12,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        height: MediaQuery.of(context).size.width * 0.32,
                                        child: FittedBox(
                                          child: ImagesCardHome(image: usuario.viajeEmp != "" ? "assets/images/Iconos_Vincular_verde.png" : "assets/images/Iconos_Vincular.png"),
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        padding: const EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: usuario.viajeEmp != "" ? const Color(0xFF0A5713) : const Color(0xFFe42313),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          usuario.viajeEmp != "" ? "Finalizar Embarque" : "Iniciar Embarque",
                                          style: const TextStyle(
                                            color: AppColors.whiteColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    top: 5,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () async {
                                        _showDialogSincronizandoDatos(context, "Cargando...");
                                        final SharedPreferences pref = await SharedPreferences.getInstance();
                                        String? usuarioVinculado = pref.getString("usuarioVinculado");
                                        if (usuarioVinculado != null) {
                                          final usuarioObjeto = jsonDecode(usuarioVinculado);
                                          _obtenerDatosVinculacionSupervisorOREmbarcador(
                                            context,
                                            usuarioObjeto["tDocConductor"],
                                            usuarioObjeto["nDocConductor"].toString().trim(),
                                          );
                                        } else {
                                          _obtenerDatosVinculacionSupervisorOREmbarcador(
                                            context,
                                            '',
                                            '',
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(color: AppColors.mainBlueColor, borderRadius: BorderRadius.circular(20)),
                                        width: 25,
                                        height: 25,
                                        child: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),

                      //VINCULAR SUPERVISOR BOLSA
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERVINCULARSUPERVISOR") != null && usuario.domicilio == '0')
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_${usuario.viajeEmp}' != "" ? "finalizar_embarque" : "iniciar_embarque", usuario, 'VERVINCULARSUPERVISOR');

                            ////Shared Preferences
                            final SharedPreferences pref = await SharedPreferences.getInstance();

                            String? usuarioVinculado = pref.getString("usuarioVinculado");

                            if (usuarioVinculado == null || jsonDecode(usuarioVinculado)["numViaje"] == "") {
                              context.read<EmbarquesSupScanerBloc>().add(resetEstadoEscanearUnidadInitial());

                              context.read<VincularInicioBloc>().add(resetEstadoVincularInitial());

                              Navigator.of(context).pushNamedAndRemoveUntil('embarquesSupervisorScaner', (Route<dynamic> route) => false);
                            } else {
                              ViajeDomicilio viaje3 = Provider.of<DomicilioProvider>(context, listen: false).viaje;

                              _showDialogFinalizarViajeBolsSupervisorEmbarcador(context, viaje3).show();
                            }
                          },
                          child: Card(
                            elevation: 1,
                            color: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 7,
                                  right: 12,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        height: MediaQuery.of(context).size.width * 0.32,
                                        child: FittedBox(
                                          child: ImagesCardHome(image: usuario.viajeEmp != "" ? "assets/images/Iconos_Vincular_verde.png" : "assets/images/Iconos_Vincular.png"),
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        padding: const EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: usuario.viajeEmp != "" ? const Color(0xFF0A5713) : const Color(0xFFe42313),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          usuario.viajeEmp != "" ? "Finalizar Embarque" : "Iniciar Embarque",
                                          style: const TextStyle(
                                            color: AppColors.whiteColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    top: 5,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () async {
                                        _showDialogSincronizandoDatos(context, "Cargando...");
                                        final SharedPreferences pref = await SharedPreferences.getInstance();
                                        String? usuarioVinculado = pref.getString("usuarioVinculado");
                                        if (usuarioVinculado != null) {
                                          final usuarioObjeto = jsonDecode(usuarioVinculado);
                                          _obtenerDatosVinculacionSupervisorOREmbarcador(
                                            context,
                                            usuarioObjeto["tDocConductor"],
                                            usuarioObjeto["nDocConductor"].toString().trim(),
                                          );
                                        } else {
                                          _obtenerDatosVinculacionSupervisorOREmbarcador(
                                            context,
                                            '',
                                            '',
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(color: AppColors.mainBlueColor, borderRadius: BorderRadius.circular(20)),
                                        width: 25,
                                        height: 25,
                                        child: const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),

                      //VINCULAR CONDUCTOR  DOMICILIO
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERVINCULAR") != null && usuario.domicilio == '1')
                        GestureDetector(
                          onTap: usuario.viajeEmp != "" && usuario.vinculacionActiva != "0"
                              ? () async {
                                  _insertarEventoAnalytics('opc_${Provider.of<UsuarioProvider>(context).usuario.vinculacionActiva}' == "1" ? "finalizar_viaje" : "iniciar_viaje", usuario, 'VERVINCULAR/DOMICILIO');

                                  bool isEmbarque = false;

                                  setState(() {
                                    _odometroController.text = "";
                                  });

                                  ViajeDomicilio viaje4 = Provider.of<DomicilioProvider>(context, listen: false).viaje;

                                  if (viaje4.sentido == "I") {
                                    for (int i = 0; i < viaje4.pasajeros.length; i++) {
                                      if (viaje4.pasajeros[i].embarcado == 2) {
                                        isEmbarque = true;
                                      }
                                    }

                                    if (isEmbarque == true) {
                                      Log.insertarLogDomicilio(context: context, mensaje: "No puede finalizar el viaje porque existen pasajeros en pendiente embarque. # pasajeros :${viaje4.pasajeros.fold(0, (previousValue, element) => element.embarcado == 2 ? previousValue + 1 : previousValue)}", rpta: "OK");

                                      return _mostrarModalRespuesta("No puedes finalizar", "Existen pasajeros en pendiente embarque.", false).show();
                                    }
                                  }

                                  if (viaje4.sentido == "R") {
                                    bool reportoCompleto = false;
                                    int cantidadRepartidos = calcularCantidadRepartidos(viaje4);
                                    int cantidadEmbarcados = calcularCantidadEmbarcados(viaje4);

                                    if (cantidadRepartidos == cantidadEmbarcados) {
                                      reportoCompleto = true;
                                    }
                                    if (reportoCompleto == false) {
                                      Log.insertarLogDomicilio(context: context, mensaje: "No puede finalizar el viaje porque existen pasajeros en pendiente reparto. # pasajeros : ${cantidadEmbarcados - cantidadRepartidos}", rpta: "OK");

                                      return _mostrarModalRespuesta("No puedes finalizar", "Existen pasajeros en pendiente reparto.", false).show();
                                    }
                                  }

                                  Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal finalizar viaje", rpta: "OK");
                                  _showDialogFinalizarViaje(context, viaje4).show();
                                }
                              : () {
                                  if (usuario.domicilio == "1") {
                                    Log.insertarLogDomicilio(context: context, mensaje: "Ingreso a iniciar viaje", rpta: "OK");

                                    Navigator.of(context).pushNamedAndRemoveUntil('vinculacionDomicilio', (Route<dynamic> route) => false);
                                  }
                                },
                          child: Card(
                            elevation: 1,
                            color: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 12,
                                  left: 16,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.34,
                                        height: MediaQuery.of(context).size.width * 0.30,
                                        child: FittedBox(
                                          child: ImagesCardHome(
                                            image: Provider.of<UsuarioProvider>(context).usuario.vinculacionActiva == "1" ? "assets/images/Iconos_Vincular_verde.png" : "assets/images/Iconos_Vincular.png",
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        padding: const EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: Provider.of<UsuarioProvider>(context).usuario.vinculacionActiva == "1" ? const Color(0xFF0A5713) : const Color(0xFFe42313),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          Provider.of<UsuarioProvider>(context).usuario.vinculacionActiva == "1" ? "Finalizar viaje" : "Iniciar viaje",
                                          style: const TextStyle(
                                            color: AppColors.whiteColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal cargando", rpta: "OK");

                                      _showDialogSincronizandoDatos(context, "Cargando...");

                                      _obtenerDatosVinculacion(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(color: AppColors.mainBlueColor, borderRadius: BorderRadius.circular(20)),
                                      width: 25,
                                      height: 25,
                                      child: const Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                if (usuario.vinculacionActiva == '1' && Provider.of<DomicilioProvider>(context, listen: true).viaje.sentido == 'I')
                                  Positioned(
                                    right: 3,
                                    top: MediaQuery.of(context).size.width * 0.15,
                                    child: SizedBox(
                                      height: MediaQuery.of(context).size.width * 0.12,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Material(
                                            elevation: 1,
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              alignment: Alignment.center,
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color: Colors.amber,
                                              ),
                                              child: Text(
                                                "${Provider.of<DomicilioProvider>(context, listen: true).viaje.pasajeros.fold(0, (previousValue, element) => element.embarcado == 2 ? previousValue + 1 : previousValue)}",
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          Material(
                                            elevation: 1,
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              alignment: Alignment.center,
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color: Colors.green,
                                              ),
                                              child: Text(
                                                "${Provider.of<DomicilioProvider>(context, listen: true).viaje.pasajeros.fold(0, (previousValue, element) => element.embarcado == 1 ? previousValue + 1 : previousValue)}",
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (usuario.vinculacionActiva == '1' && Provider.of<DomicilioProvider>(context, listen: true).viaje.sentido == 'R')
                                  Positioned(
                                    right: 3,
                                    top: MediaQuery.of(context).size.width * 0.10,
                                    child: SizedBox(
                                      height: MediaQuery.of(context).size.width * 0.18,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Container(
                                            alignment: Alignment.center,
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "${esEmbarque ? 'E' : 'R'} ",
                                              style: const TextStyle(color: AppColors.mainBlueColor, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Material(
                                            elevation: 1,
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              alignment: Alignment.center,
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color: Colors.amber,
                                              ),
                                              child: Text(
                                                esEmbarque ? "${Provider.of<DomicilioProvider>(context, listen: true).viaje.pasajeros.fold(0, (previousValue, element) => element.embarcado == 2 ? previousValue + 1 : previousValue)}" : "${Provider.of<DomicilioProvider>(context, listen: true).viaje.pasajeros.fold(0, (previousValue, element) => element.embarcado == 1 && element.fechaDesembarque == "" ? previousValue + 1 : previousValue)}",
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          Material(
                                            elevation: 1,
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              alignment: Alignment.center,
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                color: Colors.green,
                                              ),
                                              child: Text(
                                                esEmbarque ? "${Provider.of<DomicilioProvider>(context, listen: true).viaje.pasajeros.fold(0, (previousValue, element) => element.embarcado == 1 ? previousValue + 1 : previousValue)}" : "${Provider.of<DomicilioProvider>(context, listen: true).viaje.pasajeros.fold(0, (previousValue, element) => element.embarcado == 1 && element.fechaDesembarque != "" ? previousValue + 1 : previousValue)}",
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR EMBARQUE CONDUCTOR DOMICILIO
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUECONDUCTOR") != null && usuario.domicilio == "1" && usuario.vinculacionActiva == "1")
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_embarque', usuario, 'GESTIONAREMBARQUECONDUCTOR/DOMICILIO');

                            _modalSincronizacionDomicilio(context);

                            /*Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ListaViajesPage(),
                                    ),
                                  );*/
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(
                                      child: ImagesCardHome(
                                    image: "assets/images/Iconos_Embarque.png",
                                  )),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Embarque",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR EMBARQUE CONDUCTOR BOLSA
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUECONDUCTOR") != null && usuario.domicilio == "0" && usuario.vinculacionActiva == "1")
                        GestureDetector(
                          onTap: () {
                            _insertarEventoAnalytics('opc_embarque', usuario, 'GESTIONAREMBARQUECONDUCTOR');

                            if (usuario.domicilio == "1") {
                              _modalSincronizacionDomicilio(context);
                            } else {
                              _modalSincronizacionBolsa(context);
                            }

                            /*Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ListaViajesPage(),
                                    ),
                                  );*/
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(
                                      child: ImagesCardHome(
                                    image: "assets/images/Iconos_Embarque.png",
                                  )),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Embarque",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR EMBARQUE SUPERVISOR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUESUPERVISOR") != null && usuario.domicilio == "0" && usuario.vinculacionActiva == "1")
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_embarque', usuario, 'GESTIONAREMBARQUESUPERVISOR');

                            ////Shared Preferences
                            _showDialogSincronizandoDatos(context, "Cargando...");
                            final SharedPreferences pref = await SharedPreferences.getInstance();
                            // pref.clear();
                            String? usuarioVinculado = pref.getString("usuarioVinculado");

                            if (usuarioVinculado == null) {
                              context.read<EmbarquesSupScanerBloc>().add(resetEstadoEscanearUnidadInitial());

                              context.read<VincularInicioBloc>().add(resetEstadoVincularInitial());

                              Navigator.of(context).pushNamedAndRemoveUntil('embarquesSupervisorScaner', (Route<dynamic> route) => false);
                            } else {
                              final usuarioObjeto = jsonDecode(usuarioVinculado);

                              context.read<EmbarquesSupScanerBloc>().add(EditarEstadoEscanearUnidadSuccessSup(
                                    usuarioObjeto["nDocConductor"].toString().trim(),
                                    usuarioObjeto["numViaje"],
                                  ));

                              context.read<VincularInicioBloc>().add(EditarEstadoVincularSuccess(
                                    usuarioObjeto["tDocConductor"],
                                    usuarioObjeto["nDocConductor"].toString().trim(),
                                  ));

                              _supervisorCargarViajeRemoteOLocal(
                                context,
                                usuarioObjeto["tDocConductor"].toString().trim(),
                                usuarioObjeto["nDocConductor"].toString().trim(),
                                usuarioObjeto["numViaje"].toString().trim(),
                              );
                            }
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(child: ImagesCardHome(image: "assets/images/Iconos_Embarque.png")),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Embarques",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR EMBARQUE EMBARCADOR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUEEMBARCADOR") != null && usuario.domicilio == "0" && usuario.vinculacionActiva == "1")
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_embarque', usuario, 'GESTIONAREMBARQUEEMBARCADOR');

                            ////Shared Preferences
                            _showDialogSincronizandoDatos(context, "Cargando...");
                            final SharedPreferences pref = await SharedPreferences.getInstance();

                            String? usuarioVinculado = pref.getString("usuarioVinculado");

                            if (usuarioVinculado == null) {
                              context.read<EmbarquesSupScanerBloc>().add(resetEstadoEscanearUnidadInitial());

                              context.read<VincularInicioBloc>().add(resetEstadoVincularInitial());

                              Navigator.of(context).pushNamedAndRemoveUntil('embarquesSupervisorScaner', (Route<dynamic> route) => false);
                            } else {
                              final usuarioObjeto = jsonDecode(usuarioVinculado);

                              context.read<EmbarquesSupScanerBloc>().add(EditarEstadoEscanearUnidadSuccessSup(
                                    usuarioObjeto["nDocConductor"].toString().trim(),
                                    usuarioObjeto["numViaje"],
                                  ));

                              context.read<VincularInicioBloc>().add(EditarEstadoVincularSuccess(
                                    usuarioObjeto["tDocConductor"],
                                    usuarioObjeto["nDocConductor"].toString().trim(),
                                  ));

                              var viajeServicio = ViajeServicio();
                              Viaje viaje = await viajeServicio.obtenerViajeVinculadoBolsaSupervisor_v4(
                                usuarioObjeto["tDocConductor"],
                                usuarioObjeto["nDocConductor"].toString().trim(),
                                usuarioObjeto["numViaje"],
                              );

                              final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
                                viaje.nroViaje,
                                viaje.codOperacion,
                              );

                              viaje.puntosEmbarque = puntosEmabarque;

                              Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viaje);

                              final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;

                              await Provider.of<PrereservaProvider>(context, listen: false).obtenerListadoPrereservasBD(
                                viaje.nroViaje,
                                usuarioProvider.tipoDoc,
                                usuarioProvider.numDoc,
                                viaje.subOperacionId,
                              );

                              Navigator.pop(context);

                              Navigator.of(context).pushNamed('navigationBolsaViaje');
                            }
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(child: ImagesCardHome(image: "assets/images/Iconos_Embarque.png")),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Embarques",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR EMBARQUE SUPERVISOR MULTIPLE
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUEMULTIPLE") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_embarque_multiples', usuario, 'GESTIONAREMBARQUEMULTIPLE');

                            _supervisorMultipleCargarDatos(context);
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(child: ImagesCardHome(image: "assets/images/Iconos_Embarque.png")),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Embarques Múltiples",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR MANIFIESTO SUPERVISOR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERMANIFIESTOS") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_manifiestos', usuario, 'VERMANIFIESTOS');

                            Provider.of<ViajeProvider>(context, listen: false).limpiarLista();
                            await Provider.of<PuntoEmbarqueProvider>(context, listen: false).obtenerPuntosEmbarque(usuario.codOperacion);

                            Navigator.of(context).pushNamedAndRemoveUntil('listaViajes', (Route<dynamic> route) => false);
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(child: ImagesCardHome(image: "assets/images/Iconos_Manifiesto.png")),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Manifiesto",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR FINALIZAR VIAJE SUPERVISOR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERFINALIZARVIAJE") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_finalizar_viajes', usuario, 'VERFINALIZARVIAJE');

                            await Provider.of<RutasProvider>(context, listen: false).obtenerRutas(usuario.codOperacion);

                            Navigator.of(context).pushNamedAndRemoveUntil('finalizarViajePage', (Route<dynamic> route) => false);
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(child: ImagesCardHome(image: "assets/images/Iconos_Finalizar_viaje.png")),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Finalizar Viajes",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR CONFIGURAR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "CONFIGURAR") != null)
                        GestureDetector(
                          onTap: () {
                            //Navigator.pop(context);
                            //Navigator.popAndPushNamed(context, 'listaViajes');
                            _insertarEventoAnalytics('opc_configuracion', usuario, 'CONFIGURAR');

                            Navigator.of(context).pushNamedAndRemoveUntil('configuracion', (Route<dynamic> route) => false);
                          },
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  child: const FittedBox(
                                    child: ImagesCardHome(image: "assets/images/Iconos_Configuracion.png"),
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe42313),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Configuración",
                                    style: TextStyle(
                                      color: AppColors.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      //GESTIONAR JORNADA SUPERVISOR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERJORNADA") != null && usuario.unidadEmp != "" && usuario.viajeEmp != "")
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_jornada', usuario, 'VERJORNADA');

                            context.read<UnidadBloc>().add(
                                  SetStateUnidadSuccess(
                                    usuario.placaEmp,
                                    usuario.unidadEmp,
                                    usuario.viajeEmp,
                                  ),
                                );

                            final AppDatabase appDatabase = AppDatabase();
                            final listaJornada = await appDatabase.ListarJornada(
                              usuario.viajeEmp,
                            );

                            bool iniciar = true;
                            String dni = "";

                            for (var element in listaJornada) {
                              if (element.estado == "1") {
                                iniciar = false;
                                dni = element.viajDni;
                              }
                            }

                            if (iniciar) {
                              Navigator.pushNamed(context, 'jornada');
                            } else {
                              _showDialogFinalizarJornada(context, dni).show();
                            }
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: FittedBox(
                                        child: ImagesCardHome(image: state.idJornadaActual != "" ? "assets/images/Iconos_Jornada_inicio.png" : "assets/images/Iconos_Jornada_fin.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: state.idJornadaActual != "" ? AppColors.greenColor : const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        state.idJornadaActual != "" ? "${state.NombreJornadaActual.split(",").last}, ${state.NombreJornadaActual.split(",").first} " : "Iniciar Jornada",
                                        style: const TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //GESTIONAR VER FINALIZAR VIAJE CONDUCTOR BOLSA
                      // if (_usuario.acciones.firstWhereOrNull((accion) =>
                      //         accion.toUpperCase() ==
                      //         "VERFINALIZARVIAJECONDUCTORBOLSA") !=
                      //     null)
                      //   GestureDetector(
                      //     onTap: _usuario.viajeEmp == ""
                      //         ? null
                      //         : () async {
                      //             _showDialogFinalizarViaje(context).show();
                      //           },
                      //     child: BlocBuilder<JornadaBloc, JornadaState>(
                      //       builder: (context, state) {
                      //         return Card(
                      //           elevation: _usuario.viajeEmp == "" ? 0 : 1,
                      //           color: _usuario.viajeEmp == ""
                      //               ? Colors.grey.shade200
                      //               : state.idJornadaActual != ""
                      //                   ? Colors.green.shade300
                      //                   : AppColors.whiteColor,
                      //           shape: const RoundedRectangleBorder(
                      //             borderRadius: const BorderRadius.all(
                      //               Radius.circular(20),
                      //             ),
                      //           ),
                      //           child: Column(
                      //             mainAxisAlignment: MainAxisAlignment.center,
                      //             crossAxisAlignment: CrossAxisAlignment.center,
                      //             children: [
                      //               Container(
                      //                 width: MediaQuery.of(context).size.width *
                      //                     0.35,
                      //                 height:
                      //                     MediaQuery.of(context).size.width *
                      //                         0.32,
                      //                 child: FittedBox(
                      //                   child: ImagesCardHome(
                      //                     image:
                      //                         "assets/images/Iconos_Finalizar_viaje.png",
                      //                   ),
                      //                 ),
                      //               ),
                      //               Container(
                      //                 width: MediaQuery.of(context).size.width *
                      //                     0.35,
                      //                 padding:
                      //                     EdgeInsets.symmetric(horizontal: 5),
                      //                 decoration: BoxDecoration(
                      //                   color: Color(0xFFe42313),
                      //                   borderRadius: BorderRadius.circular(20),
                      //                 ),
                      //                 alignment: Alignment.center,
                      //                 child: Text(
                      //                   "Finalizar Viaje",
                      //                   style: TextStyle(
                      //                     color: AppColors.whiteColor,
                      //                     fontWeight: FontWeight.bold,
                      //                   ),
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   ),

                      //GESTIONAR VERIFICAR UNIDAD : CONTROL DE SALIDAS
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERVERIFICARUNIDAD") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_salidas_llegadas', usuario, 'VERVERIFICARUNIDAD');

                            Navigator.of(context).pushNamedAndRemoveUntil('controlVehicular', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/Iconos_Verificar_unidad.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Salidas / Llegadas",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //GESTIONAR CONTROL ASISTENCIA
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERCONTROLASISTENCIA") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_asistencia', usuario, 'VERCONTROLASISTENCIA');

                            Navigator.of(context).pushNamedAndRemoveUntil('controlAsistencia', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/iconos_Control_asistencia.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Asistencia",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //GESTIONAR VERIFICAR UNIDAD : CONTROL DE INGRESO
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERCONTROLINGRESO") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_control_ingreso', usuario, 'VERCONTROLINGRESO');

                            Navigator.of(context).pushNamedAndRemoveUntil('controlIngreso', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/Iconos_Verificar_unidad.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Control Ingreso",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //AGREGAR COLABORADOR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERAGREGAREDITARCOLABORADOR") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_agregar_personal', usuario, 'VERAGREGAREDITARCOLABORADOR');

                            Navigator.of(context).pushNamedAndRemoveUntil('colaboradorPage', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/agregarColaborador.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Agregar Personal",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //USUARIO GEOP - PADRON VEHICULAR
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERPADRONVEHICULOGEOP") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_padron_unidades', usuario, 'VERPADRONVEHICULOGEOP');

                            _showDialogCargando(context, "Cargando...");
                            final validacion = await validarTodasUnidadesGEOP();

                            Navigator.pop(context);

                            if (validacion.status == "200") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebViewBasicaPage(url: "https://plataformas.linea.pe/GEOP/GEOP_APP?p=${validacion.encriptado}&placaunidad=xxx&codunidad=xxx", titulo: "Padrón de unidades", back: "inicio"),
                                ),
                              );
                            } else {
                              _showDialogError(context, "ERROR", "${validacion.rpta}");
                            }
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/Iconos_padron_vehicular.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Padrón Unidades",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //USUARIO GEOP - PADRON QR UNIDAD
                      // if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERFICHAVEHICULOGEOP") != null)
                      // GestureDetector(
                      //   onTap: () async {
                      //     _insertarEventoAnalytics('opc_qr_unidad', usuario, 'VERFICHAVEHICULOGEOP');

                      //     Navigator.of(context).pushNamedAndRemoveUntil('padronVehicularGeop', (Route<dynamic> route) => false);
                      //   },
                      //   child: BlocBuilder<JornadaBloc, JornadaState>(
                      //     builder: (context, state) {
                      //       return Card(
                      //         shape: const RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.all(
                      //             Radius.circular(20),
                      //           ),
                      //         ),
                      //         child: Column(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           crossAxisAlignment: CrossAxisAlignment.center,
                      //           children: [
                      //             SizedBox(
                      //               width: MediaQuery.of(context).size.width * 0.35,
                      //               height: MediaQuery.of(context).size.width * 0.32,
                      //               child: const FittedBox(
                      //                 child: ImagesCardHome(image: "assets/images/qr_unidad_geop.png"),
                      //               ),
                      //             ),
                      //             Container(
                      //               width: MediaQuery.of(context).size.width * 0.35,
                      //               padding: const EdgeInsets.symmetric(horizontal: 5),
                      //               decoration: BoxDecoration(
                      //                 color: const Color(0xFFe42313),
                      //                 borderRadius: BorderRadius.circular(20),
                      //               ),
                      //               alignment: Alignment.center,
                      //               child: const Text(
                      //                 "QR Unidad",
                      //                 style: TextStyle(
                      //                   color: AppColors.whiteColor,
                      //                   fontWeight: FontWeight.bold,
                      //                 ),
                      //                 maxLines: 1,
                      //                 overflow: TextOverflow.ellipsis,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),

                      //CHECKLIST MANTENIMIENTO
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERCHECKLISTMANTENIMIENTO") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_checklist', usuario, 'VERCHECKLISTMANTENIMIENTO');

                            Navigator.of(context).pushNamedAndRemoveUntil('checklistMantenimiento', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/qr_unidad_geop.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "CheckList",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERORDENSERVICIOPORTALLER") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_orden_servicio_taller', usuario, 'VERORDENSERVICIOPORTALLER');

                            Navigator.of(context).pushNamed('ordenServicioTaller');
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/qr_unidad_geop.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Orden Servicio Taller",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERORDENSERVICIOTODOSLOSTALLERES") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_orden_servicio', usuario, 'VERORDENSERVICIOTODOSLOSTALLERES');

                            Navigator.of(context).pushNamedAndRemoveUntil('ordenServicioTalleres', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/qr_unidad_geop.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Orden Servicio",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //CHECKLIST MANTENIMIENTO
                      //if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERCHECKLIST") != null)
                      GestureDetector(
                        onTap: () async {
                          _insertarEventoAnalytics('opc_checklist', usuario, 'VERCHECKLIST');
                          context.read<ChecklistBloc>().add(
                                ListarTipoCheckListEvent(
                                  tDoc: usuario.tipoDoc,
                                  nDoc: usuario.numDoc,
                                ),
                              );
                          Navigator.of(context).pushNamedAndRemoveUntil('checklistMain', (Route<dynamic> route) => false);
                        },
                        child: BlocBuilder<JornadaBloc, JornadaState>(
                          builder: (context, state) {
                            return Card(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.35,
                                    height: MediaQuery.of(context).size.width * 0.32,
                                    child: const FittedBox(
                                      child: ImagesCardHome(image: "assets/images/qr_unidad_geop.png"),
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.35,
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe42313),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "CheckList",
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      //VER PROGRAMACIÓN
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERPROGRAMACION") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_programacion', usuario, 'VERPROGRAMACION');

                            Navigator.of(context).pushNamedAndRemoveUntil('listarProgramacion', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/qr_unidad_geop.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Mi Programación",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //GESTIONAR DAR AUTORIZACION
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "DARAUTORIZACION") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_autorizaciones', usuario, 'DARAUTORIZACION');

                            Navigator.of(context).pushNamedAndRemoveUntil('darAutorizaciones', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/Iconos_Dar_Auth.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Autorizaciones",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      // if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERDOCLABORALES") != null)
                      GestureDetector(
                        onTap: () async {
                          final auth = LocalAuthentication();

                          final canCheck = await auth.canCheckBiometrics;
                          final isSupported = await auth.isDeviceSupported();

                          if (!canCheck && !isSupported) {
                            await mostrarAvisoSeguridad(context);
                            return;
                          }

                          try {
                            final autorizado = await auth.authenticate(
                              localizedReason: 'Confirma tu identidad',
                              authMessages: <AuthMessages>[
                                AndroidAuthMessages(
                                  signInTitle: 'Autenticación requerida',
                                  cancelButton: 'Cancelar',
                                ),
                                IOSAuthMessages(
                                  cancelButton: 'Cancelar',
                                ),
                              ],
                            );

                            if (autorizado && context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                'verDocLaborales',
                                (route) => false,
                              );
                            }
                          } catch (_) {
                            // 🔴 Aquí entra cuando NO hay bloqueo configurado
                            await mostrarAvisoSeguridad(context);
                          }
                        },
                        child: BlocBuilder<JornadaBloc, JornadaState>(
                          builder: (context, state) {
                            return Card(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.35,
                                    height: MediaQuery.of(context).size.width * 0.32,
                                    child: const FittedBox(
                                      child: ImagesCardHome(image: "assets/images/icon_documentos.png"),
                                    ),
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.35,
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe42313),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "Docs. Laborales",
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      //PLATAFORMA DE SOPORTE TI
                      if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERPLATAFORMASOPORTETI") != null)
                        GestureDetector(
                          onTap: () async {
                            _insertarEventoAnalytics('opc_soporte_ti', usuario, 'VERPLATAFORMASOPORTETI');

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WebViewBasicaPage(url: "https://aplicativos.linea.pe/gestorSoporteTI", titulo: "Soporte TI", back: "inicio"),
                              ),
                            );
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: const FittedBox(
                                        child: ImagesCardHome(image: "assets/images/Iconos_Soporte_TI_2.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        "Soporte TI",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      //VER INCIDENTES HISTORIAL
                      if (_usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERINCIDENTES") != null)
                        GestureDetector(
                          onTap: () async {
                            Navigator.of(context).pushNamedAndRemoveUntil('irVerIncidentes', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: FittedBox(
                                        child: ImagesCardHome(image: "assets/images/Iconos_Incidentes.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Alertas",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      //if (_usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "COPILOTO VIRTUAL") != null)
                      // GestureDetector(
                      //   onTap: () async {
                      //     //await verificarVersion();
                      //     Navigator.of(context).pushNamedAndRemoveUntil('irCopiloto', (Route<dynamic> route) => false);
                      //   },
                      //   child: BlocBuilder<JornadaBloc, JornadaState>(
                      //     builder: (context, state) {
                      //       return Card(
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: const BorderRadius.all(
                      //             Radius.circular(20),
                      //           ),
                      //         ),
                      //         child: Column(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           crossAxisAlignment: CrossAxisAlignment.center,
                      //           children: [
                      //             Container(
                      //               width: MediaQuery.of(context).size.width * 0.35,
                      //               height: MediaQuery.of(context).size.width * 0.32,
                      //               child: FittedBox(
                      //                 child: ImagesCardHome(image: "assets/images/Icono_copiloto.png"),
                      //               ),
                      //             ),
                      //             Container(
                      //               width: MediaQuery.of(context).size.width * 0.35,
                      //               padding: EdgeInsets.symmetric(horizontal: 5),
                      //               decoration: BoxDecoration(
                      //                 color: Color(0xFFe42313),
                      //                 borderRadius: BorderRadius.circular(20),
                      //               ),
                      //               alignment: Alignment.center,
                      //               child: Text(
                      //                 "Copiloto",
                      //                 style: TextStyle(
                      //                   color: AppColors.whiteColor,
                      //                   fontWeight: FontWeight.bold,
                      //                 ),
                      //                 maxLines: 1,
                      //                 overflow: TextOverflow.ellipsis,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),
                      if (_usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "VERRUTAS") != null)
                        GestureDetector(
                          onTap: () async {
                            Navigator.of(context).pushNamedAndRemoveUntil('irVerRutas', (Route<dynamic> route) => false);
                          },
                          child: BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      height: MediaQuery.of(context).size.width * 0.32,
                                      child: FittedBox(
                                        child: ImagesCardHome(image: "assets/images/Iconos_Ruta.png"),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.35,
                                      padding: EdgeInsets.symmetric(horizontal: 5),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "Rutas",
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (Conexion.mood == false)
                const Center(
                  child: Text(
                    "Desarrollo",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                    ),
                  ),
                ),
              if (Provider.of<UsuarioProvider>(context, listen: true).usuario.viajeEmp == "")
                Container(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  alignment: Alignment.center,
                  width: width,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.mainBlueColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${usuario.apellidoPat} ${usuario.apellidoMat} ${usuario.nombres} ${usuario.equipo?.trim() == "" ? "" : "| ${usuario.equipo}"}",
                        style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              BlocBuilder<JornadaBloc, JornadaState>(
                builder: (context, state) {
                  if (usuario.viajeEmp != "") {
                    return Container(
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      alignment: Alignment.center,
                      width: width,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.mainBlueColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Viaje inició:",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " ${usuario.vinculacionActiva == "1" ? " ${usuario.unidadEmp} ${usuario.placaEmp}  ${usuario.fechaEmp}" : "vinculación desactiva"}",
                            style: const TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
  }

  Future<void> mostrarAvisoSeguridad(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Seguridad requerida'),
        content: const Text(
          'Para acceder a Documentos Laborales debes activar '
          'un bloqueo de pantalla (PIN, patrón o huella) en tu dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showDialogBDLimpiarLocalCONFIRMAR({
    required BuildContext context,
    required String mensaje,
    required String titulo,
  }) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () => Future(() => false),
          child: AlertDialog(
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: AppColors.mainBlueColor,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mensaje,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  TextFormField(
                    textAlign: TextAlign.start,
                    style: const TextStyle(color: Colors.black),
                    autofocus: true,
                    controller: textClaveMaestraController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.mainBlueColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.mainBlueColor,
                          width: 1.5,
                        ),
                      ),
                      label: Text(
                        "contraseña",
                        style: TextStyle(color: AppColors.mainBlueColor),
                      ),
                    ),
                    onEditingComplete: () {},
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MaterialButton(
                            elevation: 0.8,
                            onPressed: () async {
                              Future.delayed(Duration.zero, () {
                                Navigator.pop(context, "");
                              });
                              setState(() {
                                textClaveMaestraController.text = "";
                              });
                              _showDialogSincronizandoDatos(context, "Actualizando...");
                              await _obtenerDatosVinculacion(context);
                            },
                            height: double.infinity,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            color: Colors.grey,
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MaterialButton(
                            elevation: 0.8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            onPressed: () async {
                              if (_hayConexion()) {
                                _showDialogSincronizandoDatos(context, "Actualizando los datos...");
                                await sincronizarViaje();

                                Navigator.pop(context);

                                _showDialogSincronizandoDatos(context, "Limpiando los datos locales...");

                                Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

                                if (usuario.claveMaestra == textClaveMaestraController.text.trim()) {
                                  await AppDatabase.instance.Eliminar(tabla: "viaje_domicilio");
                                  await AppDatabase.instance.Eliminar(tabla: "pasajero_domicilio");
                                  await AppDatabase.instance.Eliminar(tabla: "tripulante");
                                  await AppDatabase.instance.Eliminar(tabla: "parada");
                                  await AppDatabase.instance.Eliminar(tabla: "paradero");

                                  await Provider.of<UsuarioProvider>(context, listen: false).emparejar("", "", "", "", "0");

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "El equipo se libero correctamente",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      backgroundColor: AppColors.greenColor,
                                    ),
                                  );

                                  Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
                                } else {
                                  Navigator.pop(context);
                                  _mostrarModalRespuesta("Contraseña Incorrecta", "Ingrese nuevamente la contraseña", false).show();
                                }
                              } else {
                                _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
                              }
                            },
                            height: double.infinity,
                            color: AppColors.greenColor,
                            child: const Text(
                              "Liberar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  sincronizarJornadasBD() async {
    EmbarquesSupScanerServicio embarquesSupScanerServicio = EmbarquesSupScanerServicio();
    List<Jornada> listaPendiente = [];

    AppDatabase appDatabase = AppDatabase();
    List<Jornada> listJornadas = await appDatabase.ListarJornadas();

    for (var jornada in listJornadas) {
      if (jornada.estadobdfin == "1" || jornada.estadobdinicio == "1") {
        listaPendiente.add(jornada);
      }
    }

    for (var pendiente in listaPendiente) {
      String fechaInicioBD = "";
      String fechaFinBD = "";
      if (pendiente.decoInicio.trim().isNotEmpty) {
        final fechaInicio = DateTime.parse(pendiente.decoInicio);
        fechaInicioBD = DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaInicio);
      }

      if (pendiente.decoInicio.trim().isNotEmpty) {
        final fechaFin = DateTime.parse(pendiente.decoFin);
        fechaFinBD = DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaFin);
      }

      Response? resp = await embarquesSupScanerServicio.RegistarTurno(
        pendiente.viajNroViaje,
        pendiente.dehoTurno,
        pendiente.viajDni,
        fechaInicioBD,
        fechaFinBD,
        pendiente.dehoCordenadasInicio,
        pendiente.dehoCordenadasFin,
      );

      if (resp != null && resp.body.split(",")[0] == "0") {
        await appDatabase.UpdateJornada(
          {
            "EstadoBDInicio": "0", // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
            "EstadoBDFin": "0", // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
          },
          "ID=${pendiente.id}",
        );
      }
    }
  }

  //finalizarviaje-gps
  AwesomeDialog _showDialogFinalizarViaje(BuildContext context, ViajeDomicilio viaje) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      desc: "",
      body: Column(
        children: [
          // if (minutosTr < 30)
          Text(
            "¿Seguro que desea finalizar el viaje de la unidad ${_usuario.unidadEmp}-${_usuario.placaEmp} ?",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          Text(
            "Kilometraje inicial: ${Provider.of<DomicilioProvider>(context, listen: false).viaje.odometroInicial}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            "Hora finalización: ${DateFormat("hh:mm a").format(DateTime.now())}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          TextFormField(
            textAlign: TextAlign.center,
            focusNode: _focusOdometro,
            autofocus: true,
            controller: _odometroController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Ingrese su kilometraje final",
              label: Text(
                "Kilometraje final",
                style: TextStyle(
                  color: AppColors.mainBlueColor,
                ),
              ),
            ),
          ),
        ],
      ),
      reverseBtnOrder: true,
      buttonsTextStyle: const TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal cargando", rpta: "OK");
        _showDialogSincronizandoDatos(context, "Cargando...");

        if (int.tryParse(_odometroController.text.trim()) == null) {
          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");
          Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal Ingrese un kilometraje valido.", rpta: "OK");

          _mostrarModalRespuesta("ERROR AL FINALIZAR", "Ingrese un kilometraje valido.", false).show();
          return;
        }

        if (_odometroController.text.trim().contains('.') || _odometroController.text.trim().contains(',') || _odometroController.text.trim().contains('+') || _odometroController.text.trim().contains('-')) {
          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");
          Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal El odomentro no debe contener comas(;)", rpta: "OK");

          _mostrarModalRespuesta("ERROR AL FINALIZAR", "El odomentro no debe contener comas(;), puntos(.) o cualquier otro caracter especial.", false).show();

          return;
        }

        // if (minutosTr > 30) {
        if (_odometroController.text.trim() == "") {
          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");
          Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal Ingrese el kilometraje final", rpta: "OK");

          _mostrarModalRespuesta("ERROR AL FINALIZAR", "Ingrese el kilometraje final.", false).show();
          return;
        }
        // }

        if (_usuario.domicilio == "1") {
          // if (_odometroController.text.trim() != "0") {
          ViajeDomicilio viaje = Provider.of<DomicilioProvider>(context, listen: false).viaje;

          if (int.parse(_odometroController.text.trim()) <= viaje.odometroInicial) {
            Navigator.pop(context, 'Cancel');

            Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");
            Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal EL kilometraje final no puede ser menor o igual al kilometraje inicial", rpta: "OK");

            _mostrarModalRespuesta("ERROR AL FINALIZAR", "EL kilometraje final no puede ser menor o igual al kilometraje inicial", false).show();

            return;
          }
          // }
        }

        // if (await Permission.location.request().isGranted) {}
        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = "${posicionActualGPS.latitude},${posicionActualGPS.longitude}";
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        if (_hayConexion()) {
          sincronizarViaje();
          sincronizarJornadasBD();
          ViajeServicio servicio = ViajeServicio();

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Finaliza el viaje #${_usuario.viajeEmp} -> PA:finalizar_viaje_v4", rpta: "OK");

          final rpta = await servicio.finalizarViajeV4(
            _usuario.viajeEmp,
            _usuario.codOperacion,
            _usuario,
            _odometroController.text.trim() == "" ? "0" : _odometroController.text.trim(),
            posicionActual,
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: finalizar viaje #${_usuario.viajeEmp} -> PA:finalizar_viaje_v4", rpta: rpta == "0" || rpta == "1" ? "OK" : "ERROR-> $rpta");

          switch (rpta) {
            case "0":
              Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

              Log.insertarLogDomicilio(context: context, mensaje: "Se ha finalizado correctamente el viaje", rpta: "OK");

              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPagina("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();

              break;
            case "1":
              Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

              Log.insertarLogDomicilio(context: context, mensaje: "Este viaje ya ha sido finalizado", rpta: "OK");

              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPagina("Error", "Este viaje ya ha sido finalizado", false, _usuario.viajeEmp).show();

              break;
            case "2":
              Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

              Log.insertarLogDomicilio(context: context, mensaje: "Al parecer este viaje ya no existe", rpta: "OK");

              Navigator.pop(context, 'Cancel');
              /*_mensajeCerrado("Al parecer este viaje ya no existe.",true);*/

              _mostrarModalRespuestaCerrarPagina("Error", "Al parecer este viaje ya no existe", false, _usuario.viajeEmp).show();

              break;
            case "3":
              Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

              Log.insertarLogDomicilio(context: context, mensaje: "Se cerrará la página", rpta: "OK");

              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPagina("Error", "Se cerrará la página", false, _usuario.viajeEmp).show();

              break;
            case "10":
              Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

              Log.insertarLogDomicilio(context: context, mensaje: "El kilometraje del inicio es mayor al del final.", rpta: "OK");

              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuesta("Error", "El kilometraje del inicio es mayor al del final.", false).show();

              break;
            // case "9":
            //   Navigator.pop(context, 'Cancel');
            //   _mostrarModalRespuesta(
            //           "Error", "No tiene conexión a internet", false)
            //       .show();
            //   break;
            default:
              Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");
              Log.insertarLogDomicilio(context: context, mensaje: "Error al procesar la consulta", rpta: "OK");

              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuesta("Error", "Error al procesar la consulta", false).show();
          }
        } else {
          int status = await AppDatabase.instance.Update(
            table: "viaje_domicilio",
            value: {
              "cordenadaFinal": posicionActual,
              "odometroFinal": int.parse(_odometroController.text.trim()),
              "estadoViaje": "1",
            },
            where: "nroViaje = '${_usuario.viajeEmp}'",
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el viaje con odometro final en BDLocal -> TBL: viaje_domicilio", rpta: status > 0 ? "OK" : "ERROR-> $status");

          int statusU = await AppDatabase.instance.Update(
            table: "usuario",
            value: {
              "vinculacionActiva": "0",
              "sesionSincronizada": '1',
            },
            where: "numDoc = '${_usuario.numDoc}'",
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el usuario y su vinculación -> TBL: usuario", rpta: statusU > 0 ? "OK" : "ERROR-> $statusU");

          Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal Se ha finalizado correctamente el viaje", rpta: "OK");

          _mostrarModalRespuestaCerrarPagina("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  //finalizarviajebolsa-gps
  AwesomeDialog _showDialogFinalizarViajeBolsaORInteprovincial(BuildContext context, Viaje viaje) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      desc: "",
      body: Column(
        children: [
          // if (minutosTr < 30)
          Text(
            "¿Seguro que desea finalizar el viaje de la unidad ${_usuario.unidadEmp}-${_usuario.placaEmp} ?",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),
          Text(
            "Hora Finalización: ${DateFormat("hh:mm a").format(DateTime.now())}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            "Km. Inicial: ${Provider.of<ViajeProvider>(context, listen: false).viaje.odometroInicial}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          TextFormField(
            textAlign: TextAlign.center,
            focusNode: _focusOdometro,
            autofocus: true,
            controller: _odometroController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Ingrese su kilometraje final",
              label: Text(
                "Kilometraje final",
                style: TextStyle(
                  color: AppColors.mainBlueColor,
                ),
              ),
            ),
          ),
        ],
      ),
      reverseBtnOrder: true,
      buttonsTextStyle: const TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        _showDialogSincronizandoDatos(context, "Cargando...");

        if (int.tryParse(_odometroController.text.trim()) == null) {
          Navigator.pop(context, 'Cancel');
          _mostrarModalRespuesta("ERROR AL FINALIZAR", "Ingrese un kilometraje valido.", false).show();
          return;
        }

        if (_odometroController.text.trim().contains('.') || _odometroController.text.trim().contains(',') || _odometroController.text.trim().contains('+') || _odometroController.text.trim().contains('-')) {
          Navigator.pop(context, 'Cancel');
          _mostrarModalRespuesta("ERROR AL FINALIZAR", "El odomentro no debe contener comas(;), puntos(.) o cualquier otro caracter especial.", false).show();

          return;
        }

        // if (minutosTr > 30) {
        if (_odometroController.text.trim() == "") {
          Navigator.pop(context, 'Cancel');
          _mostrarModalRespuesta("ERROR AL FINALIZAR", "Ingrese el kilometraje final.", false).show();
          return;
        }
        // }

        if (_usuario.domicilio == "1") {
          // if (_odometroController.text.trim() != "0") {
          Viaje viaje = Provider.of<ViajeProvider>(context, listen: false).viaje;

          if (int.parse(_odometroController.text.trim()) <= viaje.odometroInicial) {
            Navigator.pop(context, 'Cancel');
            _mostrarModalRespuesta("ERROR AL FINALIZAR", "EL kilometraje final no puede ser menor o igual al kilometraje inicial", false).show();

            return;
          }
          // }
        } else {
          if (int.parse(_odometroController.text.trim()) <= viaje.odometroInicial) {
            Navigator.pop(context, 'Cancel');
            _mostrarModalRespuesta("ERROR AL FINALIZAR", "EL kilometraje final no puede ser menor o igual al kilometraje inicial", false).show();

            return;
          }
        }

        if (await Permission.location.request().isGranted) {}
        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = "${posicionActualGPS.latitude},${posicionActualGPS.longitude}";
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        if (_hayConexion()) {
          sincronizarViaje();
          sincronizarJornadasBD();
          ViajeServicio servicio = ViajeServicio();
          final rpta = await servicio.finalizarViajeV5(
            _usuario.viajeEmp,
            _usuario.codOperacion,
            _usuario,
            _odometroController.text.trim() == "" ? "0" : _odometroController.text.trim(),
            posicionActual,
            odometroObtenido ? 'SIGPS' : 'NOGPS',
          );

          switch (rpta) {
            case "0":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();

              break;
            case "1":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Este viaje ya ha sido finalizado", false, _usuario.viajeEmp).show();

              break;
            case "2":
              Navigator.pop(context, 'Cancel');
              /*_mensajeCerrado("Al parecer este viaje ya no existe.",true);*/

              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Al parecer este viaje ya no existe", false, _usuario.viajeEmp).show();

              break;
            case "3":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Se cerrará la página", false, _usuario.viajeEmp).show();

              break;
            case "10":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuesta("Error", "El kilometraje del inicio es mayor al del final.", false).show();

              break;
            // case "9":
            //   Navigator.pop(context, 'Cancel');
            //   _mostrarModalRespuesta(
            //           "Error", "No tiene conexión a internet", false)
            //       .show();
            //   break;
            default:
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuesta("Error", "Error al procesar la consulta", false).show();
          }
        } else {
          await AppDatabase.instance.Update(
            table: "viaje",
            value: {
              "cordenadaFinal": posicionActual,
              "odometroFinal": int.parse(_odometroController.text.trim()),
              "estadoViaje": "1",
            },
            where: "nroViaje = '${_usuario.viajeEmp}'",
          );

          await AppDatabase.instance.Update(
            table: "usuario",
            value: {
              "vinculacionActiva": "0",
              "viajeEmp": "",
              "unidadEmp": "",
              "placaEmp": "",
              "fechaEmp": "",
              "sesionSincronizada": '1',
            },
            where: "numDoc = '${_usuario.numDoc}'",
          );

          Navigator.pop(context, 'Cancel');
          _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  Future<Map<String, dynamic>> obtenerOdometroViaje(String codUnidad) async {
    final EmbarquesSupScanerServicio embarquesSupScanerServicio = EmbarquesSupScanerServicio();
    Response? res = await embarquesSupScanerServicio.ObtenerOdometroViaje(codUnidad.trim());

    String rpta = "0";
    String mensaje = "0";

    if (res != null) {
      final data = json.decode(res.body);
      if (data["rpta"] == "0") {
        setState(() {
          odometroObtenido = true;
        });
        rpta = "0";
        mensaje = data["mensaje"];
      } else {
        setState(() {
          odometroObtenido = false;
        });
        rpta = "1";
        mensaje = data["mensaje"];
      }
    } else {
      setState(() {
        odometroObtenido = false;
      });
      rpta = "1";
      mensaje = "Error en la consulta";
    }

    return {"rpta": rpta, "mensaje": mensaje};
  }

  AwesomeDialog _showDialogFinalizarViajeBolsaORInteprovincialSinOdometro(BuildContext context, Viaje viaje, String odometro) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      desc: "",
      body: Column(
        children: [
          // if (minutosTr < 30)
          Text(
            "¿Seguro que desea finalizar el viaje de la unidad ${_usuario.unidadEmp}-${_usuario.placaEmp} ?",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          Text(
            "Hora Finalización: ${DateFormat("hh:mm a").format(DateTime.now())}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),

          Text(
            "Km. Inicial: ${Provider.of<ViajeProvider>(context, listen: false).viaje.odometroInicial}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            "Km. Final: $odometro",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            "Km. Recorridos: ${int.parse(odometro) - Provider.of<ViajeProvider>(context, listen: false).viaje.odometroInicial}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      reverseBtnOrder: true,
      buttonsTextStyle: const TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        _showDialogSincronizandoDatos(context, "Cargando...");

        if (await Permission.location.request().isGranted) {}
        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = "${posicionActualGPS.latitude},${posicionActualGPS.longitude}";
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        if (_hayConexion()) {
          sincronizarViaje();
          sincronizarJornadasBD();
          ViajeServicio servicio = ViajeServicio();
          final rpta = await servicio.finalizarViajeV5(
            _usuario.viajeEmp,
            _usuario.codOperacion,
            _usuario,
            odometro,
            posicionActual,
            odometroObtenido ? 'SIGPS' : 'NOGPS',
          );

          switch (rpta) {
            case "0":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();

              break;
            case "1":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Este viaje ya ha sido finalizado", false, _usuario.viajeEmp).show();

              break;
            case "2":
              Navigator.pop(context, 'Cancel');
              /*_mensajeCerrado("Al parecer este viaje ya no existe.",true);*/

              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Al parecer este viaje ya no existe", false, _usuario.viajeEmp).show();

              break;
            case "3":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Se cerrará la página", false, _usuario.viajeEmp).show();

              break;
            case "10":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuesta("Error", "El kilometraje del inicio es mayor al del final.", false).show();

              break;
            // case "9":
            //   Navigator.pop(context, 'Cancel');
            //   _mostrarModalRespuesta(
            //           "Error", "No tiene conexión a internet", false)
            //       .show();
            //   break;
            default:
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuesta("Error", "Error al procesar la consulta", false).show();
          }
        } else {
          await AppDatabase.instance.Update(
            table: "viaje",
            value: {
              "cordenadaFinal": posicionActual,
              "odometroFinal": int.parse(_odometroController.text.trim()),
              "estadoViaje": "1",
            },
            where: "nroViaje = '${_usuario.viajeEmp}'",
          );

          await AppDatabase.instance.Update(
            table: "usuario",
            value: {
              "vinculacionActiva": "0",
              "viajeEmp": "",
              "unidadEmp": "",
              "placaEmp": "",
              "fechaEmp": "",
              "sesionSincronizada": '1',
            },
            where: "numDoc = '${_usuario.numDoc}'",
          );

          Navigator.pop(context, 'Cancel');
          _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  AwesomeDialog _showDialogFinalizarViajeBolsSupervisorEmbarcador(BuildContext context, ViajeDomicilio viaje) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      desc: "",
      body: Column(
        children: [
          Text(
            "¿Seguro que desea finalizar el viaje de la unidad ${_usuario.unidadEmp}-${_usuario.placaEmp} ?",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            "Hora finalización: ${DateFormat("hh:mm a").format(DateTime.now())}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
      reverseBtnOrder: true,
      buttonsTextStyle: const TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        _showDialogSincronizandoDatos(context, "Cargando...");
        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = "${posicionActualGPS.latitude},${posicionActualGPS.longitude}";
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        if (_hayConexion()) {
          sincronizarViajeBolsa();
          sincronizarJornadasBD();
          ViajeServicio servicio = ViajeServicio();
          final rpta = await servicio.finalizarViaje_v2_1(
            //DWA
            _usuario.viajeEmp,
            _usuario.codOperacion,
            _usuario,
            posicionActual,
          );

          switch (rpta) {
            case "0":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();

              break;
            case "1":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Este viaje ya ha sido finalizado", false, _usuario.viajeEmp).show();

              break;
            case "2":
              Navigator.pop(context, 'Cancel');
              /*_mensajeCerrado("Al parecer este viaje ya no existe.",true);*/

              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Al parecer este viaje ya no existe", false, _usuario.viajeEmp).show();

              break;
            case "3":
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Error", "Se cerrará la página", false, _usuario.viajeEmp).show();

              break;

            default:
              Navigator.pop(context, 'Cancel');
              _mostrarModalRespuesta("Error", "Error al procesar la consulta", false).show();
          }
        } else {
          await AppDatabase.instance.Update(
            table: "viaje",
            value: {
              "cordenadaFinal": posicionActual,
              "estadoViaje": "1",
            },
            where: "nroViaje = '${_usuario.viajeEmp}'",
          );

          await AppDatabase.instance.Update(
            table: "usuario",
            value: {
              "vinculacionActiva": "0",
              "sesionSincronizada": '1',
            },
            where: "numDoc = '${_usuario.numDoc}'",
          );

          Navigator.pop(context, 'Cancel');
          _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador("Finalizado", "Se ha finalizado correctamente el viaje", true, _usuario.viajeEmp).show();
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  _obtenerDatosVinculacion(BuildContext context) async {
    await sincronizarViaje();
    await sincronizarJornadasBD();
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.clear();
    var usuarioServicio = UsuarioServicio();

    Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Obtener datos actualizado del usuario y su vinculación -> PA:obtenerDatosVinculacion", rpta: "OK");

    DatosVinculacion vinculacion = await usuarioServicio.obtenerDatosVinculacion(_usuario.tipoDoc, _usuario.numDoc, _usuario.codOperacion);

    Log.insertarLogDomicilio(context: context, mensaje: "Finalizar petición: Obtener datos actualizado del usuario y su vinculación -> viajeEmp:${vinculacion.viajeEmp}, unidadEmp: ${vinculacion.unidadEmp}, fechaEmp: ${vinculacion.fechaEmp}, placaEmp:${vinculacion.placaEmp} -> PA:obtenerDatosVinculacion", rpta: " ${vinculacion.rpta == "0" || vinculacion.rpta == "1" ? 'OK' : 'ERROR ->  ${vinculacion.mensaje}'}");

    if (vinculacion.rpta == "0" || vinculacion.rpta == "1") {
      await Provider.of<UsuarioProvider>(context, listen: false).emparejar(
        vinculacion.viajeEmp,
        vinculacion.unidadEmp,
        vinculacion.placaEmp,
        vinculacion.fechaEmp,
        vinculacion.viajeEmp == "" ? "0" : "1",
      );

      await AppDatabase.instance.Update(
        table: "usuario",
        value: {"viajeEmp": vinculacion.viajeEmp, "unidadEmp": vinculacion.unidadEmp, "placaEmp": vinculacion.placaEmp, "fechaEmp": vinculacion.fechaEmp, "vinculacionActiva": vinculacion.viajeEmp == "" ? "0" : "1"},
        where: "numDoc = '${_usuario.numDoc}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el usuario con su vinculacion de viaje: #${vinculacion.viajeEmp} - ${vinculacion.fechaEmp} TBL:usuario", rpta: "OK");

      Navigator.pop(context);

      Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

      Log.insertarLogDomicilio(context: context, mensaje: "Actualizado Correctamente", rpta: "OK");

      _mensaje(context, "Actualizado Correctamente").show();
    } else {
      Navigator.pop(context);

      Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando", rpta: "OK");

      Log.insertarLogDomicilio(context: context, mensaje: "No tiene conexión a internet", rpta: "OK");

      _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
    }
  }

  void _obtenerDatosVinculacionSupervisorOREmbarcador(BuildContext context, String tipoDoc, String numDoc) async {
    await sincronizarViaje();
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.clear();
    var usuarioServicio = UsuarioServicio();
    DatosVinculacion vinculacion = await usuarioServicio.obtenerDatosVinculacion(tipoDoc, numDoc, _usuario.codOperacion);

    if (vinculacion.rpta == "0" || vinculacion.rpta == "1") {
      await Provider.of<UsuarioProvider>(context, listen: false).emparejar(
        vinculacion.viajeEmp,
        vinculacion.unidadEmp,
        vinculacion.placaEmp,
        vinculacion.fechaEmp,
        vinculacion.viajeEmp == "" ? "0" : "1",
      );
      var variableLocal = {"placa": vinculacion.placaEmp, "codOperacion": _usuario.codOperacion, "numViaje": vinculacion.viajeEmp, "tDocConductor": tipoDoc, "nDocConductor": numDoc};
      await pref.setString("usuarioVinculado", jsonEncode(variableLocal));

      await AppDatabase.instance.Update(
        table: "usuario",
        value: {"viajeEmp": vinculacion.viajeEmp, "unidadEmp": vinculacion.unidadEmp, "placaEmp": vinculacion.placaEmp, "fechaEmp": vinculacion.fechaEmp, "vinculacionActiva": vinculacion.viajeEmp == "" ? "0" : "1"},
        where: "numDoc = '${_usuario.numDoc}'",
      );

      Navigator.pop(context);

      _mensaje(context, "Actualizado Correctamente").show();
    } else {
      Navigator.pop(context);

      _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
    }
  }

  AwesomeDialog _mensaje(BuildContext context, String mensaje) {
    if (_cambioDependencia) context = _navigator.context;

    return AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      //customHeader: null,
      animType: AnimType.topSlide,

      autoDismiss: true,
      autoHide: const Duration(seconds: 2),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            mensaje,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, title: titulo, desc: cuerpo, descTextStyle: const TextStyle(fontSize: 15), autoHide: const Duration(seconds: 2), dismissOnBackKeyPress: false, dismissOnTouchOutside: false);
  }

  AwesomeDialog _mostrarModalRespuestaCerrarPaginaBolsaSupervisorOrEmbarcador(String titulo, String cuerpo, bool success, String nroViaje) {
    return AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      autoHide: const Duration(seconds: 2),
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      onDismissCallback: (type) async {
        await AppDatabase.instance.Update(
          table: "viaje",
          value: {
            "estadoViaje": "1",
            "seleccionado": "2",
          },
          where: "nroViaje = '${_usuario.viajeEmp}'",
        );

        await AppDatabase.instance.Update(
          table: "usuario",
          value: {"vinculacionActiva": "0"},
          where: "numDoc = '${_usuario.numDoc}'",
        );

        await Provider.of<UsuarioProvider>(context, listen: false).emparejar("", "", "", "", "0");

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('usuarioVinculado');
        // await AppDatabase.instance.eliminarTodoDeUnViaje(nroViaje);
        // await AppDatabase.instance.EliminaJornadas();
        setState(() {});
      },
    );
  }

  AwesomeDialog _mostrarModalRespuestaCerrarPagina(String titulo, String cuerpo, bool success, String nroViaje) {
    return AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      autoHide: const Duration(seconds: 2),
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      onDismissCallback: (type) async {
        await AppDatabase.instance.Update(
          table: "viaje_domicilio",
          value: {
            "odometroFinal": int.parse(_odometroController.text.trim()),
            "estadoViaje": "1",
            "seleccionado": "2",
          },
          where: "nroViaje = '${_usuario.viajeEmp}'",
        );

        await AppDatabase.instance.Update(
          table: "usuario",
          value: {
            "vinculacionActiva": "0",
            "viajeEmp": "",
            "unidadEmp": "",
            "placaEmp": "",
            "fechaEmp": "",
          },
          where: "numDoc = '${_usuario.numDoc}'",
        );

        await Provider.of<UsuarioProvider>(context, listen: false).emparejar("", "", "", "", "0");
        // await AppDatabase.instance.eliminarTodoDeUnViaje(nroViaje);
        // await AppDatabase.instance.EliminaJornadas();
        setState(() {});
      },
    );
  }

  void _insertarEventoAnalytics(String nombreEvento, Usuario usuario, String dataAdicional) async {
    await GoogleServices.setEvent(
      nombreEvento: nombreEvento,
      usuario: usuario,
      dataAdicional: dataAdicional,
    );
  }

  void _modalSincronizacionDomicilio(BuildContext context) async {
    Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal SINCRONIZANDO DATOS", rpta: "OK");
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    if (_hayConexion()) //si hay conexion a internet
    {
      List<Map<String, Object?>> listaViajesLocal = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");

      Log.insertarLogDomicilio(context: context, mensaje: "Si hay conexión a internet", rpta: "OK");

      Log.insertarLogDomicilio(context: context, mensaje: "Cantidad de viajes obtenidos de BDLocal ${listaViajesLocal.length}", rpta: "OK");

      if (listaViajesLocal.isNotEmpty) {
        List<Map<String, Object?>> listaViajeFalaSin = [...listaViajesLocal];

        if (listaViajeFalaSin.isNotEmpty) {
          for (var i = 0; i < listaViajeFalaSin.length; i++) {
            ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajeFalaSin[i]);

            if (viaje.sentido == "I") {
              await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
            } else if (viaje.sentido == "R") {
              await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioRepartoDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
            }
          }
        }
      }

      var viajeServicio = ViajeServicio();

      Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Obtener los viajes del conductor #${_usuario.numDoc} -> PA:obtener_viajes_domicilio_conductor", rpta: "OK");

      final viajes = await viajeServicio.obtenerViajesConductorVinculadoDomicilio(_usuario);

      Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Obtener los viajes del conductor #${_usuario.numDoc} -> PA:obtener_viajes_domicilio_conductor", rpta: "OK");
      var nrosViajes = viajes.map((objeto) => objeto.nroViaje.toString()).join(', ');

      Log.insertarLogDomicilio(context: context, mensaje: "Los viajes obtenidos del conductor son $nrosViajes", rpta: "OK");

      if (viajes.isNotEmpty && viajes[0].rpta == "0") {
        await AppDatabase.instance.Eliminar(tabla: "viaje_domicilio");
        await AppDatabase.instance.Eliminar(tabla: "pasajero_domicilio");
        await AppDatabase.instance.Eliminar(tabla: "tripulante");
        await AppDatabase.instance.Eliminar(tabla: "parada");
        await AppDatabase.instance.Eliminar(tabla: "paradero");
        if (_cambioDependencia) context = _navigator.context;

        Log.insertarLogDomicilio(context: context, mensaje: "Limpiamos las tablas (pasajero_domicilio,viaje_domicilio,tripulante,parada,paradero) BDLocal -> TBL:viaje_domicilio", rpta: "OK");

        for (var i = 0; i < viajes.length; i++) {
          int statusv = await AppDatabase.instance.Guardar(tabla: "viaje_domicilio", value: viajes[i].toMapDatabaseLocal()); //27/06/2023 16:53 -- JOHN SAMUEL : GUARDA EL VIAJE DOMICILIO EN BD LOCAL

          Log.insertarLogDomicilio(context: context, mensaje: "Guardar viaje #${viajes[i].nroViaje} BDLocal -> TBL:viaje_domicilio", rpta: statusv > 0 ? "OK" : "ERROR->$statusv");

          for (var pasajero in viajes[i].pasajeros) {
            int statusp = await AppDatabase.instance.Guardar(tabla: "pasajero_domicilio", value: pasajero.toJsonBDLocal()); //27/06/2023  -- JOHN SAMUEL : GUARDA EL PASAJERO DOMICILIO EN BD LOCAL

            Log.insertarLogDomicilio(context: context, mensaje: "Guardar pasajero #${pasajero.numDoc} BDLocal -> TBL:pasajero_domicilio", rpta: statusp > 0 ? "OK" : "ERROR->$statusp");
          }

          for (var tripulante in viajes[i].tripulantes) {
            int statust = await AppDatabase.instance.Guardar(tabla: "tripulante", value: tripulante.toMapDatabase()); //27/06/2023  -- JOHN SAMUEL : GUARDA EL TRIPULANTE DOMICILIO EN BD LOCAL

            Log.insertarLogDomicilio(context: context, mensaje: "Guardar tripulante #${tripulante.numDoc} BDLocal -> TBL:tripulante", rpta: statust > 0 ? "OK" : "ERROR->$statust");
          }

          for (var parada in viajes[i].paradas) {
            int statusp = await AppDatabase.instance.Guardar(tabla: "parada", value: parada.toJson()); //27/06/2023  -- JOHN SAMUEL : GUARDA LA PARADA DOMICILIO EN BD LOCAL

            Log.insertarLogDomicilio(context: context, mensaje: "Guardar parada ${parada.direccion} BDLocal -> TBL:tripulante", rpta: statusp > 0 ? "OK" : "ERROR->$statusp");
          }

          for (var paradero in viajes[i].paraderos) {
            int statusprdro = await AppDatabase.instance.Guardar(tabla: "paradero", value: paradero.toJson()); //27/06/2023  -- JOHN SAMUEL : GUARDA LA PARADERO DOMICILIO EN BD LOCAL

            Log.insertarLogDomicilio(context: context, mensaje: "Guardar paradero ${paradero.nombre} BDLocal -> TBL:paradero", rpta: statusprdro > 0 ? "OK" : "ERROR->$statusprdro");
          }
        }

        List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio", where: "seleccionado = '1'");

        ViajeDomicilio viajeselecionado = ViajeDomicilio();
        if (listaViajeDomicilio.isEmpty) {
          List<Map<String, Object?>> listaViajesDomicilios = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");

          for (var i = 0; i < listaViajesDomicilios.length; i++) {
            ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajesDomicilios[i]);

            if (_usuario.viajeEmp.trim() == "") {
              if (_cambioDependencia) context = _navigator.context;

              Navigator.pop(context);

              Log.insertarLogDomicilio(context: context, mensaje: "Discontinuidad con los datos", rpta: "ERROR-> el campo viajeEmp esta vacio");

              _showDialogError(context, "Lo Sentimos", "Error al procesar la consulta. precione en el icono refrescar");
              return;
            }

            if (viaje.nroViaje == _usuario.viajeEmp) {
              int status = await AppDatabase.instance.Update(
                  table: "viaje_domicilio",
                  value: {
                    "seleccionado": "1",
                  },
                  where: "nroViaje = '${viaje.nroViaje}'");

              Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el viaje seleccionado BDLocal -> TBL:viaje_domicilio", rpta: status > 0 ? "OK" : "ERROR->$status");

              viajeselecionado = viaje;
            }
          }
        } else {
          viajeselecionado = ViajeDomicilio.fromJsonMapBDLocal(listaViajeDomicilio[0]);
        }

        await Provider.of<DomicilioProvider>(_navigator.context, listen: false).actualizarViaje(viajeselecionado);

        await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();

        await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();

        ViajeDomicilio? viajeExisteReparto = viajes.firstWhereOrNull((element) => element.sentido == "R");
        if (viajeExisteReparto != null) {
          await AppDatabase.instance.Eliminar(tabla: "posibles_pasajero_domicilio");

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Obtener posibles pasajeros del viaje #${viajeExisteReparto.nroViaje} -> PA:listarPosiblesPasajeros", rpta: "OK");

          final listasPosiblesPasajeros = await viajeServicio.obtenerPosiblesPasajeros(viajeExisteReparto.nroViaje);

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Obtener posibles pasajeros del viaje #${viajeExisteReparto.nroViaje} : ${listasPosiblesPasajeros.length} pasajeros -> PA:listarPosiblesPasajeros", rpta: "OK");

          for (var i = 0; i < listasPosiblesPasajeros.length; i++) {
            // ignore: unused_local_variable
            int status = await AppDatabase.instance.Guardar(
              tabla: "posibles_pasajero_domicilio",
              value: listasPosiblesPasajeros[i].toJsonBDLocal(),
            );
          }

          Log.insertarLogDomicilio(context: context, mensaje: "Guardar posibles pasajeros BDLocal -> TBL:posibles_pasajero_domicilio", rpta: "OK");

          Provider.of<DomicilioProvider>(context, listen: false).asignarPosiblesPasajeros(listasPosiblesPasajeros);
        }
        //

        if (viajeselecionado.sentido == 'I') //Si es Ida (Subida, Recojo)
        {
          //Navigator.popAndPushNamed(context, 'navigationDomicilioRecojo');

          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal SINCRONIZANDO DATOS", rpta: "OK");

          Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla recojo pasajeros", rpta: "OK");

          Navigator.of(context).pushNamedAndRemoveUntil('navigationDomicilioRecojo', (Route<dynamic> route) => false);
        }

        if (viajeselecionado.sentido == 'R') //Si es Retorno (Bajada, Reparto)
        {
          //Navigator.popAndPushNamed(context, 'navigationDomicilioReparto');

          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal SINCRONIZANDO DATOS", rpta: "OK");

          Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla reparto pasajeros", rpta: "OK");

          Navigator.of(context).pushNamedAndRemoveUntil('navigationDomicilioReparto', (Route<dynamic> route) => false);
        }
      } else {
        // _showDialogError(context, "NO SE ENCONTRARON VIAJES", "");

        ingresarEmbarqueOffline(context);
        return;
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;
      Log.insertarLogDomicilio(context: context, mensaje: "No hay conexión a internet", rpta: "OK");
      ingresarEmbarqueOffline(context);
      return;
    }
  }

  ingresarEmbarqueOffline(BuildContext context) async {
    List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio", where: "seleccionado = '1'");

    if (listaViajeDomicilio.isNotEmpty) {
      List<Map<String, Object?>> listaViajeDomi = [...listaViajeDomicilio];

      ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajeDomi[0]);

      await Provider.of<DomicilioProvider>(_navigator.context, listen: false).actualizarViaje(viaje);

      await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();

      await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();

      Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal SINCRONIZANDO DATOS", rpta: "OK");

      Navigator.pop(context, 'Cancel');
      if (viaje.sentido == 'I') //Si es Ida (Subida, Recojo)
      {
        //Navigator.popAndPushNamed(context, 'navigationDomicilioRecojo');

        Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla recojo pasajeros", rpta: "OK");

        Navigator.of(context).pushNamedAndRemoveUntil('navigationDomicilioRecojo', (Route<dynamic> route) => false);
      }

      if (viaje.sentido == 'R') //Si es Retorno (Bajada, Reparto)
      {
        List<Map<String, Object?>> listaPosiblesPasajeros = await AppDatabase.instance.Listar(tabla: "posibles_pasajero_domicilio");

        List<PasajeroDomicilio> posiblesPasajeros = listaPosiblesPasajeros.map((e) => PasajeroDomicilio.fromJsonMapBDLocal(e)).toList();

        Provider.of<DomicilioProvider>(context, listen: false).asignarPosiblesPasajeros(posiblesPasajeros);
        //

        //Navigator.popAndPushNamed(context, 'navigationDomicilioReparto');

        Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla reparto pasajeros", rpta: "OK");

        Navigator.of(context).pushNamedAndRemoveUntil('navigationDomicilioReparto', (Route<dynamic> route) => false);
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;

      Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal SINCRONIZANDO DATOS", rpta: "OK");

      Navigator.pop(context);

      Log.insertarLogDomicilio(context: context, mensaje: "Mensaje modal error sin conexión de internet", rpta: "ERROR");

      _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");
    }
  }

  Future<ViajeDomicilio> actualizarViajeClicEmbarque(Map<String, dynamic> json) async {
    ViajeDomicilio viaje;
    viaje = ViajeDomicilio.fromJsonMapBDLocal(json);

    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero_domicilio", where: "nroViaje = '${viaje.nroViaje}'");

    List<PasajeroDomicilio> pasajeros = listaPasajeros.map((e) => PasajeroDomicilio.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaParada = await AppDatabase.instance.Listar(tabla: "parada", where: "nroViaje = '${viaje.nroViaje}'");

    List<Parada> paradas = listaParada.map((e) => Parada.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaParadero = await AppDatabase.instance.Listar(tabla: "paradero");

    List<Paradero> paraderos = listaParadero.map((e) => Paradero.fromJsonMap(e)).toList();

    viaje.pasajeros = pasajeros;
    viaje.paradas = paradas;
    viaje.paraderos = paraderos;

    return viaje;
  }

  void _showDialogError(BuildContext context, String titulo, String mensaje) {
    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          Timer modalTimer = Timer(const Duration(seconds: 3), () {
            Navigator.pop(context);
          });

          return AlertDialog(
            title: Text(
              titulo,
              textAlign: TextAlign.center,
            ),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () {
                  modalTimer.cancel();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Aceptar",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          );
        });
  }

  AwesomeDialog _showDialogFinalizarJornada(BuildContext context, String dni) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      //customHeader: null,
      animType: AnimType.topSlide,
      //showCloseIcon: true,
      title: '¿${context.read<JornadaBloc>().state.NombreJornadaActual} estas seguro de finalizar su jornada?',
      desc: "",
      reverseBtnOrder: true,
      buttonsTextStyle: const TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        if (await Permission.location.request().isGranted) {}

        _showDialogCargando(context, "cargando");

        final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

        Position cordenadas;
        String latitud;
        String longitud;

        try {
          cordenadas = await Geolocator.getCurrentPosition();
          latitud = "${cordenadas.latitude}";
          longitud = "${cordenadas.longitude}";
        } catch (e) {
          latitud = "0, 0 -Error no controlado";
          longitud = "0, 0 -Error no controlado";
        }

        context.read<JornadaBloc>().add(
              Iniciarjornada(
                dni,
                usuario.viajeEmp,
                "$latitud,$longitud",
                usuario.numDoc,
              ),
            );
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  void _showDialogCargando(BuildContext context, String titulo) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return ModalCargando(titulo: titulo);
      },
    );
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online') {
      return true;
    } else {
      return false;
    }
  }

  void _showDialogSincronizandoDatos(BuildContext context, String titulo) {
    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.mainBlueColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                //content: Text('...'),
                content: const SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          semanticsLabel: 'Circular progress indicator',
                          color: AppColors.blueColor,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              onWillPop: () {
                return Future.value(false);
              });
        });
  }

  void _modalSincronizacionBolsa(BuildContext context) async {
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    if (_hayConexion()) //si hay conexion a internet
    {
      await sincronizarViajeBolsa();
      var viajeServicio = ViajeServicio();
      final viajes = await viajeServicio.obtenerViajesProgramdosBolsa(_usuario);

      if (viajes.isNotEmpty && viajes[0].rpta == "0") {
        await AppDatabase.instance.Eliminar(tabla: "viaje");
        await AppDatabase.instance.Eliminar(tabla: "punto_embarque");
        await AppDatabase.instance.Eliminar(tabla: "pasajero");
        await AppDatabase.instance.Eliminar(tabla: "tripulante");

        for (var i = 0; i < viajes.length; i++) {
          viajes[i].fechaConsultada = DateTime.now().toString();
          await AppDatabase.instance.Guardar(tabla: "viaje", value: viajes[i].toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA EL VIAJE EN BD LOCAL

          final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
            viajes[i].nroViaje,
            viajes[i].codOperacion,
          );

          for (var puntoEmabarque in puntosEmabarque) {
            puntoEmabarque.nroViaje = viajes[i].nroViaje;
            await AppDatabase.instance.Guardar(tabla: "punto_embarque", value: puntoEmabarque.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PUNTOS DE EMBARQUE DEL VIAJE EN BD LOCAL
          }

          var servicio = PasajeroServicio();
          final listadoPrereservas = await servicio.obtener_prereservas(viajes[i].nroViaje, _usuario.tipoDoc, _usuario.numDoc, viajes[i].subOperacionId);

          for (var prereserva in listadoPrereservas) {
            await AppDatabase.instance.Guardar(tabla: "pasajero", value: prereserva.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PRERESERVA DEL VIAJE EN BD LOCAL
          }

          for (var pasajero in viajes[i].pasajeros) {
            await AppDatabase.instance.Guardar(tabla: "pasajero", value: pasajero.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PASAJEROS DEL VIAJE EN BD LOCAL
          }

          for (var j = 0; j < viajes[i].tripulantes.length; j++) {
            if (viajes[i].tripulantes[j].numDoc != "") {
              viajes[i].tripulantes[j].orden = "${j + 1}";
              await AppDatabase.instance.Guardar(tabla: "tripulante", value: viajes[i].tripulantes[j].toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA TRIPULANTES DEL VIAJE EN BD LOCAL
            }
          }
        }

        List<Map<String, Object?>> listaViajeBolsa = await AppDatabase.instance.Listar(tabla: "viaje", where: "seleccionado = '1'");

        Viaje viajeselecionado = Viaje();
        if (listaViajeBolsa.isEmpty) {
          List<Map<String, Object?>> listaViajesBolsa = await AppDatabase.instance.Listar(tabla: "viaje");

          for (var i = 0; i < listaViajesBolsa.length; i++) {
            Viaje viaje = await actualizarViajeEmbarqueBolsaBDLocal(listaViajesBolsa[i]);

            if (viaje.nroViaje == _usuario.viajeEmp) {
              await AppDatabase.instance.Update(
                  table: "viaje",
                  value: {
                    "seleccionado": "1",
                  },
                  where: "nroViaje = '${viaje.nroViaje}'");

              viajeselecionado = viaje;
            }
          }
        } else {
          viajeselecionado = Viaje.fromJsonMapVinculadoLocal(listaViajeBolsa[0]);
        }

        await Provider.of<ViajeProvider>(_navigator.context, listen: false).viajeActual(viaje: viajeselecionado);

        // if (_cambioDependencia) context = _navigator.context;
        // await AppDatabase.instance.insertarViaje(viaje); //Si existe el viaje lo inserta o actualiza

        // if (_cambioDependencia) context = _navigator.context;

        Navigator.pop(context, 'Cancel');

        Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
      } else {
        if (_cambioDependencia) context = _navigator.context;

        ingresarEmbarqueBolsaOffline(context);
        // Navigator.pop(context, 'Cancel');

        // _showDialogError(context, "NO SE PUDO SINCRONIZAR", viajes[].mensaje!);
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;

      // Navigator.pop(context);
      // _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");

      ingresarEmbarqueBolsaOffline(context);
    }
  }

  ingresarEmbarqueBolsaOffline(BuildContext context) async {
    List<Map<String, Object?>> listaViaje = await AppDatabase.instance.Listar(tabla: "viaje", where: "seleccionado = '1'");

    if (listaViaje.isNotEmpty) {
      List<Map<String, Object?>> listaViajeBolsa = [...listaViaje];

      Viaje viaje = await actualizarViajeEmbarqueBolsaBDLocal(listaViajeBolsa[0]);

      await Provider.of<ViajeProvider>(_navigator.context, listen: false).viajeActual(viaje: viaje);

      //Navigator.popAndPushNamed(context, 'navigationDomicilioReparto');

      Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
    } else {
      if (_cambioDependencia) context = _navigator.context;

      Navigator.pop(context);

      _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");
    }
  }

  Future<Viaje> actualizarViajeEmbarqueBolsaBDLocal(Map<String, dynamic> json) async {
    Viaje viaje;
    viaje = Viaje.fromJsonMapVinculadoLocal(json);

    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero");
    List<Pasajero> pasajeros = listaPasajeros.map((e) => Pasajero.fromJsonMapDBLocal(e)).toList();

    List<Map<String, Object?>> listaPuntosEmbarque = await AppDatabase.instance.Listar(tabla: "punto_embarque", where: "nroViaje = '${viaje.nroViaje}'");
    List<PuntoEmbarque> puntosEmbarque = listaPuntosEmbarque.map((e) => PuntoEmbarque.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaTripulantes = await AppDatabase.instance.Listar(tabla: "tripulante", where: "nroViaje = '${viaje.nroViaje}'");

    List<Tripulante> tripulantes = listaTripulantes.map((e) => Tripulante.fromJsonMap(e)).toList();

    viaje.pasajeros = pasajeros;
    viaje.puntosEmbarque = puntosEmbarque;
    viaje.tripulantes = tripulantes;

    return viaje;
  }

  int calcularCantidadRepartidos(ViajeDomicilio viaje) {
    int cantRepartidos = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 1 && viaje.pasajeros[i].fechaDesembarque != "") {
        cantRepartidos++;
      }
    }

    return cantRepartidos;
  }

  int calcularCantidadEmbarcados(ViajeDomicilio viaje) {
    int cantEmbarcados = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 1) {
        cantEmbarcados++;
      }
    }

    return cantEmbarcados;
  }

  void _supervisorMultipleCargarDatos(BuildContext context) async {
    if (_hayConexion()) {
      _showDialogSincronizandoDatos(context, "CARGANDO");

      await AppDatabase.instance.Eliminar(tabla: "punto_embarque");

      var viajeServicio = ViajeServicio();
      final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXFecha(_usuario);
      for (var puntoEmabarque in puntosEmabarque) {
        puntoEmabarque.nroViaje = "0";
        await AppDatabase.instance.Guardar(tabla: "punto_embarque", value: puntoEmabarque.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PUNTOS DE EMBARQUE DEL VIAJE EN BD LOCAL
      }

      Navigator.pop(context, 'Cancel');

      Navigator.of(context).pushNamedAndRemoveUntil('embarqueMultipleSupervisor', (Route<dynamic> route) => false);
    } else {
      _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");
    }
  }

  void _supervisorCargarViajeRemoteOLocal(BuildContext context, String tdocConductor, String nDocConductor, String numViaje) async {
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    if (_hayConexion()) //si hay conexion a internet
    {
      await sincronizarViajeBolsa();
      var viajeServicio = ViajeServicio();
      final viaje = await viajeServicio.obtenerViajeVinculadoBolsaSupervisor_v4(tdocConductor, nDocConductor, numViaje);

      if (viaje.rpta == "0") {
        await AppDatabase.instance.Eliminar(tabla: "viaje");
        await AppDatabase.instance.Eliminar(tabla: "punto_embarque");
        await AppDatabase.instance.Eliminar(tabla: "pasajero");
        await AppDatabase.instance.Eliminar(tabla: "tripulante");

        viaje.fechaConsultada = DateTime.now().toString();
        await AppDatabase.instance.Guardar(tabla: "viaje", value: viaje.toMapDatabase()); //27/06/2023 16:53 -- JOHN SAMUEL : GUARDA EL VIAJE EN BD LOCAL

        final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
          viaje.nroViaje,
          viaje.codOperacion,
        );

        for (var puntoEmabarque in puntosEmabarque) {
          puntoEmabarque.nroViaje = viaje.nroViaje;
          await AppDatabase.instance.Guardar(tabla: "punto_embarque", value: puntoEmabarque.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PUNTOS DE EMBARQUE DEL VIAJE EN BD LOCAL
        }

        var servicio = PasajeroServicio();
        final listadoPrereservas = await servicio.obtener_prereservas(viaje.nroViaje, _usuario.tipoDoc, _usuario.numDoc, viaje.subOperacionId);

        for (var prereserva in listadoPrereservas) {
          await AppDatabase.instance.Guardar(tabla: "pasajero", value: prereserva.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PRERESERVA DEL VIAJE EN BD LOCAL
        }

        for (var pasajero in viaje.pasajeros) {
          await AppDatabase.instance.Guardar(tabla: "pasajero", value: pasajero.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PASAJEROS DEL VIAJE EN BD LOCAL
        }

        for (var j = 0; j < viaje.tripulantes.length; j++) {
          if (viaje.tripulantes[j].numDoc != "") {
            viaje.tripulantes[j].orden = "${j + 1}";
            await AppDatabase.instance.Guardar(tabla: "tripulante", value: viaje.tripulantes[j].toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA TRIPULANTES DEL VIAJE EN BD LOCAL
          }
        }

        List<Map<String, Object?>> listaViajeBolsa = await AppDatabase.instance.Listar(tabla: "viaje", where: "seleccionado = '1'");

        Viaje viajeselecionado = Viaje();
        if (listaViajeBolsa.isEmpty) {
          List<Map<String, Object?>> listaViajesBolsa = await AppDatabase.instance.Listar(tabla: "viaje");

          for (var i = 0; i < listaViajesBolsa.length; i++) {
            Viaje viaje = await actualizarViajeEmbarqueBolsaBDLocal(listaViajesBolsa[i]);

            final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

            if (viaje.nroViaje == usuario.viajeEmp) {
              await AppDatabase.instance.Update(
                  table: "viaje",
                  value: {
                    "seleccionado": "1",
                  },
                  where: "nroViaje = '${viaje.nroViaje}'");

              viajeselecionado = viaje;
            }
          }
        } else {
          viajeselecionado = Viaje.fromJsonMapVinculadoLocal(listaViajeBolsa[0]);
        }

        await Provider.of<ViajeProvider>(_navigator.context, listen: false).viajeActual(viaje: viajeselecionado);

        Navigator.pop(context, 'Cancel');

        Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
      } else {
        if (_cambioDependencia) context = _navigator.context;

        ingresarEmbarqueBolsaOffline(context);
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;

      // Navigator.pop(context);
      // _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");

      ingresarEmbarqueBolsaOffline(context);
    }
  }

  Future<UsuarioGeop> validarTodasUnidadesGEOP() async {
    Usuario user = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    UsuarioGeopServicio usuarioGeopServicio = UsuarioGeopServicio();

    var usuarioGeopResponse = await usuarioGeopServicio.GeopvalidarUnidades(
      idUsuario: user.usuarioId!,
      tipoDoc: user.tipoDoc,
      ndoc: user.numDoc,
      paterno: user.apellidoPat,
      materno: user.apellidoMat,
      nombres: user.nombres,
    );

    return usuarioGeopResponse;
  }

  Future<void> verificarVersion() async {
    String versionActual = AppData.appVersion; // '4.3.1+33'
    ActualVersion? versionRequerida = await VersionService().fetchUltimaVersion();

    if (versionRequerida == null) {
      return;
    }
    String versionRequeridaStr = versionRequerida.version;

    // Compara las versiones
    if (compararVersiones(versionActual, versionRequeridaStr) < 0) {
      mostrarDialogoDeActualizacion(context);
    }
  }

  void mostrarDialogoDeActualizacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)), // Redondea las esquinas superiores
      ),
      isScrollControlled: true, // Permite controlar la altura del BottomSheet
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: const Column(
                  mainAxisSize: MainAxisSize.min, // Esto asegura que el BottomSheet se ajuste al contenido
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '  ¡Actualización Disponible!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      //textAlign: TextAlign.start,
                    ),
                    SizedBox(height: 10),
                    Text(
                      '¡Descárga la nueva versión YA!',
                      //textAlign: TextAlign.start,
                      style: TextStyle(fontSize: 16),
                    )
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  launchStore();
                },
                style: TextButton.styleFrom(
                    backgroundColor: AppColors.mainBlueColor, // Aquí defines el color de fondo
                    foregroundColor: AppColors.whiteColor, // Aquí defines el color del texto
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Borde redondeado
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
                child: Text('Actualizar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  int compararVersiones(String version1, String version2) {
    List<String> partes1 = version1.split('+');
    List<String> partes2 = version2.split('+');

    List<int> version1Partes = partes1[0].split('.').map((e) => int.parse(e)).toList();
    List<int> version2Partes = partes2[0].split('.').map((e) => int.parse(e)).toList();

    for (int i = 0; i < version1Partes.length; i++) {
      if (i >= version2Partes.length) return 1;
      if (version1Partes[i] < version2Partes[i]) return -1;
      if (version1Partes[i] > version2Partes[i]) return 1;
    }

    int build1 = int.parse(partes1[1]);
    int build2 = int.parse(partes2[1]);

    if (build1 < build2) return -1;
    if (build1 > build2) return 1;

    return 0;
  }

  Future<void> launchStore() async {
    String url;

    if (Platform.isAndroid) {
      url = 'https://play.google.com/store/apps/details?id=pe.linea.lineaempresa';
    } else if (Platform.isIOS) {
      url = 'https://apps.apple.com/app/id/TU_ID';
    } else {
      url = 'https://example.com';
    }

    final Uri uri = Uri.parse(url);

    // Intenta lanzar la URL con el nuevo método launchUrl
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication); // Usar LaunchMode para abrir la aplicación externa
    } else {
      throw 'No se pudo abrir la URL: $url';
    }
  }
}

class ImagesCardHome extends StatelessWidget {
  final String image;

  const ImagesCardHome({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.30,
      width: (MediaQuery.of(context).size.width * 0.35),
      decoration: BoxDecoration(
        // color: Colors.amber,
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
