import 'package:embarques_tdp/src/components/webview_basica.dart';
import 'package:embarques_tdp/src/models/usuario-geop.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_bolsa.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/usuario-geop.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class VehiculoGeopPage extends StatefulWidget {
  const VehiculoGeopPage({super.key});

  @override
  State<VehiculoGeopPage> createState() => _VehiculoGeopPageState();
}

class _VehiculoGeopPageState extends State<VehiculoGeopPage> {
  final FocusNode _focusFotocheck = FocusNode();

  final UsuarioGeopServicio _usuarioGeopServicio = UsuarioGeopServicio();

  TextEditingController textVehiculoController = TextEditingController();
  bool enProceso = false;

  @override
  void initState() {
    super.initState();
    cargarQR();
  }

  cargarQR() {
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
        validar();
      } else {
        // Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Datos de unidad"),
          centerTitle: true,
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
            ),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
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
                  if (res != '-1') {
                    setState(() {
                      textVehiculoController.text = res;
                    });
                    validar();
                  } else {
                    Navigator.pop(context);
                  }
                },
                onChanged: (value) {},
              ),
            ],
          ),
        ));
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

  validar() async {
    _showDialogCargando(context, "Validando...");
    final validacion = await ValidarUnidad();
    Navigator.pop(context);

    if (validacion.status == "200") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewBasicaPage(
            url: "https://plataformas.linea.pe/GEOP/GEOP_APP?p=${validacion.encriptado}&placaunidad=${textVehiculoController.text.trim()}&codunidad=${validacion.codUndiad}",
            titulo: "Datos de unidad",
            back: "padronVehicularGeop",
          ),
        ),
      );
      setState(() {
        enProceso = false;
      });
    } else {
      setState(() {
        textVehiculoController.text = "";
        enProceso = false;
      });
      _showDialogError(
        "ERROR",
        "${validacion.rpta}",
      );
    }
  }

  Future<UsuarioGeop> ValidarUnidad() async {
    Usuario user = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    var usuarioGeopResponse = await _usuarioGeopServicio.GeopvalidarUnidad(
      idUsuario: user.usuarioId!,
      tipoDoc: user.tipoDoc,
      ndoc: user.numDoc,
      paterno: user.apellidoPat,
      materno: user.apellidoMat,
      nombres: user.nombres,
      placa: textVehiculoController.text.trim(),
    );

    return usuarioGeopResponse;
  }

  void _showDialogError(String titulo, String cuerpo) {
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
