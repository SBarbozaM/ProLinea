import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/Bloc/unidadScaner/embarques_sup_scaner_bloc.dart';
import 'package:embarques_tdp/src/Bloc/vincularInicio/vincular_inicio_bloc.dart';
import 'package:embarques_tdp/src/components/drawer.dart';
import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmbarquesSupervisorScaner extends StatefulWidget {
  const EmbarquesSupervisorScaner({super.key});

  @override
  State<EmbarquesSupervisorScaner> createState() => _EmbarquesSupervisorScanerState();
}

class _EmbarquesSupervisorScanerState extends State<EmbarquesSupervisorScaner> {
  final TextEditingController _PlacaUnidadcController = TextEditingController();
  final TextEditingController _numConductorController = TextEditingController();

  FocusNode _focusNumDoc = new FocusNode();
  FocusNode _focusUnidad = new FocusNode();

  @override
  void dispose() {
    _focusNumDoc.dispose();
    _focusUnidad.dispose();
    _PlacaUnidadcController.dispose();
    _numConductorController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ingreso();
  }

  ingreso() async {
    var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    await AppDatabase.instance.NuevoRegistroBitacora(
      context,
      "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
      "${usuarioLogin.codOperacion}",
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "Embarque ${usuarioLogin.perfil}: INGRESO A EMBARQUE ESCANER UNIDAD CONDUCTOR",
      "Exitoso",
    );
  }

