import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/pages/inicio.dart';
import 'package:embarques_tdp/src/pages/jornada/bloc/jornada/jornada_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/ayudante/ayudante_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/conductor1/conductor1_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/conductor2/conductor2_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/conductor3/conductor3_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/unidad/unidad_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/components/snackBarMensaje.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class VinculacionJornadaPage extends StatelessWidget {
  const VinculacionJornadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Viaje'),
        centerTitle: true,
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
      body: jornadaBody(),
    );
  }
}

class jornadaBody extends StatefulWidget {
  const jornadaBody({super.key});

  @override
  State<jornadaBody> createState() => _jornadaBodyState();
}

class _jornadaBodyState extends State<jornadaBody> {
  late Usuario _usuario;

  final TextEditingController _PlacaUnidadcController = TextEditingController();
  final TextEditingController _odometroController = TextEditingController();
  final TextEditingController _numConductor1Controller = TextEditingController();
  final TextEditingController _numConductor2Controller = TextEditingController();
  final TextEditingController _numConductor3Controller = TextEditingController();
  final TextEditingController _numAyudanteController = TextEditingController();

  bool enabledC1 = false;
  bool enabledC2 = false;
  bool enabledC3 = false;
  bool enabledAy = false;

  int initStateBoton = 0;

  FocusNode _focusNumCond1 = new FocusNode();
  FocusNode _focusNumCond2 = new FocusNode();
  FocusNode _focusNumCond3 = new FocusNode();
  FocusNode _focusNumConAy = new FocusNode();
  FocusNode _focusUnidad = new FocusNode();
  FocusNode _focusOdometro = new FocusNode();

