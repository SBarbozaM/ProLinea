import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/jornada.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/pages/inicio.dart';
import 'package:embarques_tdp/src/pages/jornada/bloc/jornada/jornada_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/unidad/unidad_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/components/snackBarMensaje.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_jornadaPage.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class JornadaPage extends StatefulWidget {
  const JornadaPage({super.key});

  @override
  State<JornadaPage> createState() => _JornadaPageState();
}

class _JornadaPageState extends State<JornadaPage> {
  // Barcode? result;
  // QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final TextEditingController _numConductorController = TextEditingController();
  FocusNode _focusNumCond = new FocusNode();

  String nombreConductor = "";
  FocusNode _focusUnidad = new FocusNode();
  final TextEditingController _PlacaUnidadcController = TextEditingController();

  int initStateBoton = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _numConductorController.dispose();
    _focusNumCond.dispose();
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

  tituloAppBar() async {
    final AppDatabase _appDatabase = AppDatabase();
    final listaJornada = await _appDatabase.ListarJornada(Provider.of<ViajeProvider>(context, listen: false).viaje.nroViaje);

    nombreConductor = _numConductorController.text.trim();

    for (var element in listaJornada) {
      if (element.viajDni.trim() == _numConductorController.text.trim()) {
        setState(() {
          nombreConductor = element.viajNombre;
        });
      }
    }
  }

