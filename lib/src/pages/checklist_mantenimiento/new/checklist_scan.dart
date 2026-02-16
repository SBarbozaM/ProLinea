import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_obtener_taller.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/new/checklist_mantenimiento.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_bolsa.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/ordenServicio_service.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class CheckListScanPage extends StatefulWidget {
  final String tipoCheckListNombre;
  const CheckListScanPage({super.key, required this.tipoCheckListNombre});

  @override
  State<CheckListScanPage> createState() => _CheckListScanPageState();
}

class _CheckListScanPageState extends State<CheckListScanPage> {
  OrdenServicioService sOrden = OrdenServicioService();

  FocusNode _focusFotocheck = new FocusNode();

  String? taller;

  TextEditingController textVehiculoController = TextEditingController();
  bool enProceso = false;

  @override
  void initState() {
    super.initState();
    // cargarQR();
  }

  cargarQR() async {
    var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQRPage()));

    if (res != '-1') {
      setState(() {
        textVehiculoController.text = res;
      });

      ValidarUnidad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChecklistBloc, ChecklistState>(
      listener: (context, state) {
        if (state.statusValidarCheck == StatusValidarCheck.success) {
          setState(() {
            enProceso = false;
            textVehiculoController.text = "";
          });

          // 🔥 LEER Provider ANTES del pop para evitar usar un context destruido
          final usuarioProv = Provider.of<UsuarioProvider>(context, listen: false);
          final tipoDoc = usuarioProv.usuario.tipoDoc;
          final numDoc = usuarioProv.usuario.numDoc;
          final tipoListSelected = usuarioProv.usuario.tipoListSelected ?? 0;

          // 🔥 Cerrar solo después de obtener los valores correctos
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          if (state.validarCheck.rpta == "0" && state.validarCheck.hoseCodigo != 0) {
            final String hora = formatearHoraTexto(state.validarCheck.hoseRegistro);
            return _showDialogContinuarCheckList("CONFIRMACIÓN", "Tiene un Checklist reportado a las ${hora} . ¿Deseas modificarlo?", "${state.validarCheck.codVehiculo}", "${state.validarCheck.descVehiculo}", state.validarCheck.hoseCodigo);
          }
          // 🔥 Enviar evento al Bloc con datos correctos
          context.read<ChecklistBloc>().add(ListarCheckListEvent(hoseCode: state.validarCheck.hoseCodigo, tDoc: tipoDoc, nDoc: numDoc, placa: state.validarCheck.codVehiculo, tipoCheckList: tipoListSelected));

          // 🔥 Navegación correcta con el mismo context
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChecklistMantenimientoPage(titulo: widget.tipoCheckListNombre, descripcionVhlo: state.validarCheck.descVehiculo)));
        }

        if (state.statusValidarCheck == StatusValidarCheck.failure) {
          setState(() {
            textVehiculoController.text = "";
            enProceso = false;
          });
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          if (state.validarCheck.rpta == "500") {
            return _showDialogError("ERROR", "Falló la consulta desde base de datos.");
          }
          _showDialogError("ERROR", "${state.validarCheck.mensaje}");
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Check List ${widget.tipoCheckListNombre}"),
          centerTitle: true,
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back_ios_new),
          ),
        ),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("QR UNIDAD", style: TextStyle(color: AppColors.mainBlueColor, fontSize: 16)),
              _inputField(
                focus: _focusFotocheck,
                Controller: textVehiculoController,
                onEditingComplete: () async {
                  if (enProceso) return;

                  setState(() {
                    enProceso = true;
                  });

                  ValidarUnidad();
                },
                onPressed: () async {
                  var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanQRPage()));
                  if (res != '-1') {
                    setState(() {
                      textVehiculoController.text = res;
                    });

                    ValidarUnidad();
                  }
                },
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ),
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

  ValidarUnidad() async {
    _showDialogCargando(context, "Validando...");
    context.read<ChecklistBloc>().add(ValidarListarCheckConductorEvent(tipoDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc, nroDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc, placa: textVehiculoController.text, codOperacion: Provider.of<UsuarioProvider>(context, listen: false).usuario.codOperacion, tipoCheckList: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoListSelected ?? 0));
  }

  obtenerTaller() async {
    OrdenServicioService sOrden = OrdenServicioService();
    Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    OsObtenerTaller tallerResponse = await sOrden.ObtenerTaller(tdoc: usuario.tipoDoc, ndoc: usuario.numDoc);

    if (tallerResponse.rpta == '0') {
      setState(() {
        taller = tallerResponse.tallerCodigo;
      });
    } else {
      setState(() {
        taller = null;
      });
      _showDialogError("ERROR", "${tallerResponse.mensaje}");
    }
  }

  String formatearHoraTexto(String hora) {
    final partes = hora.split(":");
    int h = int.parse(partes[0]);
    int m = int.parse(partes[1]);

    String ampm = h >= 12 ? "PM" : "AM";

    int hour12 = h % 12;
    if (hour12 == 0) hour12 = 12;

    String min = m.toString().padLeft(2, '0');

    return "$hour12:$min $ampm";
  }

  void _showDialogErrorBack(String titulo, String cuerpo) {
    Color color = AppColors.redColor;

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        // /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
        //   Navigator.pop(context);
        // });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: new BorderRadius.all(new Radius.circular(5))),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: color, size: 30),
              const SizedBox(width: 10),
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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDialogError(String titulo, String cuerpo) {
    Color color = AppColors.redColor;

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        Timer modalTimer = new Timer(Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: new BorderRadius.all(new Radius.circular(5))),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: color, size: 30),
              const SizedBox(width: 10),
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
                modalTimer.cancel();
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
  }

  void _showDialogContinuarCheckList(String titulo, String cuerpo, String placa, String descripcion, int codigoHS) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          shape: RoundedRectangleBorder(borderRadius: new BorderRadius.all(new Radius.circular(5))),
          title: Row(
            children: [
              Text(
                titulo,
                style: TextStyle(color: AppColors.amberColor, fontWeight: FontWeight.bold),
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
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    color: AppColors.greenColor,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      context.read<ChecklistBloc>().add(ListarCheckListEvent(hoseCode: codigoHS, tDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc, nDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc, placa: placa, tipoCheckList: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoListSelected ?? 0));
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChecklistMantenimientoPage(titulo: widget.tipoCheckListNombre, descripcionVhlo: descripcion)));
                    },
                    child: Text("Si", style: TextStyle(color: AppColors.whiteColor, fontSize: 19)),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: MaterialButton(
                    color: AppColors.redColor,
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text("No", style: TextStyle(color: AppColors.whiteColor, fontSize: 19)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _inputField extends StatelessWidget {
  const _inputField({super.key, required FocusNode focus, required TextEditingController Controller, required void Function()? onPressed, required void Function()? onEditingComplete, required void Function(String)? onChanged})
      : _focus = focus,
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
          icon: Icon(Icons.qr_code_scanner_sharp, size: 25, color: AppColors.mainBlueColor),
        ),
        border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.mainBlueColor)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.mainBlueColor, width: 1.5)),
      ),
      onEditingComplete: _onEditingComplete,
      onChanged: _onChanged,
    );
  }
}