  void _showDialogCargando(BuildContext context, String titulo) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return ModalCargando(titulo: titulo);
      },
    );
  }

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final unidadBloc = context.read<UnidadBloc>();
    final conductor1Bloc = context.read<Conductor1Bloc>();
    final conductor2Bloc = context.read<Conductor2Bloc>();
    final conductor3Bloc = context.read<Conductor3Bloc>();
    final ayudanteBloc = context.read<AyudanteBloc>();

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return BlocListener<JornadaBloc, JornadaState>(
      listener: (context, state) async {
        if (state.code == "500") {
          SnackBarmensaje(context, state.mensaje, AppColors.redColor);
          unidadBloc.add(ResetListTripulantes());
          setState(() {
            _PlacaUnidadcController.text = "";
            _odometroController.text = "";
            initStateBoton = 0;
          });
          Navigator.pop(context);
        }

        if (state.code == "5") {
          context.read<JornadaBloc>().add(resetJornadaActual());
          var usuarioServicio = UsuarioServicio();

          DatosVinculacion vinculacion = await usuarioServicio.obtenerDatosVinculacion(_usuario.tipoDoc, _usuario.numDoc, _usuario.codOperacion);

          Provider.of<UsuarioProvider>(context, listen: false).emparejar(vinculacion.viajeEmp, vinculacion.unidadEmp, vinculacion.placaEmp, vinculacion.fechaEmp, "");

          SnackBarmensaje(context, "Vinculación Exitosa", AppColors.greenColor);

          Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute(
                builder: (context) => InicioPage(),
              ),
              (route) => false);
        }
      },
      child: BlocListener<UnidadBloc, UnidadState>(
        listener: (context, state) async {
          if (state is UnidadFailure) {
            Navigator.pop(context);

            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;

            _PlacaUnidadcController.text = "";
            setState(() {
              initStateBoton = 0;
            });
            _focusUnidad.requestFocus();
            return _mensaje(context, state.mensaje, DialogType.error).show();
          }
          if (state is UnidadSuccess) {
            AppDatabase.instance.EliminaJornadas();
            await AppDatabase.instance.Eliminar(tabla: "pasajero_domicilio");
            await AppDatabase.instance.Eliminar(tabla: "viaje_domicilio");
            await AppDatabase.instance.Eliminar(tabla: "tripulante");
            await AppDatabase.instance.Eliminar(tabla: "parada");
            await AppDatabase.instance.Eliminar(tabla: "paradero");

            if (state.listTripulante.length >= 1)
              context.read<JornadaBloc>().add(
                    AddTripulante(
                      state.numViaje.trim(),
                      state.listTripulante[0].tipoDoc.trim(),
                      state.listTripulante[0].numDoc.trim(),
                      state.listTripulante[0].nombres.trim(),
                    ),
                  );
            if (state.listTripulante.length >= 2)
              context.read<JornadaBloc>().add(
                    AddTripulante(
                      state.numViaje.trim(),
                      state.listTripulante[1].tipoDoc.trim(),
                      state.listTripulante[1].numDoc.trim(),
                      state.listTripulante[1].nombres.trim(),
                    ),
                  );
            if (state.listTripulante.length >= 3)
              context.read<JornadaBloc>().add(
                    AddTripulante(
                      state.numViaje.trim(),
                      state.listTripulante[2].tipoDoc.trim(),
                      state.listTripulante[2].numDoc.trim(),
                      state.listTripulante[2].nombres.trim(),
                    ),
                  );
            if (state.listTripulante.length >= 4)
              context.read<JornadaBloc>().add(
                    AddTripulante(
                      state.numViaje.trim(),
                      state.listTripulante[3].tipoDoc.trim(),
                      state.listTripulante[3].numDoc.trim(),
                      state.listTripulante[3].nombres.trim(),
                    ),
                  );

            Navigator.pop(context);
            _focusOdometro.requestFocus();
          }
        },
        child: BlocListener<Conductor1Bloc, Conductor1State>(
          listener: (context, state) async {
            if (state is Conductor1Failure) {
              Navigator.pop(context);
              // setState(() {
              //   enabledC2 = false;
              // });
              _numConductor1Controller.text = "";
              _focusNumCond1.requestFocus();
              return _mensaje(context, state.mensaje, DialogType.warning).show();
            }
            if (state is Conductor1Success) {
              Navigator.pop(context);
              UnidadSuccess sucessState = unidadBloc.state as UnidadSuccess;

              context.read<JornadaBloc>().add(
                    AddTripulante(
                      sucessState.numViaje,
                      state.tDocConducto1,
                      state.nDocConducto1,
                      state.nombreConductor1,
                    ),
                  );

              if (sucessState.numConductor == "1") {
                ////Shared Preferences
                final SharedPreferences pref = await SharedPreferences.getInstance();

                Provider.of<UsuarioProvider>(context, listen: false).emparejar(sucessState.numViaje, sucessState.codUnidad, sucessState.placa, state.fechaEmp, "");

                Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
              } else {
                // _focusNumCond2.requestFocus();
              }
            }
          },
          child: BlocListener<Conductor2Bloc, Conductor2State>(
            listener: (context, state) async {
              if (state is Conductor2Failure) {
                Navigator.pop(context);
                // setState(() {
                //   enabledC3 = false;
                // });
                _numConductor2Controller.text = "";
                _focusNumCond2.requestFocus();
                return _mensaje(context, state.mensaje, DialogType.warning).show();
              }
              if (state is Conductor2Success) {
                Navigator.pop(context);
                UnidadSuccess sucessState = unidadBloc.state as UnidadSuccess;

                context.read<JornadaBloc>().add(
                      AddTripulante(
                        sucessState.numViaje,
                        state.tDocConducto2,
                        state.nDocConducto2,
                        state.nombreConductor2,
                      ),
                    );

                if (sucessState.numConductor == "2") {
                  ////Shared Preferences
                  final SharedPreferences pref = await SharedPreferences.getInstance();

                  Provider.of<UsuarioProvider>(context, listen: false).emparejar(sucessState.numViaje, sucessState.codUnidad, sucessState.placa, state.fechaEmp, "");

                  Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
                } else {
                  // _focusNumCond3.requestFocus();
                }
              }
            },
            child: BlocListener<Conductor3Bloc, Conductor3State>(
              listener: (context, state) async {
                if (state is Conductor3Failure) {
                  Navigator.pop(context);
                  // setState(() {
                  //   enabledAy = false;
                  // });

                  _numConductor3Controller.text = "";
                  _focusNumCond3.requestFocus();
                  return _mensaje(context, state.mensaje, DialogType.warning).show();
                }
                if (state is Conductor3Success) {
                  Navigator.pop(context);
                  UnidadSuccess sucessState = unidadBloc.state as UnidadSuccess;

                  context.read<JornadaBloc>().add(
                        AddTripulante(
                          sucessState.numViaje,
                          state.tDocConducto3,
                          state.nDocConducto3,
                          state.nombreConductor3,
                        ),
                      );

                  if (sucessState.numConductor == "3") {
                    ////Shared Preferences
                    final SharedPreferences pref = await SharedPreferences.getInstance();

                    Provider.of<UsuarioProvider>(context, listen: false).emparejar(sucessState.numViaje, sucessState.codUnidad, sucessState.placa, state.fechaEmp, "");

                    Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
                  } else {
                    // _focusNumConAy.requestFocus();
                  }
                }
              },
              child: BlocListener<AyudanteBloc, AyudanteState>(
                listener: (context, state) async {
                  if (state is AyudanteFailure) {
                    Navigator.pop(context);
                    _numConductor3Controller.text = "";
                    _focusNumCond3.requestFocus();
                    return _mensaje(context, state.mensaje, DialogType.warning).show();
                  }
                  if (state is AyudanteSuccess) {
                    Navigator.pop(context);

                    UnidadSuccess sucessState = unidadBloc.state as UnidadSuccess;

                    context.read<JornadaBloc>().add(
                          AddTripulante(
                            sucessState.numViaje,
                            state.tDocAyudante,
                            state.nDocAyudante,
                            state.nombreAyudante,
                          ),
                        );

                    if (sucessState.numConductor == "4") {
                      ////Shared Preferences
                      final SharedPreferences pref = await SharedPreferences.getInstance();

                      Provider.of<UsuarioProvider>(context, listen: false).emparejar(sucessState.numViaje, sucessState.codUnidad, sucessState.placa, state.fechaEmp, "");

                      Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
                    }
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 15),
                        TextFormField(
                          textAlign: TextAlign.center,
                          focusNode: _focusUnidad,
                          autofocus: true,
                          controller: _PlacaUnidadcController,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            hintText: "Ingrese la placa de la unidad",
                            label: Text(
                              "Placa unidad",
                              style: TextStyle(
                                color: AppColors.mainBlueColor,
                                fontSize: 22,
                              ),
                            ),
                            suffix: IconButton(
                              icon: Icon(Icons.qr_code_scanner_rounded),
                              onPressed: () async {
                                _PlacaUnidadcController.text = "";

                                var res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ScanQRPage(),
                                  ),
                                );

                                _showDialogCargando(context, "cargando");

                                setState(() {
                                  initStateBoton = 1;
                                });

                                if (res != '-1') {
                                  _PlacaUnidadcController.text = res;
                                  var usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;
                                  unidadBloc.add(
                                    EscanearUnidadJornada(res, usuarioProvider.codOperacion, _usuario.numDoc),
                                  );
                                } else {
                                  unidadBloc.add(ResetListTripulantes());

                                  setState(() {
                                    initStateBoton = 0;
                                  });
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                          onEditingComplete: () {
                            if ((_PlacaUnidadcController.text).trim() == "") {
                              SnackBarmensaje(context, "Ingresé la placa de la unidad", AppColors.redColor);
                              return;
                            }
                            _showDialogCargando(context, "cargando");

                            if (_PlacaUnidadcController.text.trim().contains('.') || _PlacaUnidadcController.text.trim().contains(',') || _PlacaUnidadcController.text.trim().contains('+')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                new SnackBar(
                                  content: Text(
                                    "La unidad no debe contener comas(;), puntos(.) o cualquier otro caracter especial.",
                                    style: TextStyle(color: AppColors.whiteColor),
                                  ),
                                  backgroundColor: AppColors.redColor,
                                ),
                              );
                              Navigator.pop(context, 'Cancel');

                              return;
                            }

                            setState(() {
                              initStateBoton = 1;
                            });

                            var usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;
                            unidadBloc.add(
                              EscanearUnidadJornada(_PlacaUnidadcController.text, usuarioProvider.codOperacion, _usuario.numDoc),
                            );
                          },
                          onChanged: (value) {
                            unidadBloc.add(ResetListTripulantes());

                            setState(() {
                              initStateBoton = 0;
                              _odometroController.text = "";
                            });
                          },
                        ),
                        SizedBox(height: 15),
                        BlocBuilder<UnidadBloc, UnidadState>(
                          builder: (context, state) {
                            if (state is UnidadSuccess) {
                              final unidadState = state as UnidadSuccess;
                              return BlocBuilder<Conductor1Bloc, Conductor1State>(
                                builder: (context, state) {
                                  return Container(
                                    child: Column(
                                      children: [
                                        if (unidadState.listTripulante.length >= 1) SizedBox(height: 10),
                                        if (unidadState.listTripulante.length >= 1)
                                          inputNDocConductor(
                                            hintText: "Ingrese su numero de DNI",
                                            enabled: enabledC1,
                                            label: "${unidadState.listTripulante[0].nombres}",
                                            numConductorController: _numConductor1Controller,
                                            focusNumCond: _focusNumCond1,
                                            onEditingComplete: () {
                                              // if ((_numConductor1Controller.text)
                                              //         .trim() ==
                                              //     "") {
                                              //   SnackBarmensaje(
                                              //       context,
                                              //       "Ingresé el dni del conductor",
                                              //       AppColors.redColor);
                                              //   return;
                                              // }

                                              // setState(() {
                                              //   enabledC2 = true;
                                              // });

                                              // _showDialogCargando(
                                              //     context, "cargando");

                                              // // var usuarioProvider = Provider.of<UsuarioProvider>(context,listen: false).usuario;

                                              // final UniBloc =
                                              //     context.read<UnidadBloc>();
                                              // final stateSucces =
                                              //     UniBloc.state as UnidadSuccess;

                                              // conductor1Bloc
                                              //     .add(VincularConductor1(
                                              //   stateSucces.numViaje.toString(),
                                              //   _numConductor1Controller.text,
                                              //   '1',
                                              //   _usuario.tipoDoc,
                                              //   _usuario.numDoc,
                                              //   _usuario.codOperacion,
                                              // ));
                                            },
                                            onPressed: () async {
                                              // _numConductor1Controller.text = "";

                                              // final UniBloc =
                                              //     context.read<UnidadBloc>();
                                              // final stateSucces =
                                              //     UniBloc.state as UnidadSuccess;

                                              // var res = await Navigator.push(
                                              //   context,
                                              //   MaterialPageRoute(
                                              //     builder: (context) =>
                                              //         const ScanQRPage(),
                                              //   ),
                                              // );

                                              // setState(() {
                                              //   enabledC2 = true;
                                              // });

                                              // _showDialogCargando(
                                              //     context, "cargando");
                                              // if (res != '-1') {
                                              //   _numConductor1Controller.text =
                                              //       res;
                                              //   conductor1Bloc
                                              //       .add(VincularConductor1(
                                              //     stateSucces.numViaje.toString(),
                                              //     _numConductor1Controller.text,
                                              //     '1',
                                              //     _usuario.tipoDoc,
                                              //     _usuario.numDoc,
                                              //     _usuario.codOperacion,
                                              //   ));
                                              // } else {
                                              //   Navigator.pop(context);
                                              // }
                                            },
                                          ),
                                        if (unidadState.listTripulante.length >= 2) SizedBox(height: 20),
                                        if (unidadState.listTripulante.length >= 2)
                                          BlocBuilder<Conductor2Bloc, Conductor2State>(
                                            builder: (context, state) {
                                              return inputNDocConductor(
                                                hintText: "Ingrese su numero de DNI",
                                                enabled: enabledC2,
                                                label: "${unidadState.listTripulante[1].nombres}",
                                                numConductorController: _numConductor2Controller,
                                                focusNumCond: _focusNumCond2,
                                                onEditingComplete: () {
                                                  // if ((_numConductor2Controller
                                                  //             .text)
                                                  //         .trim() ==
                                                  //     "") {
                                                  //   SnackBarmensaje(
                                                  //       context,
                                                  //       "Ingresé el dni del conductor",
                                                  //       AppColors.redColor);
                                                  //   return;
                                                  // }

                                                  // setState(() {
                                                  //   enabledC3 = true;
                                                  // });

                                                  // _showDialogCargando(
                                                  //     context, "cargando");

                                                  // final UniBloc =
                                                  //     context.read<UnidadBloc>();
                                                  // final stateSucces = UniBloc
                                                  //     .state as UnidadSuccess;

                                                  // conductor2Bloc
                                                  //     .add(VincularConductor2(
                                                  //   stateSucces.numViaje
                                                  //       .toString(),
                                                  //   _numConductor2Controller.text,
                                                  //   '2',
                                                  //   _usuario.tipoDoc,
                                                  //   _usuario.numDoc,
                                                  //   _usuario.codOperacion,
                                                  // ));
                                                },
                                                onPressed: () async {
                                                  // _numConductor2Controller.text =
                                                  //     "";

                                                  // final UniBloc =
                                                  //     context.read<UnidadBloc>();
                                                  // final stateSucces = UniBloc
                                                  //     .state as UnidadSuccess;

                                                  // var res = await Navigator.push(
                                                  //   context,
                                                  //   MaterialPageRoute(
                                                  //     builder: (context) =>
                                                  //         const ScanQRPage(),
                                                  //   ),
                                                  // );

                                                  // setState(() {
                                                  //   enabledC3 = true;
                                                  // });

                                                  // _showDialogCargando(
                                                  //     context, "cargando");

                                                  // if (res != '-1') {
                                                  //   _numConductor2Controller
                                                  //       .text = res;
                                                  //   conductor2Bloc
                                                  //       .add(VincularConductor2(
                                                  //     stateSucces.numViaje
                                                  //         .toString(),
                                                  //     _numConductor2Controller
                                                  //         .text,
                                                  //     '2',
                                                  //     _usuario.tipoDoc,
                                                  //     _usuario.numDoc,
                                                  //     _usuario.codOperacion,
                                                  //   ));
                                                  // } else {
                                                  //   Navigator.pop(context);
                                                  // }
                                                },
                                              );
                                            },
                                          ),
                                        if (unidadState.listTripulante.length >= 3) SizedBox(height: 20),
                                        if (unidadState.listTripulante.length >= 3)
                                          BlocBuilder<Conductor3Bloc, Conductor3State>(
                                            builder: (context, state) {
                                              return inputNDocConductor(
                                                hintText: "Ingrese su numero de DNI",
                                                enabled: enabledC3,
                                                label: "${unidadState.listTripulante[2].nombres}",
                                                numConductorController: _numConductor3Controller,
                                                focusNumCond: _focusNumCond3,
                                                onEditingComplete: () {
                                                  // if ((_numConductor3Controller
                                                  //             .text)
                                                  //         .trim() ==
                                                  //     "") {
                                                  //   SnackBarmensaje(
                                                  //       context,
                                                  //       "Ingresé el dni del conductor",
                                                  //       AppColors.redColor);
                                                  //   return;
                                                  // }

                                                  // setState(() {
                                                  //   enabledAy = true;
                                                  // });

                                                  // _showDialogCargando(
                                                  //     context, "cargando");

                                                  // final UniBloc =
                                                  //     context.read<UnidadBloc>();
                                                  // final stateSucces = UniBloc
                                                  //     .state as UnidadSuccess;

                                                  // conductor3Bloc
                                                  //     .add(VincularConductor3(
                                                  //   stateSucces.numViaje
                                                  //       .toString(),
                                                  //   _numConductor3Controller.text,
                                                  //   '3',
                                                  //   _usuario.tipoDoc,
                                                  //   _usuario.numDoc,
                                                  //   _usuario.codOperacion,
                                                  // ));
                                                },
                                                onPressed: () async {
                                                  // _numConductor3Controller.text =
                                                  //     "";

                                                  // final UniBloc =
                                                  //     context.read<UnidadBloc>();
                                                  // final stateSucces = UniBloc
                                                  //     .state as UnidadSuccess;

                                                  // var res = await Navigator.push(
                                                  //   context,
                                                  //   MaterialPageRoute(
                                                  //     builder: (context) =>
                                                  //         const ScanQRPage(),
                                                  //   ),
                                                  // );

                                                  // setState(() {
                                                  //   enabledAy = true;
                                                  // });

                                                  // _showDialogCargando(
                                                  //     context, "cargando");

                                                  // if (res != '-1') {
                                                  //   conductor3Bloc
                                                  //       .add(VincularConductor3(
                                                  //     stateSucces.numViaje
                                                  //         .toString(),
                                                  //     _numConductor3Controller
                                                  //         .text,
                                                  //     '3',
                                                  //     _usuario.tipoDoc,
                                                  //     _usuario.numDoc,
                                                  //     _usuario.codOperacion,
                                                  //   ));
                                                  // } else {
                                                  //   Navigator.pop(context);
                                                  // }
                                                },
                                              );
                                            },
                                          ),
                                        if (unidadState.listTripulante.length >= 4) SizedBox(height: 20),
                                        if (unidadState.listTripulante.length >= 4)
                                          BlocBuilder<AyudanteBloc, AyudanteState>(
                                            builder: (context, state) {
                                              return inputNDocConductor(
                                                hintText: "Ingrese su numero de DNI",
                                                enabled: enabledAy,
                                                label: "${unidadState.listTripulante[3].nombres}",
                                                numConductorController: _numAyudanteController,
                                                focusNumCond: _focusNumConAy,
                                                onEditingComplete: () {
                                                  // if ((_numAyudanteController
                                                  //             .text)
                                                  //         .trim() ==
                                                  //     "") {
                                                  //   SnackBarmensaje(
                                                  //       context,
                                                  //       "Ingresé el dni del ayudante",
                                                  //       AppColors.redColor);
                                                  //   return;
                                                  // }

                                                  // _showDialogCargando(
                                                  //     context, "cargando");

                                                  // final UniBloc =
                                                  //     context.read<UnidadBloc>();
                                                  // final stateSucces = UniBloc
                                                  //     .state as UnidadSuccess;

                                                  // ayudanteBloc
                                                  //     .add(VincularAyudante(
                                                  //   stateSucces.numViaje
                                                  //       .toString(),
                                                  //   _numAyudanteController.text,
                                                  //   '4',
                                                  //   _usuario.tipoDoc,
                                                  //   _usuario.numDoc,
                                                  //   _usuario.codOperacion,
                                                  // ));
                                                },
                                                onPressed: () async {
                                                  // _numAyudanteController.text =
                                                  //     "";

                                                  // final UniBloc =
                                                  //     context.read<UnidadBloc>();
                                                  // final stateSucces = UniBloc
                                                  //     .state as UnidadSuccess;

                                                  // var res = await Navigator.push(
                                                  //   context,
                                                  //   MaterialPageRoute(
                                                  //     builder: (context) =>
                                                  //         const ScanQRPage(),
                                                  //   ),
                                                  // );
                                                  // _showDialogCargando(
                                                  //     context, "cargando");

                                                  // if (res != '-1') {
                                                  //   ayudanteBloc
                                                  //       .add(VincularAyudante(
                                                  //     stateSucces.numViaje
                                                  //         .toString(),
                                                  //     _numAyudanteController.text,
                                                  //     '4',
                                                  //     _usuario.tipoDoc,
                                                  //     _usuario.numDoc,
                                                  //     _usuario.codOperacion,
                                                  //   ));
                                                  // } else {
                                                  //   Navigator.pop(context);
                                                  // }
                                                },
                                              );
                                            },
                                          ),
                                        SizedBox(height: 15),
                                        //Odometro
                                        if (initStateBoton == 1)
                                          TextFormField(
                                            textAlign: TextAlign.center,
                                            focusNode: _focusOdometro,
                                            autofocus: true,
                                            controller: _odometroController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: "Ingrese su kilometraje  de inicio",
                                              label: Text(
                                                "Odómetro",
                                                style: TextStyle(
                                                  color: AppColors.mainBlueColor,
                                                  fontSize: 22,
                                                ),
                                              ),
                                            ),
                                            onEditingComplete: () async {
                                              _showDialogCargando(context, "cargando");
                                              if (_PlacaUnidadcController.text.trim() == "") {
                                                Navigator.pop(context);
                                                SnackBarmensaje(context, "Ingresé el la placa del vehículo", AppColors.redColor);
                                                return;
                                              }

                                              if (_odometroController.text.trim() == "") {
                                                Navigator.pop(context);
                                                SnackBarmensaje(context, "Ingresé el numero kilometraje  del vehículo", AppColors.redColor);
                                                return;
                                              }

                                              if (_odometroController.text.trim().contains('.') || _odometroController.text.trim().contains(',') || _odometroController.text.trim().contains('+')) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  new SnackBar(
                                                    content: Text(
                                                      "El odomentro no debe contener comas(;), puntos(.) o cualquier otro caracter especial.",
                                                      style: TextStyle(color: AppColors.whiteColor),
                                                    ),
                                                    backgroundColor: AppColors.redColor,
                                                  ),
                                                );
                                                Navigator.pop(context, 'Cancel');

                                                return;
                                              }

                                              UnidadSuccess _unidadSuccess = unidadBloc.state as UnidadSuccess;

                                              if (await Permission.location.request().isGranted) {}
                                              String posicionActual;
                                              try {
                                                Position posicionActualGPS = await Geolocator.getCurrentPosition();
                                                posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
                                              } catch (e) {
                                                posicionActual = "0, 0-Error no controlado";
                                              }

                                              context.read<JornadaBloc>().add(
                                                    ContinuarVinculacion(
                                                      _unidadSuccess.numViaje,
                                                      _usuario.tipoDoc,
                                                      _usuario.numDoc,
                                                      _usuario.codOperacion,
                                                      _unidadSuccess.listTripulante,
                                                      _odometroController.text.trim(),
                                                      posicionActual,
                                                    ),
                                                  );
                                              setState(() {});
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                            return Container();
                          },
                        ),
                        SizedBox(height: 20),
                        if (initStateBoton == 0)
                          BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return MaterialButton(
                                onPressed: () async {
                                  if ((_PlacaUnidadcController.text).trim() == "") {
                                    SnackBarmensaje(context, "Ingresé la placa de la unidad", AppColors.redColor);
                                    return;
                                  }
                                  _showDialogCargando(context, "cargando");

                                  if (_PlacaUnidadcController.text.trim().contains('.') || _PlacaUnidadcController.text.trim().contains(',') || _PlacaUnidadcController.text.trim().contains('+')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      new SnackBar(
                                        content: Text(
                                          "La unidad no debe contener comas(;), puntos(.) o cualquier otro caracter especial.",
                                          style: TextStyle(color: AppColors.whiteColor),
                                        ),
                                        backgroundColor: AppColors.redColor,
                                      ),
                                    );
                                    Navigator.pop(context, 'Cancel');

                                    return;
                                  }

                                  setState(() {
                                    initStateBoton = 1;
                                  });

                                  var usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;
                                  unidadBloc.add(
                                    EscanearUnidadJornada(_PlacaUnidadcController.text, usuarioProvider.codOperacion, _usuario.numDoc),
                                  );
                                },
                                minWidth: width * 0.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: AppColors.mainBlueColor,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                textColor: AppColors.whiteColor,
                                child: Text("Validar Unidad"),
                              );
                            },
                          ),
                        if (initStateBoton == 1)
                          BlocBuilder<JornadaBloc, JornadaState>(
                            builder: (context, state) {
                              return MaterialButton(
                                onPressed: () async {
                                  _showDialogCargando(context, "cargando");
                                  if (_PlacaUnidadcController.text.trim() == "") {
                                    Navigator.pop(context);
                                    SnackBarmensaje(context, "Ingresé el la placa del vehículo", AppColors.redColor);
                                    return;
                                  }

                                  if (_odometroController.text.trim() == "") {
                                    Navigator.pop(context);
                                    SnackBarmensaje(context, "Ingresé el numero odómentro del vehículo", AppColors.redColor);
                                    return;
                                  }

                                  if (_odometroController.text.trim().contains('.') || _odometroController.text.trim().contains(',') || _odometroController.text.trim().contains('+')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      new SnackBar(
                                        content: Text(
                                          "El odomentro no debe contener comas(;), puntos(.) o cualquier otro caracter especial.",
                                          style: TextStyle(color: AppColors.whiteColor),
                                        ),
                                        backgroundColor: AppColors.redColor,
                                      ),
                                    );
                                    Navigator.pop(context, 'Cancel');

                                    return;
                                  }

                                  UnidadSuccess _unidadSuccess = unidadBloc.state as UnidadSuccess;
                                  if (await Permission.location.request().isGranted) {}
                                  String posicionActual;
                                  try {
                                    Position posicionActualGPS = await Geolocator.getCurrentPosition();
                                    posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
                                  } catch (e) {
                                    posicionActual = "0, 0-Error no controlado";
                                  }

                                  context.read<JornadaBloc>().add(
                                        ContinuarVinculacion(
                                          _unidadSuccess.numViaje,
                                          _usuario.tipoDoc,
                                          _usuario.numDoc,
                                          _usuario.codOperacion,
                                          _unidadSuccess.listTripulante,
                                          _odometroController.text.trim(),
                                          posicionActual,
                                        ),
                                      );
                                  setState(() {});
                                },
                                minWidth: width * 0.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: AppColors.mainBlueColor,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                textColor: AppColors.whiteColor,
                                child: Text("Continuar"),
                              );
                            },
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModalCargando extends StatelessWidget {
  const ModalCargando({
    super.key,
    required String titulo,
  }) : _titulo = titulo;

  final String _titulo;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: AlertDialog(
          title: Text(
            _titulo,
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
  }
}

class inputNDocConductor extends StatelessWidget {
  const inputNDocConductor({
    super.key,
    required TextEditingController numConductorController,
    required FocusNode focusNumCond,
    required Function() onEditingComplete,
    required Function() onPressed,
    required String label,
    required String hintText,
    required bool enabled,
  })  : _numConductorController = numConductorController,
        _focusNumCond = focusNumCond,
        _onEditingComplete = onEditingComplete,
        _onPressed = onPressed,
        _label = label,
        _hintText = hintText,
        _enabled = enabled;

  final TextEditingController _numConductorController;
  final FocusNode _focusNumCond;
  final Function()? _onEditingComplete;
  final void Function()? _onPressed;
  final String _label;
  final String _hintText;
  final bool _enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        enabled: _enabled,
        textAlign: TextAlign.center,
        controller: _numConductorController,
        focusNode: _focusNumCond,
        autofocus: true,
        decoration: InputDecoration(
            isCollapsed: true,
            hintText: _hintText,
            label: Text(
              _label,
              style: TextStyle(
                color: AppColors.mainBlueColor,
                fontSize: 22,
              ),
            ),
            suffix: IconButton(
              icon: Icon(Icons.qr_code_scanner_rounded),
              onPressed: _onPressed,
            )),
        onEditingComplete: _onEditingComplete);
  }
}
