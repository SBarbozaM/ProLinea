import 'package:embarques_tdp/src/models/orden_servicio/os_obtener_taller.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_orden_servicio.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/pages/orden_servicio/lista_orden_servicio_taller_mantenimiento.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_bolsa.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/ordenServicio_service.dart';
import 'package:embarques_tdp/src/utils/ScanQR.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class ScanUnidadOrdenMantenimientoPage extends StatefulWidget {
  const ScanUnidadOrdenMantenimientoPage({super.key});

  @override
  State<ScanUnidadOrdenMantenimientoPage> createState() => _ScanUnidadOrdenMantenimientoPageState();
}

class _ScanUnidadOrdenMantenimientoPageState extends State<ScanUnidadOrdenMantenimientoPage> {
  OrdenServicioService sOrden = OrdenServicioService();

  FocusNode _focusFotocheck = new FocusNode();

  String? taller;

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
        ValidarUnidad();
      } else {
        // Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Datos de unidad"),
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
                    ValidarUnidad();
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
                    ValidarUnidad();
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

  ValidarUnidad() async {
    _showDialogCargando(context, "Validando...");
    await obtenerTaller();
    if (taller != null) {
      Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

      OsOrdenServicio requeResponse = await sOrden.ListaOrdenesServicio_Mantenimiento(
        Taller: taller!,
        Placa: textVehiculoController.text,
        Tdoc: usuario.tipoDoc,
        Ndoc: usuario.numDoc,
      );
      Navigator.pop(context);

      if (requeResponse.rpta == '0') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaOrdenServicioTaller_Mantenimiento(
              ordenes: requeResponse,
            ),
          ),
        );
        setState(() {
          enProceso = false;
          textVehiculoController.text = "";
        });
      } else {
        setState(() {
          textVehiculoController.text = "";
          enProceso = false;
        });
        _showDialogError(
          "ERROR",
          "${requeResponse.mensaje}",
        );
      }
    }
  }

  obtenerTaller() async {
    OrdenServicioService sOrden = OrdenServicioService();
    Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    OsObtenerTaller tallerResponse = await sOrden.ObtenerTaller(tdoc: usuario.tipoDoc, ndoc: usuario.numDoc);

    if (tallerResponse.rpta == '0') {
      if (tallerResponse.tallerCodigo.trim().isEmpty) {
        _showDialogErrorBack(
          "ERROR",
          "${tallerResponse.mensaje}",
        );
      } else {
        setState(() {
          taller = tallerResponse.tallerCodigo;
        });
      }
    } else {
      setState(() {
        taller = null;
      });
      _showDialogError(
        "ERROR",
        "${tallerResponse.mensaje}",
      );
    }
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
