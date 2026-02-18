import 'package:embarques_tdp/src/models/control_ingreso.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_bolsa.dart';
import 'package:embarques_tdp/src/providers/controlador_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/controlador_servicio.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import 'package:audioplayers/audioplayers.dart';

class ControlIngresoPage extends StatefulWidget {
  final ValueNotifier<Position?>? posicionNotifier;
  const ControlIngresoPage({super.key, this.posicionNotifier});

  @override
  State<ControlIngresoPage> createState() => _ControlIngresoPageState();
}

class _ControlIngresoPageState extends State<ControlIngresoPage> {
  Position? _posicionActual;
  FocusNode _focusUnidad = new FocusNode();
  FocusNode _focusConductor = new FocusNode();
  FocusNode _focusFecha = new FocusNode();
  TextEditingController _fechaController = TextEditingController();
  ControladorServicio _controladorServicio = ControladorServicio();

  TextEditingController textUnidadController = TextEditingController();
  TextEditingController textConductorController = TextEditingController();
  TextEditingController textObservacionController = TextEditingController();

  DocumentosValidar documentConductor = DocumentosValidar();
  DocumentosValidar documentUnidad = DocumentosValidar();
  ControlIngreso controlSalida = ControlIngreso();

  final player = AudioPlayer();
  @override
  void initState() {
    widget.posicionNotifier?.addListener(() {
      setState(() {
        _posicionActual = widget.posicionNotifier!.value;
        print(_posicionActual);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.posicionNotifier?.removeListener(() {});
    super.dispose();
  }

  Future<ControlIngreso> ValidarIngreso() async {
    if (await Permission.location.request().isGranted) {}
    Position cordenadas;
    String latitud;
    String longitud;
    try {
      cordenadas = _posicionActual!;
      latitud = "${cordenadas.latitude}";
      longitud = "${cordenadas.longitude}";
    } catch (e) {
      latitud = "0,0";
      longitud = "0,0";
    }

    controlSalida = await _controladorServicio.QRControlIngreso(
      idAndroid: Provider.of<UsuarioProvider>(context, listen: false).idDispositivo,
      conductorQR: textConductorController.text.trim(),
      unidadQR: textUnidadController.text.trim(),
      fecha: _fechaController.text.trim(),
      codOperacion: Provider.of<UsuarioProvider>(context, listen: false).usuario.codOperacion,
      tipoDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc,
      usuario: Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc,
      latitud: latitud,
      longitud: longitud,
    );

    return controlSalida;
  }

  Future<String> ConfirmarValidarSalida(int habilitarSalida) async {
    String rpta = await _controladorServicio.QRConfirmarControlIngreso(
      idAndroid: Provider.of<UsuarioProvider>(context, listen: false).idDispositivo,
      Observacion: textObservacionController.text,
      idControl: controlSalida.idControl.toString(),
      salidaHabilitada: habilitarSalida.toString(),
    );
    return rpta;
  }

  bool enProceso = false;
  bool errorUnidad = false;
  bool errorConductor = false;

  @override
  Widget build(BuildContext context) {
    _fechaController = TextEditingController(text: DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now()));

    return WillPopScope(
      onWillPop: () => Future(() => true),
      child: Scaffold(
        appBar: AppBar(
          // title: Text(
          //   "Control Ingreso",
          //   style: TextStyle(
          //     color: AppColors.mainBlueColor,
          //   ),
          // ),
          centerTitle: true,
          backgroundColor: Color.fromARGB(0, 245, 245, 245),
          elevation: 0,
          // leading: validarSalida == 1
          //     ? IconButton(
          //         onPressed: () {
          //           Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          //         },
          //         icon: Icon(
          //           Icons.arrow_back_ios_new,
          //           color: Colors.white,
          //         ),
          //       )
          //     : null,
          actions: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'controlIngresoLista');
                },
                icon: Icon(
                  Icons.list_alt_sharp,
                  color: AppColors.mainBlueColor,
                  size: 47,
                ),
              ),
            )
          ],
        ),
        body: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.79,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            margin: EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Text(
                    "UNIDAD",
                    style: TextStyle(
                      color: AppColors.mainBlueColor,
                      fontSize: 16,
                    ),
                  ),
                  inputField(
                    focus: _focusUnidad,
                    Controller: textUnidadController,
                    onEditingComplete: () {
                      _focusConductor.requestFocus();
                    },
                    onPressed: () async {
                      var res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanQRPage(),
                        ),
                      );

                      ///_showDialogCargando(context, "cargando");
                      if (res != '-1') {
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    onChanged: (value) {
                      setState(() {
                        errorUnidad = false;
                      });
                    },
                    errorText: errorUnidad ? "La unidad es obligatorio" : null,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "CONDUCTOR",
                    style: TextStyle(
                      color: AppColors.mainBlueColor,
                      fontSize: 16,
                    ),
                  ),
                  inputField(
                    focus: _focusConductor,
                    Controller: textConductorController,
                    onEditingComplete: () {
                      if (enProceso) {
                        return;
                      } else {
                        setState(() {
                          enProceso = true;
                        });
                        validar();
                      }
                    },
                    onPressed: () async {
                      var res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanQRPage(),
                        ),
                      );
                      //  _showDialogCargando(context, "cargando");
                      if (res != '-1') {
                        textConductorController.text = res;
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    onChanged: (value) {
                      setState(() {
                        errorConductor = false;
                      });
                    },
                    errorText: errorConductor ? "El conductor es obligatorio" : null,
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: Container(
          height: 60,
          padding: EdgeInsets.all(0),
          width: MediaQuery.of(context).size.width,
          child: Row(
            children: [
              Expanded(
                child: MaterialButton(
                  elevation: 0.8,
                  onPressed: () async {
                    if (enProceso) {
                      return;
                    } else {
                      setState(() {
                        enProceso = true;
                      });
                      validar();
                    }
                  },
                  height: double.infinity,
                  color: AppColors.whiteColor,
                  child: Text(
                    "Verificar",
                    style: TextStyle(
                      color: AppColors.mainBlueColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  validar() async {
    if (textUnidadController.text == "") {
      setState(() {
        errorUnidad = true;
        enProceso = false;
      });
      return;
    }

    if (textConductorController.text == "") {
      setState(() {
        errorConductor = true;
        enProceso = false;
      });
      return;
    }

    _showDialogCargando(context, "Validando...");
    final validacion = await ValidarIngreso();
    Navigator.pop(context);

    if (validacion.rpta == "0") {
      setState(() {
        enProceso = false;
        textConductorController.text = "";
        textUnidadController.text = "";
      });
      _focusUnidad.requestFocus();

      _showDialogCargando(context, "Autorizando...");
      String rpta = await ConfirmarValidarSalida(1);
      Navigator.pop(context);

      if (rpta == "0") {
        _showDialogSuccess(
          context: context,
          mensaje: "${validacion.mensaje}",
          textoboton: "Aceptar",
          titulo: "Correcto",
        );
      } else {
        _showDialogError(
          confirmacion: false,
          context: context,
          mensaje: "Fallo la autorización del ingreso de la unidad",
          textoboton: "Aceptar",
          titulo: "Lo sentimos",
        );
      }
      //
    } else if (validacion.rpta == "3") {
      setState(() {
        enProceso = false;
        textConductorController.text = "";
        textUnidadController.text = "";
      });
      _focusUnidad.requestFocus();

      _showDialogCargando(context, "Autorizando...");
      String rpta = await ConfirmarValidarSalida(1);
      Navigator.pop(context);

      if (rpta == "0") {
        _showDialogErrorCONFIRMAR(
          confirmacion: true,
          context: context,
          titulo: "Correcto",
          mensaje: "${validacion.mensaje}",
          textoboton: "",
        );
      } else {
        _showDialogError(
          confirmacion: false,
          context: context,
          mensaje: "Fallo la autorización del ingreso de la unidad",
          textoboton: "Aceptar",
          titulo: "Lo sentimos",
        );
      }
      //
    } else {
      setState(() {
        enProceso = false;
        textConductorController.text = "";
        textUnidadController.text = "";
      });
      _focusUnidad.requestFocus();

      _showDialogError(
        confirmacion: false,
        context: context,
        titulo: "Lo sentimos",
        mensaje: "${validacion.mensaje}",
        textoboton: "Aceptar",
      );
    }
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

  void _showDialogError({
    required BuildContext context,
    required String mensaje,
    required String titulo,
    required String textoboton,
    required bool confirmacion,
  }) {
    player.play(AssetSource('sounds/error_sound2.mp3'));
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 15),
                    Text(
                      titulo,
                      style: TextStyle(
                        color: AppColors.mainBlueColor,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                MaterialButton(
                  minWidth: width * 0.7,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: AppColors.mainBlueColor,
                  child: Text(
                    textoboton,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );

    // Cerrar automáticamente después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDialogErrorCONFIRMAR({
    required BuildContext context,
    required String mensaje,
    required String titulo,
    required String textoboton,
    required bool confirmacion,
  }) {
    player.play(AssetSource('sounds/success_sound.mp3'));
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return WillPopScope(
          onWillPop: () => Future(() => false),
          child: AlertDialog(
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 220,
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
                        style: TextStyle(
                          color: AppColors.mainBlueColor,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mensaje,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MaterialButton(
                            elevation: 0.8,
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            height: double.infinity,
                            child: Text(
                              "Aceptar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            color: AppColors.mainBlueColor,
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

    // Cerrar automáticamente después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDialogSuccess({
    required BuildContext context,
    required String mensaje,
    required String titulo,
    required String textoboton,
  }) {
    player.play(AssetSource('sounds/success_sound.mp3'));
    showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return AlertDialog(
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('assets/icons/check_color_icon.png'),
                      width: 100,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      titulo,
                      style: TextStyle(
                        color: AppColors.mainBlueColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                MaterialButton(
                  minWidth: width * 0.7,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: AppColors.mainBlueColor,
                  child: Text(
                    textoboton,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );

    // Cerrar automáticamente después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  //-----

  // Future _showDialogSuccess(String titulo, String cuerpo) {
  //   player.play(AssetSource('sounds/success_sound.mp3'));

  //   return showDialog(
  //       barrierDismissible: false,
  //       context: context,
  //       builder: (context) {
  //         // /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
  //         //   Navigator.pop(context);
  //         // });

  //         return WillPopScope(
  //             child: AlertDialog(
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: new BorderRadius.all(
  //                   new Radius.circular(5),
  //                 ),
  //               ),
  //               title: Row(
  //                 children: [
  //                   Icon(
  //                     Icons.check_circle_rounded,
  //                     color: AppColors.greenColor,
  //                     size: 30,
  //                   ),
  //                   const SizedBox(
  //                     width: 10,
  //                   ),
  //                   Text(
  //                     titulo,
  //                     style: TextStyle(color: AppColors.greenColor, fontWeight: FontWeight.bold),
  //                   ),
  //                 ],
  //               ),
  //               content: SingleChildScrollView(
  //                 child: Container(
  //                   width: double.infinity,
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         cuerpo,
  //                         textAlign: TextAlign.start,
  //                         style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w600),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               actions: [
  //                 MaterialButton(
  //                   onPressed: () {
  //                     setState(() {
  //                       textUnidadController.text = "";
  //                       enProceso = false;
  //                     });
  //                     Navigator.pop(context);
  //                   },
  //                   child: Text("Aceptar"),
  //                 ),
  //               ],
  //             ),
  //             onWillPop: () {
  //               return Future.value(true);
  //             });
  //       });
  // }

  // Future _showDialogError(String titulo, String cuerpo) {
  //   player.play(AssetSource('sounds/error_sound2.mp3'));

  //   Color color = AppColors.redColor;

  //   return showDialog(
  //       barrierDismissible: false,
  //       context: context,
  //       builder: (context) {
  //         // /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
  //         //   Navigator.pop(context);
  //         // });

  //         return WillPopScope(
  //             child: AlertDialog(
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: new BorderRadius.all(
  //                   new Radius.circular(5),
  //                 ),
  //               ),
  //               title: Row(
  //                 children: [
  //                   Icon(
  //                     Icons.check_circle_rounded,
  //                     color: color,
  //                     size: 30,
  //                   ),
  //                   const SizedBox(
  //                     width: 10,
  //                   ),
  //                   Text(
  //                     titulo,
  //                     style: TextStyle(color: color, fontWeight: FontWeight.bold),
  //                   ),
  //                 ],
  //               ),
  //               content: SingleChildScrollView(
  //                 child: Container(
  //                   width: double.infinity,
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         cuerpo,
  //                         textAlign: TextAlign.start,
  //                         style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w600),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               actions: [
  //                 MaterialButton(
  //                   onPressed: () {
  //                     setState(() {
  //                       textUnidadController.text = "";
  //                       enProceso = false;
  //                     });
  //                     Navigator.pop(context);
  //                   },
  //                   child: Text("Aceptar"),
  //                 ),
  //               ],
  //             ),
  //             onWillPop: () {
  //               return Future.value(true);
  //             });
  //       });
  // }

  Future _showDialogAlerta(String titulo, String cuerpo) {
    player.play(AssetSource('sounds/error_sound2.mp3'));

    Color color = AppColors.amberColor;

    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          // /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
          //   Navigator.pop(context);
          // });

          return WillPopScope(
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: new BorderRadius.all(
                    new Radius.circular(5),
                  ),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: color,
                      size: 30,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      titulo,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cuerpo,
                          textAlign: TextAlign.start,
                          style: TextStyle(color: AppColors.blackColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  MaterialButton(
                    onPressed: () {
                      setState(() {
                        textUnidadController.text = "";
                        enProceso = false;
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Aceptar"),
                  ),
                ],
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  }
}

class inputField extends StatelessWidget {
  const inputField({
    super.key,
    required FocusNode focus,
    required TextEditingController Controller,
    required void Function()? onPressed,
    required void Function()? onEditingComplete,
    required void Function(String)? onChanged,
    required String? errorText,
  })  : _focus = focus,
        _odometro = Controller,
        _onEditingComplete = onEditingComplete,
        _onChanged = onChanged,
        _onPressed = onPressed,
        _errorText = errorText;

  final FocusNode _focus;
  final TextEditingController _odometro;
  final void Function()? _onPressed;
  final void Function()? _onEditingComplete;
  final void Function(String)? _onChanged;
  final String? _errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textAlign: TextAlign.start,
      focusNode: _focus,
      autofocus: true,
      controller: _odometro,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        isDense: true,
        suffixIcon: IconButton(
          onPressed: _onPressed,
          icon: Icon(
            Icons.qr_code_scanner_sharp,
            size: 25,
            color: AppColors.mainBlueColor,
          ),
        ),
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
        errorText: _errorText,
      ),
      onEditingComplete: _onEditingComplete,
      onChanged: _onChanged,
    );
  }
}
