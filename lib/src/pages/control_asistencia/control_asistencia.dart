import 'dart:async';

import 'package:embarques_tdp/src/models/control_asistencia.dart';
import 'package:embarques_tdp/src/models/control_salida.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_bolsa.dart';
import 'package:embarques_tdp/src/providers/controlador_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/controlador_servicio.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class ControlAsistenciaPage extends StatefulWidget {
  const ControlAsistenciaPage({super.key});

  @override
  State<ControlAsistenciaPage> createState() => _ControlAsistenciaPageState();
}

class _ControlAsistenciaPageState extends State<ControlAsistenciaPage> {
  FocusNode _focusFotocheck = new FocusNode();
  FocusNode _focusConductor = new FocusNode();
  FocusNode _focusFecha = new FocusNode();
  TextEditingController _fechaController = TextEditingController();
  ControladorServicio _controladorServicio = ControladorServicio();

  TextEditingController textFotochekController = TextEditingController();
  TextEditingController textConductorController = TextEditingController();
  TextEditingController textObservacionController = TextEditingController();

  DocumentosValidar documentConductor = DocumentosValidar();
  DocumentosValidar documentUnidad = DocumentosValidar();
  ControlAsistencia controlAsistencia = ControlAsistencia(hora: "", mensaje: "", rpta: "");

  final player = AudioPlayer();

  Future<ControlAsistencia> ValidarAsistencia() async {
    if (await Permission.location.request().isGranted) {}
    controlAsistencia = await _controladorServicio.QRControlAsistencia(
      idEquipo: Provider.of<UsuarioProvider>(context, listen: false).idDispositivo,
      fotocheck: textFotochekController.text.trim(),
      tipoDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc,
      nroDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc,
    );

    return controlAsistencia;
  }

  bool enProceso = false;

  @override
  Widget build(BuildContext context) {
    _fechaController = TextEditingController(text: DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now()));

    return WillPopScope(
      onWillPop: () => Future(() => true),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Control de asistencia",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, 'controlSalidaLista');
              },
              icon: Icon(Icons.list_alt_sharp),
            )
          ],
        ),
        body: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Text(
                    "FOTOCHECK",
                    style: TextStyle(
                      color: AppColors.mainBlueColor,
                      fontSize: 16,
                    ),
                  ),
                  _inputField(
                    focus: _focusFotocheck,
                    Controller: textFotochekController,
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
                      // _showDialogCargando(context, "cargando");
                      if (res != '-1') {
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    onChanged: (value) {},
                  ),
                  SizedBox(height: 15),
                  Container(
                    height: 60,
                    margin: EdgeInsets.only(bottom: 0),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Expanded(
                          child: MaterialButton(
                            elevation: 0.8,
                            onPressed: () {
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
                            color: AppColors.mainBlueColor,
                            child: Text(
                              "Verificar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          padding: EdgeInsets.all(20),
          child: Text(
            "${Provider.of<UsuarioProvider>(context, listen: false).usuario.equipo}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }

  validar() async {
    _showDialogCargando(context, "Validando...");
    final validacion = await ValidarAsistencia();
    Navigator.pop(context);

    if (validacion.rpta == "1") {
      setState(() {
        textFotochekController.text = "";
        enProceso = false;
      });
      _focusFotocheck.requestFocus();

      _showDialogSuccess(
        "AUTORIZADO",
        "${validacion.mensaje}",
      );
    } else if (validacion.rpta == "500") {
      setState(() {
        textFotochekController.text = "";
        enProceso = false;
      });
      _focusFotocheck.requestFocus();

      _showDialogError(
        "NO AUTORIZADO",
        "${validacion.mensaje}",
      );
    } else {
      setState(() {
        textFotochekController.text = "";
        enProceso = false;
      });
      _focusFotocheck.requestFocus();

      _showDialogAlerta(
        "NO AUTORIZADO",
        "${validacion.mensaje}",
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

  void _showDialogSuccess(String titulo, String cuerpo) {
    player.play(AssetSource('sounds/success_sound.mp3'));

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          // /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
          //   Navigator.pop(context);
          // });

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.all(
                new Radius.circular(5),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.greenColor,
                  size: 30,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  titulo,
                  style: TextStyle(color: AppColors.greenColor, fontWeight: FontWeight.bold),
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
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text("Aceptar"),
              ),
            ],
          );
        });

    // Cerrar automáticamente después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDialogError(String titulo, String cuerpo) {
    player.play(AssetSource('sounds/error_sound2.mp3'));

    Color color = AppColors.redColor;

    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (context) {
          // /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
          //   Navigator.pop(context);
          // });

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.all(
                new Radius.circular(5),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
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
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text("Aceptar"),
              ),
            ],
          );
        });

    // Cerrar automáticamente después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDialogAlerta(String titulo, String cuerpo) {
    player.play(AssetSource('sounds/error_sound2.mp3'));

    Color color = AppColors.amberColor;

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        // /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
        //   Navigator.pop(context);
        // });

        return AlertDialog(
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
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Text("Aceptar"),
            ),
          ],
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
}

class _inputField extends StatelessWidget {
  const _inputField({
    super.key,
    required FocusNode focus,
    required TextEditingController Controller,
    required void Function()? onPressed,
    required void Function()? onEditingComplete,
    required void Function(String)? onChanged,
  })  : _focus = focus,
        _odometro = Controller,
        _onEditingComplete = onEditingComplete,
        _onChanged = onChanged,
        _onPressed = onPressed;

  final FocusNode _focus;
  final TextEditingController _odometro;
  final void Function()? _onPressed;
  final void Function()? _onEditingComplete;
  final void Function(String)? _onChanged;

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
      ),
      onEditingComplete: _onEditingComplete,
      onChanged: _onChanged,
    );
  }
}
