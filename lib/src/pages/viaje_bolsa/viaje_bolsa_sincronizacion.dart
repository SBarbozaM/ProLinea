import 'dart:async';

import 'package:embarques_tdp/src/components/warning_widget_internet.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../models/pasajero.dart';
import '../../models/usuario.dart';
import '../../models/viaje.dart';
import '../../providers/connection_status_provider.dart';
import '../../providers/providers.dart';
import '../../services/pasajero_servicio.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_database.dart';

class ViajeBolsaSincronizacionPage extends StatefulWidget {
  const ViajeBolsaSincronizacionPage({Key? key}) : super(key: key);

  @override
  State<ViajeBolsaSincronizacionPage> createState() =>
      _ViajeBolsaSincronizacionPageState();
}

class _ViajeBolsaSincronizacionPageState
    extends State<ViajeBolsaSincronizacionPage> {
  ViajeServicio servicio = new ViajeServicio();
  late Timer _timer;
  late Usuario _usuario;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _timer = new Timer.periodic(Duration(seconds: 2), (timer) {
      /*Provider.of<ViajeProvider>(context, listen: false)
          .sincronizacionContinuaDeViaje(_usuario.tipoDoc, _usuario.numDoc);*/
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Viaje _viaje = Provider.of<ViajeProvider>(context, listen: false).viaje;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 60,
                        ),
                        const Center(
                          child: Text(
                            'SINCRONIZACIÓN',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ResponsiveWidget.isSmallScreen(context)
                      ? Column(
                          children: [
                            _botonEnviarDatos(width),
                            const SizedBox(
                              height: 20,
                            ),
                            _botonDescargarDatos(width, _viaje),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _botonEnviarDatos(height),
                            const SizedBox(
                              width: 20,
                            ),
                            _botonDescargarDatos(height, _viaje),
                          ],
                        ),
                ],
              ),
            ),
          ),
          WarningWidgetInternet(),
        ],
      )),
    );
  }

  Widget _botonEnviarDatos(double width) {
    return SizedBox(
      width: width * 0.80,
      child: TextButton(
        style: ButtonStyle(
          foregroundColor:
              MaterialStateProperty.all<Color>(AppColors.whiteColor),
          backgroundColor: MaterialStateProperty.all<Color>(
              _hayConexion() ? AppColors.mainBlueColor : AppColors.greyColor),
        ),
        onPressed: !_hayConexion()
            ? null
            : () async {
                Viaje viajeActual =
                    Provider.of<ViajeProvider>(context, listen: false).viaje;
                String mensaje = "Este viaje no tiene pasajeros";
                bool esError = true;

                if (viajeActual.pasajeros.isNotEmpty) {
                  _dialogSincronizando('ENVIANDO DATOS', 'AZUL');

                  mensaje = "No hay datos para enviar";
                  PasajeroServicio pasajeroServicio = new PasajeroServicio();
                  int numeroPasajerosPorSincronizar = 0;

                  List<Pasajero> pasajerosEliminar = [];

                  loop:
                  for (int i = 0; i < viajeActual.pasajeros.length; i++) {
                    String nuevoNroViaje = "0";
                    if (viajeActual.pasajeros[i].modificado == 0 ||
                        viajeActual.pasajeros[i].modificado == 2) {
                      if (viajeActual.pasajeros[i].embarcado == 0)
                        nuevoNroViaje = "0";
                      else
                        nuevoNroViaje = viajeActual.nroViaje;

                      //datosPorSincronizar = true;
                      String rpta =
                          await pasajeroServicio.cambiarEstadoPrereserva(
                              viajeActual.pasajeros[i],
                              viajeActual.codOperacion,
                              nuevoNroViaje,
                              _usuario.tipoDoc + _usuario.numDoc);

                      switch (rpta) {
                        case "0":
                          //datosPorSincronizar = false;
                          viajeActual.pasajeros[i].modificado = 1;
                          //Actualizamos el pasajero en la BD  local
                          if (viajeActual.pasajeros[i].embarcado == 0) {
                            await Provider.of<PrereservaProvider>(context,
                                    listen: false)
                                .agregarPrereserva(viajeActual.pasajeros[i]);
                            AppDatabase.instance.insertarActualizarPasajero(
                                viajeActual.pasajeros[i]);
                            pasajerosEliminar.add(viajeActual.pasajeros[i]);
                          } else {
                            AppDatabase.instance.insertarActualizarPasajero(
                                viajeActual.pasajeros[i]);
                            Provider.of<ViajeProvider>(context, listen: false)
                                .viajeActual(viaje: viajeActual);
                          }

                          mensaje = "Datos enviados correctamente";
                          esError = false;

                          break;
                        case "1":
                          //datosPorSincronizar = false;
                          pasajerosEliminar.add(viajeActual.pasajeros[i]);
                          break;
                        case "2":
                          break;
                        case "3":
                          //datosPorSincronizar = true;
                          mensaje =
                              "Hubo un error mientras se enviaban los datos";
                          break loop;
                        case "9":
                          //datosPorSincronizar = true;
                          mensaje = "Se perdió la conexión a internet";
                          break loop;
                        default:
                      }
                    }
                  }

                  for (Pasajero pEliminar in pasajerosEliminar) {
                    AppDatabase.instance.eliminarPasajero(pEliminar);
                    viajeActual.pasajeros.removeWhere(
                        (element) => element.numDoc == pEliminar.numDoc);
                  }

                  Provider.of<ViajeProvider>(context, listen: false)
                      .viajeActual(viaje: viajeActual);

                  viajeActual =
                      Provider.of<ViajeProvider>(context, listen: false).viaje;

                  for (int i = 0; i < viajeActual.pasajeros.length; i++) {
                    if (viajeActual.pasajeros[i].modificado == 0 ||
                        viajeActual.pasajeros[i].modificado == 2)
                      numeroPasajerosPorSincronizar += 1;
                  }

                  if (numeroPasajerosPorSincronizar > 0) {
                    datosPorSincronizar = true;
                  } else {
                    datosPorSincronizar = false;
                  }

                  setState(() {});
                  Navigator.pop(context);
                  _mostrarMensaje(mensaje, esError);
                } else {
                  _mostrarMensaje(mensaje, esError);
                }
              },
        child: const Text("ENVIAR DATOS DE EMBARQUE"),
      ),
    );
  }

  Widget _botonDescargarDatos(double width, Viaje _viaje) {
    return SizedBox(
      width: width * 0.80,
      child: TextButton(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all<Color>(AppColors.whiteColor),
            backgroundColor: MaterialStateProperty.all<Color>(
                _hayConexion() ? AppColors.redColor : AppColors.greyColor)),
        onPressed: !_hayConexion()
            ? null
            : () async {
                Viaje viajeActualizado = await servicio.obtenerViajeConductor(
                    _usuario.tipoDoc, _usuario.numDoc, _viaje.nroViaje);

                switch (viajeActualizado.rpta) {
                  case '0':
                    _dialogSincronizando('DESCARGANDO DATOS', 'ROJO');
                    await AppDatabase.instance.insertarViaje(
                        viajeActualizado); //Si existe el viaje lo inserta o actualiza

                    Provider.of<ViajeProvider>(context, listen: false)
                        .viajeActual(viaje: viajeActualizado);

                    //PUNTOS EMBARQUE LOCAL
                    /*List<PuntoEmbarque> pEmbarqueLocal = await AppDatabase
                        .instance
                        .obtenerTodosPuntosEmbarqueDeViaje(viajeActualizado);

                    if (pEmbarqueLocal.isNotEmpty) {
                      Provider.of<ViajeProvider>(context, listen: false)
                          .puntosEmbarqueViajeActuales(
                              puntosEmbarque: pEmbarqueLocal);
                    }*/

                    //PRERESERVAS

                    final usuarioProvider =
                        Provider.of<UsuarioProvider>(context, listen: false)
                            .usuario;

                    await Provider.of<PrereservaProvider>(context,
                            listen: false)
                        .obtenerListadoPrereservasBD(
                      viajeActualizado.nroViaje,
                      usuarioProvider.tipoDoc,
                      usuarioProvider.numDoc,
                      viajeActualizado.codOperacion,
                    );

                    List<Pasajero> listadoPrereservas =
                        await Provider.of<PrereservaProvider>(context,
                                listen: false)
                            .listdoPrereservas;

                    await AppDatabase.instance
                        .insertarPrereservas(listadoPrereservas);

                    Navigator.pop(context);
                    _mostrarMensaje("Datos actualizados correctamente", false);
                    setState(() {});
                    break;
                  case '1':
                    _mostrarMensaje("Este viaje ya ha sido cerrado", true);
                    await AppDatabase.instance
                        .eliminarTodoDeUnViaje(_viaje.nroViaje);
                    Navigator.pushNamed(context, 'inicio');
                    break;
                  case '9':
                    _mostrarMensaje("Revise su conexión a Internet", true);
                    break;
                  default:
                    _mostrarMensaje("Error! Inténtelo otra vez", true);
                }
              },
        child: const Text(
          "DESCARGAR DATOS DE EMBARQUE",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context).status.name == 'online')
      return true;
    else
      return false;
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _mostrarMensaje(
      String mensaje, bool esError) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        mensaje,
        style: TextStyle(color: AppColors.whiteColor),
        textAlign: TextAlign.center,
      ),
      duration: Duration(seconds: 2),
      //behavior: SnackBarBehavior.floating,
      //margin: EdgeInsets.only(bottom: 50, right: 50, left: 50),
      backgroundColor: esError ? AppColors.redColor : AppColors.greenColor,
    ));
  }

  _dialogSincronizando(String titulo, String color) {
    Color colorTitulo = AppColors.mainBlueColor;

    switch (color) {
      case "ROJO":
        colorTitulo = AppColors.redColor;
        break;
      case "AZUL":
        colorTitulo = AppColors.blueColor;
        break;
      default:
    }

    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorTitulo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                //content: Text('...'),
                content: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Circular progress indicator',
                            color: colorTitulo,
                          ),
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
}