  AwesomeDialog _showDialogJornada(BuildContext context) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      //customHeader: null,
      animType: AnimType.topSlide,
      //showCloseIcon: true,
      title: '¿${nombreConductor} estas seguro de iniciar tu jornada?',
      desc: "",
      reverseBtnOrder: true,
      buttonsTextStyle: TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        if ((_numConductorController.text).trim() == "") {
          SnackBarmensaje(context, "Ingresé el dni del conductor", AppColors.redColor);
          return;
        }
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
                _numConductorController.text.toString(),
                usuario.viajeEmp,
                "${latitud},${longitud}",
                usuario.numDoc,
              ),
            );
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JornadaBloc, JornadaState>(
      listener: (context, state) {
        if (state.code == "1") {
          ScaffoldMessenger.of(context).showSnackBar(
            new SnackBar(
              content: Text(
                state.mensaje,
                style: TextStyle(color: AppColors.whiteColor),
              ),
              backgroundColor: AppColors.redColor,
            ),
          );
          setState(() {
            _numConductorController.text = "";
          });
          Navigator.pop(context);
          // Navigator.pop(context);
        }

        if (state.code == "2") {
          ScaffoldMessenger.of(context).showSnackBar(
            new SnackBar(
              content: Text(
                state.mensaje,
                style: TextStyle(color: AppColors.whiteColor),
              ),
              backgroundColor: AppColors.greenColor,
            ),
          );
          Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute(
                builder: (context) => InicioPage(),
              ),
              (route) => false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text("Iniciar Jornada"),
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
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              children: [
                SizedBox(height: 15),
                // TextFormField(
                //   textAlign: TextAlign.center,
                //   focusNode: _focusUnidad,
                //   autofocus: true,
                //   controller: _PlacaUnidadcController,
                //   decoration: InputDecoration(
                //       isCollapsed: true,
                //       hintText: "Ingrese la placa de la unidad",
                //       label: Text(
                //         "Placa unidad",
                //         style: TextStyle(
                //           color: AppColors.mainBlueColor,
                //         ),
                //       ),
                //       suffix: IconButton(
                //         icon: Icon(Icons.qr_code_scanner_rounded),
                //         onPressed: () async {
                //           _PlacaUnidadcController.text = "";
                //
                //           var res = await Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) =>
                //                   const ScanQRPage(),
                //             ),
                //           );
                //
                //           _showDialogCargando(context, "cargando");
                //
                //           if (res != '-1') {
                //             _PlacaUnidadcController.text = res;
                //             UnidadState unidadState =
                //                 context.read<UnidadBloc>().state;
                //             if (unidadState is UnidadSuccess) {
                //               final stateUnidad = unidadState as UnidadSuccess;
                //
                //               if (stateUnidad.placa.trim() !=
                //                   res.toString().trim()) {
                //                 Navigator.pop(context);
                //                 return SnackBarmensaje(
                //                     context,
                //                     "La unidad ingresada no coincide con la de vinculación",
                //                     AppColors.redColor);
                //               }
                //               if (stateUnidad.placa.trim() ==
                //                   res.toString().trim()) {
                //                 Navigator.pop(context);
                //                 setState(() {
                //                   initStateBoton = 1;
                //                   _focusNumCond.requestFocus();
                //                 });
                //               }
                //             }
                //           } else {
                //             Navigator.pop(context);
                //           }
                //         },
                //       )),
                //   onEditingComplete: () {
                //     if ((_PlacaUnidadcController.text).trim() == "") {
                //       SnackBarmensaje(context, "Ingresé la placa de la unidad",
                //           AppColors.redColor);
                //       return;
                //     }
                //     _showDialogCargando(context, "cargando");
                //
                //     UnidadState unidadState = context.read<UnidadBloc>().state;
                //     if (unidadState is UnidadSuccess) {
                //       final stateUnidad = unidadState as UnidadSuccess;
                //
                //       if (stateUnidad.placa.trim() !=
                //           _PlacaUnidadcController.text.toString().trim()) {
                //         Navigator.pop(context);
                //         return SnackBarmensaje(
                //             context,
                //             "La unidad ingresada no coincide con la de vinculación",
                //             AppColors.redColor);
                //       }
                //
                //       if (stateUnidad.placa.trim() ==
                //           _PlacaUnidadcController.text.toString().trim()) {
                //         Navigator.pop(context);
                //         setState(() {
                //           _focusNumCond.requestFocus();
                //           initStateBoton = 1;
                //         });
                //       }
                //     }
                //   },
                // ),
                // SizedBox(height: 15),
                // if (initStateBoton == 1)
                _inputConductor(
                  hintText: "Ingrese su dni",
                  enabled: true,
                  label: "Numero Documento",
                  numConductorController: _numConductorController,
                  focusNumCond: _focusNumCond,
                  onEditingComplete: () async {
                    if (await Permission.location.request().isGranted) {}
                    if ((_numConductorController.text).trim() == "") {
                      SnackBarmensaje(context, "Ingresé el dni del conductor", AppColors.redColor);
                      return;
                    }
                    await tituloAppBar();

                    _showDialogJornada(context).show();
                  },
                  onPressed: () async {
                    if (await Permission.location.request().isGranted) {}
                    _showDialogCargando(context, "cargando");
                    _numConductorController.text = "";

                    Navigator.pop(context);

                    var res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanQRPage(),
                        ));
                    if (res != '-1') {
                      _numConductorController.text = res;
                      await tituloAppBar();
                      _showDialogJornada(context).show();
                    } else {
                      _numConductorController.text = "";
                    }
                  },
                ),
                SizedBox(height: 20),
                // if (initStateBoton == 0)
                //   MaterialButton(
                //     onPressed: () {
                //       if ((_PlacaUnidadcController.text).trim() == "") {
                //         SnackBarmensaje(
                //             context,
                //             "Ingresé la placa de la unidad",
                //             AppColors.redColor);
                //         return;
                //       }
                //       _showDialogCargando(context, "cargando");
                //
                //       UnidadState unidadState =
                //           context.read<UnidadBloc>().state;
                //       if (unidadState is UnidadSuccess) {
                //         final stateUnidad = unidadState as UnidadSuccess;
                //
                //         if (stateUnidad.placa.trim() !=
                //             _PlacaUnidadcController.text.toString().trim()) {
                //           Navigator.pop(context);
                //           return SnackBarmensaje(
                //               context,
                //               "La unidad ingresada no coincide con la de vinculación",
                //               AppColors.redColor);
                //         }
                //
                //         if (stateUnidad.placa.trim() ==
                //             _PlacaUnidadcController.text.toString().trim()) {
                //           Navigator.pop(context);
                //           setState(() {
                //             initStateBoton = 1;
                //             _focusNumCond.requestFocus();
                //           });
                //         }
                //       }
                //     },
                //     minWidth: MediaQuery.of(context).size.width * 0.5,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     color: AppColors.mainBlueColor,
                //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                //     textColor: AppColors.whiteColor,
                //     child: Text("Validar Unidad"),
                //   ),
                // if (initStateBoton == 1)
                MaterialButton(
                  onPressed: () async {
                    if (await Permission.location.request().isGranted) {}
                    if ((_numConductorController.text).trim() == "") {
                      SnackBarmensaje(context, "Ingresé el dni del conductor", AppColors.redColor);
                      return;
                    }
                    await tituloAppBar();
                    _showDialogJornada(context).show();
                  },
                  minWidth: MediaQuery.of(context).size.width * 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: AppColors.mainBlueColor,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textColor: AppColors.whiteColor,
                  child: Text("Continuar"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _inputConductor extends StatelessWidget {
  const _inputConductor({
    super.key,
    required TextEditingController numConductorController,
    required FocusNode focusNumCond,
    required Function() onEditingComplete,
    required Function() onPressed,
    required String label,
    required bool enabled,
    String? hintText,
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
  final bool _enabled;
  final String? _hintText;

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
            label: Text(
              _label,
              style: TextStyle(
                color: AppColors.mainBlueColor,
              ),
            ),
            hintText: _hintText,
            suffix: IconButton(
              icon: Icon(Icons.qr_code_scanner_rounded),
              onPressed: _onPressed,
            )),
        onEditingComplete: _onEditingComplete);
  }
}
