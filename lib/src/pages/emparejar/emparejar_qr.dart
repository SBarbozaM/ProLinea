import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/drawer.dart';
import 'package:embarques_tdp/src/models/respuesta_mensaje.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/documento_servicio.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../models/documento.dart';
import '../../models/usuario.dart';
import '../../models/vinculacion.dart';
import '../../utils/app_colors.dart';

class EmparejarQrPage extends StatefulWidget {
  const EmparejarQrPage({Key? key}) : super(key: key);
  @override
  State<EmparejarQrPage> createState() => _EmparejarQrPageState();
}

class _EmparejarQrPageState extends State<EmparejarQrPage> {
  bool _mostrarCarga = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: "QR");
  // QRViewController? controller;
  String result = "";
  late Usuario _usuario;
  bool _escaneado = false;
  bool _emparejado = false;
  List<Documento> _docs = [];

  DocumentoServicio documentoServicio = new DocumentoServicio();

  final TextEditingController _PlacaUnidadcController = TextEditingController();
  FocusNode _focusUnidad = new FocusNode();

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    if (_usuario.viajeEmp != "" && _usuario.unidadEmp != "") {
      _emparejado = true;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _focusUnidad.dispose();
    _PlacaUnidadcController.dispose();
    // controller?.dispose();
  }

  //TODO: _ONQRVIEWCREATED
  // void _onQRViewCreated(QRViewController controller) {
  //   this.controller = controller;
  //   controller.scannedDataStream.listen((scanData) async {
  //     result = scanData.code!;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: _emparejado
              ? Text("Vinculado")
              : _escaneado
                  ? Text("Documentos")
                  : Text("Vincular"),
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  'inicio', (Route<dynamic> route) => false);
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
            ),
          ),
        ),
        body: ModalProgressHUD(
          opacity: 0.0,
          color: AppColors.whiteColor,
          progressIndicator: const CircularProgressIndicator(
            color: AppColors.mainBlueColor,
          ),
          inAsyncCall: _mostrarCarga,
          child: Column(
            /*mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,*/
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  /*physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),*/
                  child: !_emparejado
                      ? _seccionNoEmparejado(width, height)
                      : _seccionEmparejado(width),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _seccionNoEmparejado(double width, double height) {
    return Column(
      children: [
        SizedBox(
          height: 15,
        ),
        !_escaneado
            ? _qrScannerWidget(width, height)
            : SizedBox(
                height: 0,
              ),
        _resultadoScanQr(width),
        SizedBox(
          height: 100,
        ),
        // _escaneado ? _botonEscanear() : SizedBox()
      ],
    );
  }

  _qrScannerWidget(double width, double height) {
    return Column(children: [
      Container(
        width: width * 0.9,
        child: Text(
          "Escanee el código QR de la unidad",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18,
              color: AppColors.mainBlueColor,
              fontWeight: FontWeight.bold),
        ),
      ),
      SizedBox(
        height: 15,
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: TextFormField(
          //keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          focusNode: _focusUnidad,
          autofocus: true,
          controller: _PlacaUnidadcController,
          onEditingComplete: () async {
            // _showDialogSincronizandoDatos(context, "cargando");
            if (_PlacaUnidadcController.text != null) {
              var usuarioProvider =
                  Provider.of<UsuarioProvider>(context, listen: false).usuario;
              setState(() {
                _mostrarCarga = true;
              });

              if (!_escaneado) {
                _escaneado = true;

                Vinculacion vinculacion =
                    await documentoServicio.emparejarConductorViaje(
                        _usuario, _PlacaUnidadcController.text);

                if (vinculacion.rpta == "2") {
                  setState(() {
                    _PlacaUnidadcController.text = "";
                    _focusUnidad.requestFocus();
                    _docs = vinculacion.documentos;
                    _escaneado = true;
                  });
                  //_mostrarModalRespuesta("Error", vinculacion.mensaje, false).show();
                } else {
                  if (vinculacion.rpta == "0") {
                    await Provider.of<UsuarioProvider>(context, listen: false)
                        .emparejar(vinculacion.nroViaje, vinculacion.codUnidad,
                            vinculacion.placa, vinculacion.fecha, "");

                    setState(() {
                      _escaneado = true;
                      _emparejado = true;
                    });
                    /*_mostrarModalRespuesta("Vinculado", vinculacion.mensaje, true)
                  .show();*/
                  } else {
                    if (vinculacion.rpta == "1") {
                      setState(() {
                        _PlacaUnidadcController.text = "";
                        _focusUnidad.requestFocus();
                        _escaneado = false;
                      });
                      _mostrarModalRespuesta(
                              "Error", vinculacion.mensaje, false)
                          .show();
                    }
                  }
                }
              }
              setState(() {
                _mostrarCarga = false;
              });
              print(_PlacaUnidadcController.text);
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
      ),
      SizedBox(
        height: 15,
      ),
    ]);
  }

  _resultadoScanQr(double width) {
    if (_docs.length > 0) {
      return _listaDocumentos(width);
    } else {
      return Center(
        child: Text(""),
      );
    }
  }

  _botonEscanear() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _escaneado = false;
              _docs = [];
            });
          },
          child: Text("Volver a Escanear"),
          style: ElevatedButton.styleFrom(
            foregroundColor: AppColors.whiteColor,
            backgroundColor: AppColors.mainBlueColor,
          ),
        ),
        SizedBox(
          height: 15,
        )
      ],
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

  _listaDocumentos(double width) {
    return Container(
      margin: EdgeInsets.only(left: 15, right: 15),
      padding: EdgeInsets.only(bottom: 15, top: 15, left: 10, right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/close_icon.png',
            width: 810,
            height: 130,
          ),
          SizedBox(
            height: 25,
          ),
          Text(
            "No puede conducir la unidad porque tiene la siguiente documentación pendiente: ",
            overflow: TextOverflow.fade,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(
            height: 25,
          ),
          contarDocumentos("V") > 0
              ? Container(
                  child: Image.asset(
                    'assets/icons/driver_icon.png',
                    width: 60,
                    height: 60,
                  ),
                )
              : SizedBox(),
          SizedBox(
            height: 25,
          ),
          contarDocumentos("V") > 0
              ? Container(
                  child: Column(
                    children: _listaWidgetDocumentos("V"),
                  ),
                )
              : SizedBox(),
          SizedBox(
            height: 25,
          ),
          contarDocumentos("C") > 0
              ? Container(
                  child: Image.asset(
                    'assets/icons/busLinea-icon.png',
                    width: 60,
                    height: 60,
                  ),
                )
              : SizedBox(),
          SizedBox(
            height: 25,
          ),
          contarDocumentos("C") > 0
              ? Container(
                  child: Column(
                    children: _listaWidgetDocumentos("C"),
                  ),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  List<Widget> _listaWidgetDocumentos(String tipo) {
    List<Widget> lista = [];

    if (_docs.isEmpty) {
      lista.add(
        Card(
          child: ListTile(
            title: Text('No hay documentos para mostrar'),
          ),
        ),
      );
    } else {
      for (int i = 0; i < _docs.length; i++) {
        if (_docs[i].tipo == tipo) lista.add(_cardWidget(_docs[i]));
      }

      if (lista.isEmpty) {
        lista.add(
          Card(
            child: ListTile(
              title: Text(
                'No hay documentos para mostrar',
              ),
            ),
          ),
        );
      }
    }

    return lista;
  }

  _cardWidget(Documento documento) {
    String textoDescripcion = "";

    if (documento.fechaVencimiento != "") {
      textoDescripcion =
          documento.estado_descripcion + " " + documento.fechaVencimiento;
    } else {
      textoDescripcion = documento.estado_descripcion;
    }

    return Card(
        //margin: EdgeInsets.only(bottom: 15),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.redColor, width: 1.5, //<-- SEE HERE
          ),
        ),
        child: ListTile(
          title: Text(documento.nombre),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textoDescripcion,
                style: TextStyle(
                  color: AppColors.redColor,
                ),
              ),
            ],
          ),
        ));
  }

  _seccionEmparejado(double width) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 30,
          ),
          Container(
            margin: EdgeInsets.only(left: 15, right: 15),
            padding: EdgeInsets.only(bottom: 15, top: 15, left: 20, right: 20),
            width: width * 0.9,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.redColor, width: 5),
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
              /*gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 28, 76, 150),
                  Color.fromARGB(255, 151, 189, 245),
                ],
              ),*/
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Container(
                  margin: EdgeInsets.only(left: 15, right: 15),
                  width: width * 0.9,
                  child: Image.asset(
                    'assets/icons/check_color_icon.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                SizedBox(
                  height: 25,
                ),
                Text(
                  "Sr. " +
                      _usuario.nombres +
                      " se ha vinculado satisfactoriamente con la Unidad " +
                      _usuario.unidadEmp +
                      ", puede iniciar la conducción de la Unidad",
                  overflow: TextOverflow.fade,
                  //textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(
                  height: 25,
                ),
                Container(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/driver_icon.png',
                        width: 80,
                        height: 80,
                      ),
                      Image.asset(
                        'assets/icons/chain_icon.png',
                        width: 80,
                        height: 80,
                      ),
                      Image.asset(
                        'assets/icons/busLinea-icon.png',
                        width: 80,
                        height: 80,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 25,
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Unidad: " + _usuario.unidadEmp + "-" + _usuario.placaEmp,
                    style: TextStyle(color: AppColors.blackColor, fontSize: 18),
                  ),
                ),
                SizedBox(
                  height: 25,
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Vinculado el " + _usuario.fechaEmp,
                    style: TextStyle(
                      color: AppColors.blackColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(
                  height: 25,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
          ),
          ElevatedButton(
            onPressed: () {
              _mostrarModalDesvincular(
                      "Confirmación",
                      "¿Seguro que desea desvincularse con la unidad " +
                          _usuario.unidadEmp +
                          "-" +
                          _usuario.placaEmp +
                          "?")
                  .show();
            },
            child: Text("Desvincular"),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.whiteColor,
              backgroundColor: AppColors.redColor,
            ),
          ),
        ],
      ),
    );
  }

  AwesomeDialog _mostrarModalRespuesta(
      String titulo, String cuerpo, bool success) {
    return AwesomeDialog(
        context: context,
        dialogType: success ? DialogType.success : DialogType.error,
        animType: AnimType.topSlide,
        title: titulo,
        desc: cuerpo,
        autoHide: Duration(seconds: 3),
        dismissOnBackKeyPress: false,
        dismissOnTouchOutside: false);
  }

  AwesomeDialog _mostrarModalDesvincular(String titulo, String cuerpo) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      showCloseIcon: true,
      reverseBtnOrder: true,
      buttonsTextStyle: TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        setState(() {
          _mostrarCarga = true;
        });
        RespuestaMensaje respuesta =
            await documentoServicio.desvincularConductorViaje(_usuario);
        setState(() {
          _mostrarCarga = false;
        });

        if (respuesta.rpta == "0") {
          _mostrarModalRespuesta("Desvinculado", respuesta.mensaje, true)
              .show();
          await Provider.of<UsuarioProvider>(context, listen: false)
              .emparejar("", "", "", "", "");
          setState(() {
            _emparejado = false;
            _escaneado = false;
          });
        } else {
          _mostrarModalRespuesta("Error", respuesta.mensaje, false).show();
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  int contarDocumentos(String tipo) {
    if (_docs.isEmpty)
      return 0;
    else {
      int total = 0;
      for (int i = 0; i < _docs.length; i++) {
        if (_docs[i].tipo == tipo) total++;
      }
      return total;
    }
  }
}
