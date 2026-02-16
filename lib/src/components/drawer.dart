import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/Bloc/unidadScaner/embarques_sup_scaner_bloc.dart';
import 'package:embarques_tdp/src/Bloc/vincularInicio/vincular_inicio_bloc.dart';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pasajero.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';
import '../providers/impresoraProvider.dart';
import '../services/viaje_servicio.dart';
import '../utils/app_colors.dart';
import '../utils/app_data.dart';
import '../utils/app_database.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  late NavigatorState _navigator;
  bool _cambioDependencia = false;
  late Usuario _usuario;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    super.initState();
  }

  // @override
  // void dispose() {
  //   _navigator.dispose();
  //   super.dispose();
  // }

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
    return SafeArea(
      child: Drawer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 40,
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Text(
                        _usuario.nombreOperacion,
                        style: TextStyle(color: AppColors.mainBlueColor, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
              cabecera(context),
              listaElementos(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget cabecera(BuildContext context) => Material(
        color: AppColors.mainBlueColor,
        child: InkWell(
          onTap: () {},
          child: Container(
            padding: EdgeInsets.only(
              bottom: 24,
              left: 5,
              right: 5,
            ),
            color: AppColors.mainBlueColor,
            child: Column(children: [
              SizedBox(height: 8),
              CircleAvatar(
                radius: 52,
                child: Icon(
                  Icons.person,
                  size: 52 + (52 / 2),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                "${_usuario.nombres} ${_usuario.apellidoPat} ${_usuario.apellidoMat}",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                _usuario.perfil,
                style: TextStyle(color: AppColors.whiteColor),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                "${_usuario.tipoDoc}: ${_usuario.numDoc}",
                style: TextStyle(color: AppColors.whiteColor),
              ),
              SizedBox(
                height: 5,
              ),
              /*Text(
                _usuario.perfil,
                style: TextStyle(color: AppColors.whiteColor),
              ),*/
              _usuario.unidadEmp == ""
                  ? SizedBox()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: AppColors.whiteColor,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          _usuario.unidadEmp + "-" + _usuario.placaEmp,
                          style: TextStyle(color: AppColors.whiteColor),
                        )
                      ],
                    )
            ]),
          ),
        ),
      );

  Widget listaElementos(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          //runSpacing: 16,
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text("Inicio"),
              onTap: () {
                //Navigator.pop(context);
                //Navigator.popAndPushNamed(context, 'inicio');
                Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
              },
            ),
            if (_usuario.perfil.trim() == 'CONDUCTOR')
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text("Vincular"),
                trailing: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _obtenerDatosVinculacion(context);
                      _mensaje(context, "Actualizado Correctamente").show();
                    },
                    icon: Icon(Icons.refresh)),
                onTap: () {
                  //Navigator.pop(context);
                  //Navigator.popAndPushNamed(context, 'emparejarQR');
                  Navigator.of(context).pushNamedAndRemoveUntil('emparejarQR', (Route<dynamic> route) => false);
                },
              ),
            if (_usuario.perfil.trim() == 'CONDUCTOR' && _usuario.viajeEmp != "" && _usuario.unidadEmp != "")
              ListTile(
                leading: const Icon(Icons.departure_board),
                title: const Text("Embarque"),
                onTap: () {
                  Navigator.pop(context);

                  if (_usuario.domicilio == "1") {
                    _modalSincronizacionDomicilio(context);
                  } else {
                    _modalSincronizacion(context);
                  }

                  /*Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ListaViajesPage(),
                  ),
                );*/
                },
              ),
            // if (_usuario.perfil.trim() == 'CONDUCTOR' &&
            //     _usuario.viajeEmp != "" &&
            //     _usuario.unidadEmp != "")
            //   ListTile(
            //     leading: const Icon(Icons.file_present_outlined),
            //     title: const Text("Documentos"),
            //     onTap: () {
            //       Navigator.of(context).pushNamedAndRemoveUntil(
            //           'documentosPage', (Route<dynamic> route) => false);
            //     },
            //   ),

            if (_usuario.perfil.trim() == 'SUPERVISOR')
              ListTile(
                leading: const Icon(Icons.directions_bus_filled),
                title: const Text("Embarques"),
                onTap: () async {
                  ////Shared Preferences
                  _showDialogSincronizandoDatos(context, "Cargando...");
                  final SharedPreferences pref = await SharedPreferences.getInstance();

                  String? usuarioVinculado = await pref.getString("usuarioVinculado");

                  print(usuarioVinculado);

                  if (usuarioVinculado == null) {
                    context.read<EmbarquesSupScanerBloc>().add(resetEstadoEscanearUnidadInitial());
                    context.read<VincularInicioBloc>().add(resetEstadoVincularInitial());
                    Navigator.of(context).pushNamedAndRemoveUntil('embarquesSupervisorScaner', (Route<dynamic> route) => false);
                  } else {
                    final usuarioObjeto = jsonDecode(usuarioVinculado);
                    print(usuarioObjeto["nDocConductor"].toString().trim());
                    context.read<EmbarquesSupScanerBloc>().add(EditarEstadoEscanearUnidadSuccessSup(
                          usuarioObjeto["nDocConductor"].toString().trim(),
                          usuarioObjeto["numViaje"],
                        ));
                    context.read<VincularInicioBloc>().add(EditarEstadoVincularSuccess(
                          usuarioObjeto["tDocConductor"],
                          usuarioObjeto["nDocConductor"].toString().trim(),
                        ));

                    var viajeServicio = new ViajeServicio();
                    Viaje viaje = await viajeServicio.obtenerViajeVinculadoBolsaSupervisor_v4(
                      usuarioObjeto["tDocConductor"],
                      usuarioObjeto["nDocConductor"].toString().trim(),
                      usuarioObjeto["numViaje"],
                    );

                    Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viaje);
                    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;

                    await Provider.of<PrereservaProvider>(context, listen: false).obtenerListadoPrereservasBD(
                      viaje.nroViaje,
                      usuarioProvider.tipoDoc,
                      usuarioProvider.numDoc,
                      viaje.subOperacionId,
                    );
                    Navigator.pop(context);

                    Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
                  }
                },
              ),

            if (_usuario.perfil.trim() == 'EMBARCADOR')
              ListTile(
                leading: const Icon(Icons.directions_bus_filled),
                title: const Text("Embarques"),
                onTap: () async {
                  ////Shared Preferences
                  _showDialogSincronizandoDatos(context, "Cargando...");
                  final SharedPreferences pref = await SharedPreferences.getInstance();

                  String? usuarioVinculado = await pref.getString("usuarioVinculado");

                  print(usuarioVinculado);

                  if (usuarioVinculado == null) {
                    context.read<EmbarquesSupScanerBloc>().add(resetEstadoEscanearUnidadInitial());
                    context.read<VincularInicioBloc>().add(resetEstadoVincularInitial());
                    Navigator.of(context).pushNamedAndRemoveUntil('embarquesSupervisorScaner', (Route<dynamic> route) => false);
                  } else {
                    final usuarioObjeto = jsonDecode(usuarioVinculado);
                    print(usuarioObjeto["nDocConductor"].toString().trim());
                    context.read<EmbarquesSupScanerBloc>().add(EditarEstadoEscanearUnidadSuccessSup(
                          usuarioObjeto["nDocConductor"].toString().trim(),
                          usuarioObjeto["numViaje"],
                        ));
                    context.read<VincularInicioBloc>().add(EditarEstadoVincularSuccess(
                          usuarioObjeto["tDocConductor"],
                          usuarioObjeto["nDocConductor"].toString().trim(),
                        ));

                    var viajeServicio = new ViajeServicio();
                    Viaje viaje = await viajeServicio.obtenerViajeVinculadoBolsaSupervisor_v4(
                      usuarioObjeto["tDocConductor"],
                      usuarioObjeto["nDocConductor"].toString().trim(),
                      usuarioObjeto["numViaje"],
                    );

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
              ),

            // if (_usuario.perfil.trim() == 'SUPERVISOR')
            //   ListTile(
            //     leading: const Icon(Icons.directions_bus_filled),
            //     title: const Text("Embarques"),
            //     onTap: () {
            //       //Navigator.pop(context);
            //       //Navigator.popAndPushNamed(context, 'listaViajes');
            //       // Navigator.of(context).pushNamedAndRemoveUntil(
            //       //     'listaViajes', (Route<dynamic> route) => false);
            //       Navigator.of(context).pushNamedAndRemoveUntil(
            //           'embarquesSupervisor', (Route<dynamic> route) => false);
            //     },
            //   ),

            if (_usuario.perfil.trim() == 'SUPERVISOR')
              ListTile(
                leading: const Icon(Icons.co_present),
                title: const Text("Manifiestos"),
                onTap: () {
                  //Navigator.pop(context);
                  //Navigator.popAndPushNamed(context, 'listaViajes');
                  // Navigator.of(context).pushNamedAndRemoveUntil(
                  //     'listaViajes', (Route<dynamic> route) => false);

                  Provider.of<ViajeProvider>(context, listen: false).limpiarLista();

                  Navigator.of(context).pushNamedAndRemoveUntil('listaViajes', (Route<dynamic> route) => false);
                },
              ),
            if (_usuario.perfil.trim() == 'SUPERVISOR')
              ListTile(
                leading: const Icon(Icons.lock_clock),
                title: const Text("Finalizar Viajes"),
                onTap: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('finalizarViajePage', (Route<dynamic> route) => false);
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Configuración"),
              onTap: () {
                //Navigator.pop(context);
                //Navigator.popAndPushNamed(context, 'listaViajes');
                Navigator.of(context).pushNamedAndRemoveUntil('configuracion', (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.redColor,
              ),
              title: const Text(
                "Cerrar Sesión",
                style: TextStyle(color: AppColors.redColor),
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
                          String fechaCierraSesion = DateFormat.yMd().add_Hms().format(new DateTime.now());

                          UsuarioServicio usuarioServicio = new UsuarioServicio();
                          final SharedPreferences prefs = await SharedPreferences.getInstance();
                          String rpta = await usuarioServicio.cerrarSesion(_usuario.tipoDoc, _usuario.numDoc, AppData.appVersion, fechaCierraSesion);
                          if (rpta == "0") {
                            prefs.setString('CS', '');
                            //await Navigator.popAndPushNamed(context, '/');
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                          } else {
                            String datosCerrarSesion = _usuario.tipoDoc + "^" + _usuario.numDoc + "^" + fechaCierraSesion;

                            prefs.setString('CS', datosCerrarSesion);

                            //await Navigator.popAndPushNamed(context, '/');
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                          }
                        },
                        child: const Text('Sí'),
                      ),
                    ],
                  ),
                );

                //Navigator.pushNamed(context, '/');
                /*Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );*/
              },
            ),
          ],
        ),
      );

  void _modalSincronizacion(BuildContext context) async {
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    await AppDatabase.instance.eliminarTodoDeUnViaje(_usuario.viajeEmp);

    if (_hayConexion()) //si hay conexion a internet
    {
      await AppDatabase.instance.eliminarTodoDeUnViaje(_usuario.viajeEmp);

      var viajeServicio = new ViajeServicio();

      Viaje viaje;

      viaje = await viajeServicio.obtenerViajeVinculadoBolsa(_usuario);

      if (viaje.rpta == "0") {
        if (_cambioDependencia) context = _navigator.context;

        await AppDatabase.instance.insertarViaje(viaje); //Si existe el viaje lo inserta o actualiza

        Provider.of<ViajeProvider>(_navigator.context, listen: false).viajeActual(viaje: viaje);

        //PRERESERVAS
        final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;

        await Provider.of<PrereservaProvider>(context, listen: false).obtenerListadoPrereservasBD(
          viaje.nroViaje,
          usuarioProvider.tipoDoc,
          usuarioProvider.numDoc,
          viaje.subOperacionId,
        );

        List<Pasajero> listadoPrereservas = await Provider.of<PrereservaProvider>(context, listen: false).listdoPrereservas;

        await AppDatabase.instance.insertarPrereservas(listadoPrereservas);

        if (_cambioDependencia) context = _navigator.context;

        Navigator.pop(context, 'Cancel');
        //Navigator.popAndPushNamed(context, 'navigationBolsaViaje');
        Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
      } else {
        if (_cambioDependencia) context = _navigator.context;
        Navigator.pop(context, 'Cancel');
        _showDialogError(context, "NO SE PUDO SINCRONIZAR", viaje.mensaje!);
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;
      Navigator.pop(context);
      _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");
    }
  }

  void _modalSincronizacionDomicilio(BuildContext context) async {
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    if (_hayConexion()) //si hay conexion a internet
    {
      var viajeServicio = new ViajeServicio();

      ViajeDomicilio viaje;

      viaje = await viajeServicio.obtenerViajeVinculadoDomicilio(_usuario);

      if (viaje.rpta == "0") {
        if (_cambioDependencia) context = _navigator.context;
        await Provider.of<DomicilioProvider>(_navigator.context, listen: false).actualizarViaje(viaje);

        await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();

        Navigator.pop(context, 'Cancel');
        if (viaje.sentido == 'I') //Si es Ida (Subida, Recojo)
        {
          //Navigator.popAndPushNamed(context, 'navigationDomicilioRecojo');
          Navigator.of(context).pushNamedAndRemoveUntil('navigationDomicilioRecojo', (Route<dynamic> route) => false);
        }

        if (viaje.sentido == 'R') //Si es Retorno (Bajada, Reparto)
        {
          //Navigator.popAndPushNamed(context, 'navigationDomicilioReparto');
          Navigator.of(context).pushNamedAndRemoveUntil('navigationDomicilioReparto', (Route<dynamic> route) => false);
        }
      } else {
        if (_cambioDependencia) context = _navigator.context;
        Navigator.pop(context, 'Cancel');

        _showDialogError(context, "NO SE ENCONTRARON VIAJES", viaje.mensaje!);
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;
      Navigator.pop(context);
      _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");
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
                  style: TextStyle(
                    color: AppColors.mainBlueColor,
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
                            color: AppColors.blueColor,
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

  void _showDialogError(BuildContext context, String titulo, String mensaje) {
    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          Timer modalTimer = new Timer(Duration(seconds: 3), () {
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
                child: Text(
                  "Aceptar",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          );
        });
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  AwesomeDialog _mensaje(BuildContext context, String mensaje) {
    if (_cambioDependencia) context = _navigator.context;

    return AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      //customHeader: null,
      animType: AnimType.topSlide,

      autoDismiss: true,
      autoHide: Duration(seconds: 2),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Text(
            mensaje,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _obtenerDatosVinculacion(BuildContext context) async {
    var usuarioServicio = UsuarioServicio();

    DatosVinculacion vinculacion = await usuarioServicio.obtenerDatosVinculacion(_usuario.tipoDoc, _usuario.numDoc, _usuario.codOperacion);

    await Provider.of<UsuarioProvider>(context, listen: false).emparejar(
      vinculacion.viajeEmp,
      vinculacion.unidadEmp,
      vinculacion.placaEmp,
      vinculacion.fechaEmp,
      "",
    );
  }
}
