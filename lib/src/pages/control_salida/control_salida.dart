import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:embarques_tdp/src/models/control_salida.dart';
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

class ControlSalidaPage extends StatefulWidget {
  final ValueNotifier<Position?>? posicionNotifier;
  const ControlSalidaPage({super.key, this.posicionNotifier});

  @override
  State<ControlSalidaPage> createState() => _ControlSalidaPageState();
}

class _ControlSalidaPageState extends State<ControlSalidaPage> {
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
  ControlSalida controlSalida = ControlSalida();

  final player = AudioPlayer();
  @override
  void initState() {
    widget.posicionNotifier?.addListener(() {
      setState(() {
        _posicionActual = widget.posicionNotifier!.value;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.posicionNotifier?.removeListener(() {});
    super.dispose();
  }

  Future<ControlSalida> ValidarSalida() async {
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

    controlSalida = await _controladorServicio.QRControlSalidas(
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
    String rpta = await _controladorServicio.QRConfirmarControlSalidas(
      idAndroid: Provider.of<UsuarioProvider>(context, listen: false).idDispositivo,
      Observacion: textObservacionController.text,
      idControl: controlSalida.idControl.toString(),
      salidaHabilitada: habilitarSalida.toString(),
    );
    return rpta;
  }

  int validarSalida = 1;
  bool enProceso = false;
  bool errorUnidad = false;
  bool errorConductor = false;

  @override
  Widget build(BuildContext context) {
    _fechaController = TextEditingController(text: DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now()));

    return WillPopScope(
      onWillPop: () => Future(() => validarSalida == 1 ? true : false),
      child: Scaffold(
        appBar: AppBar(
          // title: Text(
          //   "Control Salidas",
          //   style: TextStyle(color: AppColors.mainBlueColor),
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
            if (validarSalida == 1)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'controlSalidaLista');
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
            child: validarSalida == 1
                ? SingleChildScrollView(
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

                            ///  _showDialogCargando(context, "cargando");
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
                        // Text(
                        //   "FECHA*",
                        //   style: TextStyle(
                        //     color: AppColors.mainBlueColor,
                        //     fontSize: 16,
                        //   ),
                        // ),
                      ],
                    ),
                  )
                : validarSalida == 0
                    ? SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Container(
                              alignment: Alignment.center,
                              child: Image(
                                image: AssetImage('assets/icons/check_color_icon.png'),
                                width: 100,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Puedes conducir porque no tienes documentación pendiente",
                              style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 30),
                            Material(
                              elevation: 2,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      child: Image(
                                        image: AssetImage('assets/icons/driver_icon.png'),
                                        width: 50,
                                      ),
                                    ),
                                    Text(
                                      "${documentConductor.titulo}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(height: 5),
                                    Column(
                                      children: documentConductor.documentos
                                          .map((e) => Container(
                                                width: double.infinity,
                                                margin: EdgeInsets.only(bottom: 7),
                                                padding: EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  "${e}",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Material(
                              elevation: 2,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      child: Image(
                                        image: AssetImage('assets/icons/busLinea-icon.png'),
                                        width: 50,
                                      ),
                                    ),
                                    Text(
                                      "${documentUnidad.titulo}",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(height: 5),
                                    Column(
                                      children: documentUnidad.documentos
                                          .map((e) => Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  "${e}",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            Text(
                              "¿Salida habilitada?",
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.mainBlueColor,
                              ),
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
                                      onPressed: () {},
                                      height: double.infinity,
                                      child: Text(
                                        "No",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: MaterialButton(
                                      elevation: 0.8,
                                      onPressed: () {},
                                      height: double.infinity,
                                      child: Text(
                                        "Si",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: Image(
                                image: AssetImage('assets/icons/close_icon.png'),
                                width: 80,
                              ),
                            ),
                            // Text(
                            //   "No Puedes conducir porque tienes la siguiente documentación pendiente",
                            //   style: TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                            // ),
                            SizedBox(height: 5),
                            Material(
                              elevation: 3,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      child: Image(
                                        image: AssetImage('assets/icons/driver_icon.png'),
                                        width: 50,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "${documentConductor.titulo}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: documentConductor.documentos.length == 0 ? AppColors.greenColor : AppColors.redColor,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Column(
                                      children: documentConductor.documentos
                                          .map((e) => Container(
                                                width: double.infinity,
                                                margin: EdgeInsets.only(bottom: 15),
                                                padding: EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: AppColors.redColor,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  "${e}",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Material(
                              elevation: 3,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      child: Image(
                                        image: AssetImage('assets/icons/busLinea-icon.png'),
                                        width: 40,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "${documentUnidad.titulo}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: documentUnidad.documentos.length == 0 ? AppColors.greenColor : AppColors.redColor,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Column(
                                      children: documentUnidad.documentos
                                          .map((e) => Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: AppColors.redColor,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  "${e}",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            Container(
                                alignment: Alignment.center,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${documentConductor.documentos.length > 0 && documentUnidad.documentos.length == 0 ? 'El conductor' : ''}${documentUnidad.documentos.length > 0 && documentConductor.documentos.length == 0 ? 'La unidad' : ''}${documentConductor.documentos.length > 1 && documentUnidad.documentos.length > 1 ? 'La unidad y el conductor tiene documentos pendientes' : ''}  tiene documentos que no están en regla, ",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: AppColors.mainBlueColor,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "Aún así autoriza la habilitación de la unidad?",
                                        style: TextStyle(
                                          fontSize: 21,
                                          color: AppColors.blackColor,
                                        ),
                                      )
                                    ],
                                  ),
                                )),
                            SizedBox(height: 8),
                            TextFormField(
                              textAlign: TextAlign.start,
                              style: TextStyle(color: Colors.black),
                              autofocus: true,
                              controller: textObservacionController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
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
                                hintText: "Observaciones al habilitar la unidad (opcional)",
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                              maxLines: 2,
                              onEditingComplete: () {},
                            ),
                            SizedBox(height: 5),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: MaterialButton(
                                        elevation: 0.8,
                                        onPressed: () async {
                                          _showDialogCargando(context, "Autorizando...");
                                          String rpta = await ConfirmarValidarSalida(0);
                                          Navigator.pop(context);
                                          if (rpta == "0") {
                                            setState(() {
                                              textConductorController.text = "";
                                              textUnidadController.text = "";
                                              validarSalida = 1;
                                            });
                                          } else {
                                            _showDialogError(
                                              confirmacion: false,
                                              context: context,
                                              mensaje: "Fallo la autorización de la salida de la unidad",
                                              textoboton: "Aceptar",
                                              titulo: "Lo sentimos",
                                            );
                                          }
                                        },
                                        height: double.infinity,
                                        child: Text(
                                          "No",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        color: AppColors.redColor),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: MaterialButton(
                                        elevation: 0.8,
                                        onPressed: () async {
                                          _showDialogCargando(context, "Autorizando...");
                                          String rpta = await ConfirmarValidarSalida(1);
                                          Navigator.pop(context);
                                          if (rpta == "0") {
                                            setState(() {
                                              textConductorController.text = "";
                                              textUnidadController.text = "";
                                              validarSalida = 1;
                                            });
                                            _focusUnidad.requestFocus();

                                            _showDialogSuccess(
                                              context: context,
                                              mensaje: "Se registro su salida de la unidad.",
                                              textoboton: "Aceptar",
                                              titulo: "Unidad Autorizada",
                                            );
                                          } else {
                                            setState(() {
                                              textConductorController.text = "";
                                              textUnidadController.text = "";
                                              validarSalida = 1;
                                            });
                                            _focusUnidad.requestFocus();

                                            _showDialogError(
                                              confirmacion: false,
                                              context: context,
                                              mensaje: "Fallo la autorización de la salida de la unidad",
                                              textoboton: "Aceptar",
                                              titulo: "Lo sentimos",
                                            );
                                          }
                                        },
                                        height: double.infinity,
                                        child: Text(
                                          "Si",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        color: AppColors.greenColor),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
          ),
        ),
        floatingActionButton: validarSalida == 1
            ? Container(
                height: 60,
                margin: EdgeInsets.only(bottom: 0),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    Expanded(
                      child: MaterialButton(
                        elevation: 0.8,
                        onPressed: () {
                          setState(() {
                            textConductorController.text = "";
                            textUnidadController.text = "";
                          });
                        },
                        height: double.infinity,
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        color: Colors.white,
                      ),
                    ),
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
                        color: Colors.white,
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
              )
            : Container(
                height: 60,
                margin: EdgeInsets.only(bottom: 0),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    // Expanded(
                    //   child: MaterialButton(
                    //     elevation: 0.8,
                    //     onPressed: () async {
                    //       setState(() {
                    //         validarSalida = 1;
                    //         textConductorController.text = "";
                    //         textUnidadController.text = "";
                    //       });
                    //       _focusUnidad.requestFocus();
                    //     },
                    //     height: double.infinity,
                    //     color: Colors.white,
                    //     child: Text(
                    //       "Reintentar",
                    //       style: TextStyle(
                    //         color: AppColors.mainBlueColor,
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
        floatingActionButtonLocation: validarSalida == 1 ? FloatingActionButtonLocation.centerDocked : FloatingActionButtonLocation.endContained,
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
    final validacion = await ValidarSalida();

    if (validacion.rpta == "0") {
      Navigator.pop(context);
      setState(() {
        enProceso = false;
        textConductorController.text = "";
        textUnidadController.text = "";
        validarSalida = 1;
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
          titulo: "Documentos en regla",
        );
      } else {
        _showDialogError(
          confirmacion: false,
          context: context,
          mensaje: "Fallo la autorización de la salida de la unidad",
          textoboton: "Aceptar",
          titulo: "Lo sentimos",
        );
      }
    } else if (validacion.rpta == "2") {
      Navigator.pop(context);

      setState(() {
        enProceso = false;
      });

      var unidad;
      var tituloUnidad;
      var documentosUNI;

      var conductor;
      var tituloConductor;
      var documentosCON;

      if (validacion.cantDocUnidad > 0) {
        unidad = validacion.errorUnidad.split(":");
        tituloUnidad = unidad[0];
        documentosUNI = unidad[1].split(",");
      }

      if (validacion.cantDocConductor > 0) {
        conductor = validacion.errorConductor.split(":");
        tituloConductor = conductor[0];
        documentosCON = conductor[1].split(",");
      }
      setState(() {
        validarSalida = 2;

        if (validacion.cantDocConductor > 0) {
          documentConductor.titulo = tituloConductor;
          documentConductor.documentos = documentosCON;
        } else {
          documentConductor.titulo = "No tiene documentos pendientes.";
          documentConductor.documentos = [];
        }

        if (validacion.cantDocUnidad > 0) {
          documentUnidad.titulo = tituloUnidad;
          documentUnidad.documentos = documentosUNI;
        } else {
          documentUnidad.titulo = "No tiene documentos pendientes.";
          documentUnidad.documentos = [];
        }
      });
    } else if (validacion.rpta == "3") {
      Navigator.pop(context);

      setState(() {
        enProceso = false;
        textConductorController.text = "";
        textUnidadController.text = "";
        validarSalida = 1;
      });
      _focusUnidad.requestFocus();

      _showDialogErrorCONFIRMAR(
        confirmacion: true,
        context: context,
        titulo: "Lo sentimos ",
        mensaje: "${validacion.mensaje}",
        textoboton: "",
      );
    } else {
      Navigator.pop(context);
      setState(() {
        enProceso = false;
        textConductorController.text = "";
        textUnidadController.text = "";
        validarSalida = 1;
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
    player.play(AssetSource('sounds/error_sound2.mp3'));
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
              height: 320,
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
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      "¿Salida habilitada?",
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.mainBlueColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  TextFormField(
                    textAlign: TextAlign.start,
                    style: TextStyle(color: Colors.black),
                    autofocus: true,
                    controller: textObservacionController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
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
                        hintText: "Observacion - opcional"),
                    maxLines: 2,
                    onEditingComplete: () {},
                  ),
                  SizedBox(height: 5),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MaterialButton(
                            elevation: 0.8,
                            onPressed: () async {
                              Navigator.pop(context);
                              // _showDialogCargando(context, "Autorizando...");
                              // String rpta = await ConfirmarValidarSalida(0);
                              // if (rpta == "0") {
                              //   Navigator.pop(context);
                              //   ScaffoldMessenger.of(context)
                              //     ..showSnackBar(
                              //       SnackBar(
                              //         content: Text(
                              //           "Unidad autorizada con exito",
                              //           style: TextStyle(color: Colors.white),
                              //         ),
                              //         backgroundColor: Colors.green,
                              //       ),
                              //     );
                              //   Navigator.pop(context);
                              //   setState(() {
                              //     textConductorController.text = "";
                              //     textUnidadController.text = "";
                              //     validarSalida = 1;
                              //   });
                              //   _focusUnidad.requestFocus();
                              // } else {
                              //   Navigator.pop(context);
                              //   _showDialogError(
                              //     confirmacion: false,
                              //     context: context,
                              //     mensaje: "Fallo la autorización de la salida de la unidad",
                              //     textoboton: "Aceptar",
                              //     titulo: "Lo sentimos",
                              //     onPressed: () {
                              //       Navigator.pop(context);
                              //       setState(() {
                              //         textConductorController.text = "";
                              //         textUnidadController.text = "";
                              //         validarSalida = 1;
                              //       });
                              //       _focusUnidad.requestFocus();
                              //     },
                              //   );
                              // }
                            },
                            height: double.infinity,
                            child: Text(
                              "No",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MaterialButton(
                            elevation: 0.8,
                            onPressed: () async {
                              _showDialogCargando(context, "Autorizando...");
                              String rpta = await ConfirmarValidarSalida(1);
                              Navigator.pop(context);
                              if (rpta == "0") {
                                _showDialogSuccessConfirm(
                                  context: context,
                                  mensaje: "Se registro su salida de la unidad.",
                                  textoboton: "Aceptar",
                                  titulo: "Unidad Autorizada",
                                );
                              } else {
                                _showDialogError(
                                  confirmacion: false,
                                  context: context,
                                  mensaje: "Fallo la autorización de la salida de la unidad",
                                  textoboton: "Aceptar",
                                  titulo: "Lo sentimos",
                                );
                              }
                            },
                            height: double.infinity,
                            child: Text(
                              "Si",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            color: Colors.green,
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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDialogSuccessConfirm({
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
            height: 220,
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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
        _controller = Controller,
        _onEditingComplete = onEditingComplete,
        _onChanged = onChanged,
        _onPressed = onPressed,
        _errorText = errorText;

  final FocusNode _focus;
  final TextEditingController _controller;
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
      controller: _controller,
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
