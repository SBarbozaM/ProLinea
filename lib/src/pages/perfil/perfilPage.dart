// ignore_for_file: use_build_context_synchronously

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:collection/collection.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/paradero.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/impresoraProvider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/google_services.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_data.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
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
    final width = MediaQuery.of(context).size.width;
    final heightw = MediaQuery.of(context).size.height;
    Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    //Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: width,
            height: heightw,
            child: Stack(
              children: [
                Positioned(
                  child: Container(
                    height: heightw * 0.2,
                    width: width,
                    color: AppColors.mainBlueColor,
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.end,
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.bottomCenter,
                              height: 65,
                              width: width,
                              child: Text(
                                usuario.nombreOperacion,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        // Column(
                        //   mainAxisAlignment: MainAxisAlignment.end,
                        //   crossAxisAlignment: CrossAxisAlignment.end,
                        //   children: [
                        //     const Text(
                        //       "Versión ${AppData.appVersion}",
                        //       style: TextStyle(fontSize: 16, color: AppColors.greyColor),
                        //     ),
                        //     const FittedBox(
                        //       child: Text(
                        //         AppData.appFechaCompilacion,
                        //         style: TextStyle(color: AppColors.blackColor, fontSize: 12),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: heightw * 0.1,
                  child: SizedBox(
                    height: heightw * 0.2,
                    width: width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: heightw * 0.2,
                          width: heightw * 0.2,
                          decoration: BoxDecoration(
                            color: AppColors.greyColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 62 + (62 / 2),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: heightw * 0.3,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        Text(
                          "${usuario.nombres} ${usuario.apellidoPat} ${usuario.apellidoMat}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.mainBlueColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          usuario.perfil,
                          style: const TextStyle(
                            color: AppColors.mainBlueColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "${usuario.tipoDoc}: ${usuario.numDoc}",
                          style: const TextStyle(
                            color: AppColors.mainBlueColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // const SizedBox(
                        //   height: 5,
                        // ),
                        // const Text(
                        //   "versión ${AppData.appVersion}",
                        //   style: TextStyle(fontSize: 14, color: AppColors.greyColor),
                        // ),
                        // const FittedBox(
                        //   child: Text(
                        //     AppData.appFechaCompilacion,
                        //     style: TextStyle(color: AppColors.blackColor, fontSize: 10),
                        //   ),
                        // ),
                        SizedBox(
                          height: heightw * 0.05,
                        ),
                        if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUECONDUCTOR") != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ListTile(
                              title: const Text(
                                "Cerrar Sesión",
                                style: TextStyle(
                                  color: AppColors.redColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: Provider.of<UsuarioProvider>(context, listen: true).usuario.viajeEmp.trim() == ""
                                  ? () {
                                      showDialog<String>(
                                        context: context,
                                        builder: (BuildContext context) => AlertDialog(
                                          title: const Text('CERRAR SESIÓN'),
                                          content: const Text('¿Seguro que desea cerrar sesión?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, 'Cancel'),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                _insertarEventoAnalytics('logout', usuario, '');

                                                _showDialogSincronizandoDatos(context, "Cerrando Sesión");
                                                // Provider.of<ImpresoraProvider>(context, listen: false).actualizarImpresora(null); /* NUEVO 05/05/23 */
                                                String fechaCierraSesion = DateFormat.yMd().add_Hms().format(DateTime.now());

                                                UsuarioServicio usuarioServicio = UsuarioServicio();
                                                final SharedPreferences prefs = await SharedPreferences.getInstance();
                                                String rpta = await usuarioServicio.cerrarSesion(usuario.tipoDoc, usuario.numDoc, AppData.appVersion, fechaCierraSesion);
                                                if (rpta == "0") {
                                                  prefs.setString('CS', '');
                                                  //await Navigator.popAndPushNamed(context, '/');

                                                  await sincronizarViaje();
                                                  await AppDatabase.instance.Update(
                                                    table: "usuario",
                                                    value: {"sesionActiva": '0', "sesionSincronizada": "0"},
                                                    where: "numDoc='${usuario.numDoc}'",
                                                  );

                                                  Navigator.of(context).pushNamedAndRemoveUntil('login', (Route<dynamic> route) => false);
                                                } else {
                                                  String datosCerrarSesion = "${usuario.tipoDoc}^${usuario.numDoc}^$fechaCierraSesion";

                                                  prefs.setString('CS', datosCerrarSesion);

                                                  await AppDatabase.instance.Update(
                                                    table: "usuario",
                                                    value: {"sesionActiva": '0', "sesionSincronizada": "1"},
                                                    where: "numDoc='${usuario.numDoc}'",
                                                  );

                                                  //await Navigator.popAndPushNamed(context, '/');
                                                  Navigator.of(context).pushNamedAndRemoveUntil('login', (Route<dynamic> route) => false);
                                                }
                                              },
                                              child: const Text('Sí'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  : () {
                                      _showDialogFinalizar(context, usuario).show();
                                    },
                              trailing: const Icon(
                                Icons.logout_outlined,
                                color: AppColors.redColor,
                              ),
                            ),
                          ),
                        if (usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUECONDUCTOR") == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ListTile(
                              title: const Text(
                                "Cerrar Sesión",
                                style: TextStyle(
                                  color: AppColors.redColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: const Text('CERRAR SESIÓN'),
                                    content: const Text('¿Seguro que desea cerrar sesión?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, 'Cancel'),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          _showDialogSincronizandoDatos(context, "Cerrando Sesión");
                                          // Provider.of<ImpresoraProvider>(context, listen: false).actualizarImpresora(null); /* NUEVO 05/05/23 */
                                          String fechaCierraSesion = DateFormat.yMd().add_Hms().format(DateTime.now());
                                          await AppDatabase.instance.Eliminar(tabla: "accionesUsuario");

                                          UsuarioServicio usuarioServicio = UsuarioServicio();
                                          final SharedPreferences prefs = await SharedPreferences.getInstance();
                                          String rpta = await usuarioServicio.cerrarSesion(usuario.tipoDoc, usuario.numDoc, AppData.appVersion, fechaCierraSesion);
                                          if (rpta == "0") {
                                            prefs.setString('CS', '');
                                            //await Navigator.popAndPushNamed(context, '/');

                                            await sincronizarViaje();
                                            await AppDatabase.instance.Update(
                                              table: "usuario",
                                              value: {"sesionActiva": '0', "sesionSincronizada": "0"},
                                              where: "numDoc='${usuario.numDoc}'",
                                            );

                                            Navigator.of(context).pushNamedAndRemoveUntil('login', (Route<dynamic> route) => false);
                                          } else {
                                            String datosCerrarSesion = "${usuario.tipoDoc}^${usuario.numDoc}^$fechaCierraSesion";

                                            prefs.setString('CS', datosCerrarSesion);

                                            await AppDatabase.instance.Update(
                                              table: "usuario",
                                              value: {"sesionActiva": '0', "sesionSincronizada": "1"},
                                              where: "numDoc='${usuario.numDoc}'",
                                            );

                                            //await Navigator.popAndPushNamed(context, '/');
                                            Navigator.of(context).pushNamedAndRemoveUntil('login', (Route<dynamic> route) => false);
                                          }
                                        },
                                        child: const Text('Sí'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              trailing: const Icon(
                                Icons.logout_outlined,
                                color: AppColors.redColor,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: heightw * 0.15,
                        ),
                        const Text(
                          "Versión ${AppData.appVersion}",
                          style: TextStyle(fontSize: 18, color: AppColors.blackColor),
                        ),
                        const FittedBox(
                          child: Text(
                            AppData.appFechaCompilacion,
                            style: TextStyle(color: AppColors.blackColor, fontSize: 15),
                          ),
                        ),
                        SizedBox(
                          height: heightw * 0.01,
                        ),
                        Text(
                          Provider.of<UsuarioProvider>(context, listen: false).idDispositivo,
                          style: const TextStyle(fontSize: 17, color: AppColors.blackColor),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
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

  AwesomeDialog _showDialogFinalizar(BuildContext context, Usuario usuario) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      //customHeader: null,
      animType: AnimType.topSlide,
      //showCloseIcon: true,

      desc: "",

      body: Column(
        children: [
          // if (minutosTr < 30)
          Text(
            "¿No puedes cerrar sesión porque no ha finalizado el viaje de la unidad ${usuario.unidadEmp}-${usuario.placaEmp}?",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),
        ],
      ),
      reverseBtnOrder: true,
      buttonsTextStyle: const TextStyle(fontSize: 30),
      btnOkText: "Ir a inicio",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        setState(() {});
        Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
      },
      onDismissCallback: (type) {
        setState(() {});
      },
    );
  }

  Future<void> sincronizarViaje() async {
    List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");
    List<Map<String, Object?>> listaViajeDomi = [...listaViajeDomicilio];

    if (listaViajeDomi.isNotEmpty) {
      for (var i = 0; i < listaViajeDomi.length; i++) {
        ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajeDomi[i]);
        final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

        if (viaje.sentido == "I") {
          await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioDesdeHome(usuario.tipoDoc, usuario.numDoc, context, viaje);
        } else if (viaje.sentido == "R") {
          await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioRepartoDesdeHome(usuario.tipoDoc, usuario.numDoc, context, viaje);
        }
      }
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

  void _insertarEventoAnalytics(String nombreEvento, Usuario usuario, String dataAdicional) async {
    await GoogleServices.setEvent(
      nombreEvento: nombreEvento,
      usuario: usuario,
      dataAdicional: dataAdicional,
    );
  }
}