  @override
  Widget build(BuildContext context) {
    final embarquesBloc = context.read<EmbarquesSupScanerBloc>();
    final vincularBloc = context.read<VincularInicioBloc>();

    return BlocListener<EmbarquesSupScanerBloc, EmbarquesSupScanerState>(
      listener: (context, state) async {
        if (state is EmbarquesSupScanerFailure) {
          Navigator.pop(context);

          var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
          //TODO:LOGGER
          await AppDatabase.instance.NuevoRegistroBitacora(context, "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}", "${usuarioLogin.codOperacion}", DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()), "Embarque ${usuarioLogin.perfil} Escaneo: Placa ${_PlacaUnidadcController.text}", "Fallido");

          _PlacaUnidadcController.text = "";

          _focusUnidad.requestFocus();
          return _mensaje(context, state.mensaje, DialogType.warning).show();
        }
        if (state is EmbarquesSupScanerSuccess) {
          Navigator.pop(context);

          var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
          //TODO:LOGGER
          await AppDatabase.instance.NuevoRegistroBitacora(
            context,
            "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
            "${usuarioLogin.codOperacion}",
            DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
            "Embarque ${usuarioLogin.perfil} Escaneo: Placa ${_PlacaUnidadcController.text}",
            "Exitoso",
          );

          _focusNumDoc.requestFocus();
        }
      },
      child: BlocListener<VincularInicioBloc, VincularInicioState>(
        listener: (context, state) async {
          if (state is VincularInicioFailure) {
            Navigator.pop(context);

            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            //TODO:LOGGER
            await AppDatabase.instance.NuevoRegistroBitacora(context, "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}", "${usuarioLogin.codOperacion}", DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()), "Embarque ${usuarioLogin.perfil} Escaneo: NCconductor ${_numConductorController.text}", "Fallido");

            _numConductorController.text = "";
            _focusNumDoc.requestFocus();
            return _mensaje(context, state.mensaje, DialogType.warning).show();
          }
          if (state is VincularInicioSuccess) {
            EmbarquesSupScanerSuccess sucessState = embarquesBloc.state as EmbarquesSupScanerSuccess;

            final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

            //TODO:LOGGER
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuario.tipoDoc}-${usuario.numDoc}",
              "${usuario.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuario.perfil} Escaneo: NCconductor ${_numConductorController.text}",
              "Exitoso",
            );

            ////Shared Preferences
            final SharedPreferences pref = await SharedPreferences.getInstance();

            var variableLocal = {
              "placa": "${_PlacaUnidadcController.text}",
              "codOperacion": "${usuario.codOperacion}",
              "numViaje": "${sucessState.numViaje}",
              "tDocConductor": "${state.tDocConducto1.toString().trim()}",
              "nDocConductor": "${state.nDocConducto1}",
            };
            await pref.setString("usuarioVinculado", jsonEncode(variableLocal));

            _SupervisorCargarViajeRemoteOLocal(context, state.tDocConducto1, state.nDocConducto1, sucessState.numViaje);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Embarques'),
            backgroundColor: AppColors.mainBlueColor,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
              ),
            ),
          ),
          body: BlocBuilder<EmbarquesSupScanerBloc, EmbarquesSupScanerState>(
            builder: (context, state) {
              return SafeArea(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.9,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          //keyboardType: TextInputType.text,
                          textAlign: TextAlign.center,
                          focusNode: _focusUnidad,
                          autofocus: true,
                          controller: _PlacaUnidadcController,
                          onEditingComplete: () {
                            if (_PlacaUnidadcController.text != '') {
                              _showDialogSincronizandoDatos(context, "cargando");
                              var usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;

                              print(_PlacaUnidadcController.text);
                              embarquesBloc.add(EscanearUnidad(_PlacaUnidadcController.text, usuarioProvider.codOperacion));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                  "Ingresé la placa de la unidad",
                                  style: TextStyle(color: AppColors.whiteColor),
                                  textAlign: TextAlign.center,
                                ),
                                duration: Duration(seconds: 2),
                                //behavior: SnackBarBehavior.floating,
                                //margin: EdgeInsets.only(bottom: 50, right: 50, left: 50),
                                backgroundColor: AppColors.redColor,
                              ));
                            }
                          },

                          decoration: InputDecoration(
                            label: Text(
                              "Placa unidad",
                              style: TextStyle(
                                color: AppColors.mainBlueColor,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 20),
                          child: BlocBuilder<EmbarquesSupScanerBloc, EmbarquesSupScanerState>(
                            builder: (context, state) {
                              if (state is EmbarquesSupScanerSuccess) {
                                return ListView.builder(
                                  itemCount: int.parse(state.numConductor),
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    return TextFormField(
                                      //keyboardType: TextInputType.text,
                                      textAlign: TextAlign.center,
                                      controller: _numConductorController,
                                      focusNode: _focusNumDoc,
                                      autofocus: true,
                                      onEditingComplete: () {
                                        if (_numConductorController.text != '') {
                                          _showDialogSincronizandoDatos(context, "cargando");
                                          var usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;

                                          final EmBloc = context.read<EmbarquesSupScanerBloc>();
                                          final stateSucces = EmBloc.state as EmbarquesSupScanerSuccess;

                                          vincularBloc.add(VincularConductor(
                                            stateSucces.numViaje.toString(),
                                            _numConductorController.text,
                                            usuarioProvider.tipoDoc,
                                            usuarioProvider.numDoc,
                                            usuarioProvider.codOperacion,
                                          ));
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: Text(
                                              "Ingresé el dni del conductor",
                                              style: TextStyle(color: AppColors.whiteColor),
                                              textAlign: TextAlign.center,
                                            ),
                                            duration: Duration(seconds: 2),
                                            //behavior: SnackBarBehavior.floating,
                                            //margin: EdgeInsets.only(bottom: 50, right: 50, left: 50),
                                            backgroundColor: AppColors.redColor,
                                          ));
                                        }
                                      },
                                      decoration: InputDecoration(
                                        label: Text(
                                          "Numero Documento",
                                          style: TextStyle(
                                            color: AppColors.mainBlueColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              return Container();
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
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

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  void _SupervisorCargarViajeRemoteOLocal(BuildContext context, String tdocConductor, String nDocConductor, String nroViaje) async {
    if (_hayConexion()) //si hay conexion a internet
    {
      // await SincronizarViajeBolsa();
      var viajeServicio = new ViajeServicio();
      final viaje = await viajeServicio.obtenerViajeVinculadoBolsaSupervisor_v4(tdocConductor, nDocConductor, nroViaje);

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

        var servicio = new PasajeroServicio();
        final listadoPrereservas = await servicio.obtener_prereservas(viaje.nroViaje, tdocConductor, nDocConductor, viaje.subOperacionId);

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
            Viaje viaje = await ActualizarViajeEmbarqueBolsaBDLocal(listaViajesBolsa[i]);

            if (viaje.nroViaje == nroViaje) {
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

        String NdocUsua = Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc;

        await AppDatabase.instance.Update(
          table: "usuario",
          value: {
            "vinculacionActiva": "1",
            "viajeEmp": '${viaje.nroViaje.trim()}',
            "unidadEmp": '${viaje.unidad.trim()}',
            "fechaEmp": '${DateFormat('d-M-y H:m').format(DateTime.now())}',
            "sesionSincronizada": '0',
          },
          where: "numDoc = '${NdocUsua.trim()}'",
        );

        Provider.of<UsuarioProvider>(context, listen: false).emparejar(
          viaje.nroViaje.trim(),
          viaje.unidad.trim(),
          '',
          DateFormat('d-M-y H:m').format(DateTime.now()),
          "1",
        );

        await Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viajeselecionado);

        Navigator.pop(context, 'Cancel');
        Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
      }
      if (viaje.rpta != "0") {
        Navigator.pop(context);
        _showDialogError(context, "Error en la consulta", "${viaje.mensaje}");
      } else {
        IngresarEmbarqueBolsaOffline(context);
      }
    } else {
      IngresarEmbarqueBolsaOffline(context);
    }
  }

  IngresarEmbarqueBolsaOffline(BuildContext context) async {
    List<Map<String, Object?>> listaViaje = await AppDatabase.instance.Listar(tabla: "viaje", where: "seleccionado = '1'");

    if (listaViaje.isNotEmpty) {
      List<Map<String, Object?>> listaViajeBolsa = [...listaViaje];

      Viaje viaje = await ActualizarViajeEmbarqueBolsaBDLocal(listaViajeBolsa[0]);

      await Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viaje);

      //Navigator.popAndPushNamed(context, 'navigationDomicilioReparto');
      Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
    } else {
      Navigator.pop(context);
      _showDialogError(context, "SIN CONEXIÓN", "Revisa tu conexión a Internet");
    }
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

  Future<Viaje> ActualizarViajeEmbarqueBolsaBDLocal(Map<String, dynamic> json) async {
    Viaje viaje;
    viaje = Viaje.fromJsonMapVinculadoLocal(json);

    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero");
    List<Pasajero> _pasajeros = listaPasajeros.map((e) => Pasajero.fromJsonMapDBLocal(e)).toList();

    List<Map<String, Object?>> listaPuntosEmbarque = await AppDatabase.instance.Listar(tabla: "punto_embarque", where: "nroViaje = '${viaje.nroViaje}'");
    List<PuntoEmbarque> _puntosEmbarque = listaPuntosEmbarque.map((e) => PuntoEmbarque.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaTripulantes = await AppDatabase.instance.Listar(tabla: "tripulante", where: "nroViaje = '${viaje.nroViaje}'");

    List<Tripulante> _tripulantes = listaTripulantes.map((e) => Tripulante.fromJsonMap(e)).toList();

    viaje.pasajeros = _pasajeros;
    viaje.puntosEmbarque = _puntosEmbarque;
    viaje.tripulantes = _tripulantes;

    return viaje;
  }

  AwesomeDialog _mensaje(BuildContext context, String mensaje, DialogType dialogType) {
    return AwesomeDialog(
      context: context,
      dialogType: dialogType,
      //customHeader: null,
      animType: AnimType.topSlide,

      autoDismiss: true,
      autoHide: Duration(seconds: 3),
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
}
