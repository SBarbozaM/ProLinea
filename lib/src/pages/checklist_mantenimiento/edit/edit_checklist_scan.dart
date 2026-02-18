import 'dart:async';

import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/edit/edit_checklist_lista_activas.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_bolsa.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/ordenServicio_service.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
// import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class EditCheckListScanPage extends StatefulWidget {
  const EditCheckListScanPage({super.key});

  @override
  State<EditCheckListScanPage> createState() => _EditCheckListScanPageState();
}

class _EditCheckListScanPageState extends State<EditCheckListScanPage> {
  OrdenServicioService sOrden = OrdenServicioService();
  FocusNode _focusFotocheck = new FocusNode();
  String? taller;
  TextEditingController textVehiculoController = TextEditingController();
  bool enProceso = false;

  @override
  void initState() {
    super.initState();
    cargarQR(context as BuildContext);
  }

  cargarQR(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      var res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ScanQRPage(),
        ),
      );
      if (res != '-1') {
        setState(() {
          textVehiculoController.text = res;
        });
        ValidarUnidad(context);
      } else {
        // Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChecklistBloc, ChecklistState>(
      listener: (context, state) {
        if (state.statusValidarCheck == StatusValidarCheck.success) {
          String placa = textVehiculoController.text;
          setState(() {
            enProceso = false;
            textVehiculoController.text = "";
          });
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditChecklistListaActivas(placa: placa),
            ),
          );
        }

        if (state.statusValidarCheck == StatusValidarCheck.failure) {
          setState(() {
            textVehiculoController.text = "";
            enProceso = false;
          });
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          _showDialogError("ERROR", "${state.mensaje}", context);
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text("Buscar Check List"),
            centerTitle: true,
            backgroundColor: AppColors.mainBlueColor,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
              ),
            ),
          ),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "QR UNIDAD",
                  style: TextStyle(
                    color: AppColors.mainBlueColor,
                    fontSize: 16,
                  ),
                ),
                _inputField(
                  focus: _focusFotocheck,
                  Controller: textVehiculoController,
                  onEditingComplete: () {
                    if (enProceso) {
                      return;
                    } else {
                      setState(() {
                        enProceso = true;
                      });
                      ValidarUnidad(context);
                    }
                  },
                  onPressed: () async {
                    var res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScanQRPage(),
                      ),
                    );
                    if (res != '-1') {
                      setState(() {
                        textVehiculoController.text = res;
                      });
                      ValidarUnidad(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  onChanged: (value) {},
                ),
              ],
            ),
          )),
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

  ValidarUnidad(
    BuildContext context,
  ) async {
    _showDialogCargando(context, "Validando...");
    context.read<ChecklistBloc>().add(
          ValidarListarEditarCheckConductorEvent(
            tipoDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc,
            nroDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc,
            placa: textVehiculoController.text,
            codOperacion: Provider.of<UsuarioProvider>(context, listen: false).usuario.codOperacion,
          ),
        );
  }

  void _showDialogErrorBack(String titulo, String cuerpo, BuildContext context) {
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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showDialogError(String titulo, String cuerpo, BuildContext context) {
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
                  modalTimer.cancel();
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
