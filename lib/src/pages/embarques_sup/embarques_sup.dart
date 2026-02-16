import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/drawer.dart';
import 'package:embarques_tdp/src/models/documento.dart';
import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/ruta.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/models/vinculacion.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/services/documento_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

class EmbarquesSupervisor extends StatefulWidget {
  const EmbarquesSupervisor({super.key});

  @override
  State<EmbarquesSupervisor> createState() => _EmbarquesSupervisorState();
}

class _EmbarquesSupervisorState extends State<EmbarquesSupervisor> {
  late NavigatorState _navigator;
  bool _cambioDependencia = false;

  bool _mostrarCarga = false;
  late Usuario _usuario;
  String _opcionSeleccionadaRuta = "-1";
  List<Ruta> _rutas = [];
  DateTime _fechaSeleccionada = DateTime.now();
  List<Viaje> _viajesEncontrados = [];
  bool _escaneado = false;
  bool _emparejado = false;

  List<Documento> _docs = [];

  EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();
  DocumentoServicio documentoServicio = new DocumentoServicio();

  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    setState(() {
      _cambioDependencia = true;
    });
    super.didChangeDependencies();
  }

  @override
  initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _rutas = Provider.of<RutasProvider>(context, listen: false).rutasEmbarquesHoy;

    if (_rutas.isNotEmpty) {
      _opcionSeleccionadaRuta = _rutas.first.codRuta;
      cargarViajes(_usuario.codOperacion, _rutas[0].codRuta);
      if (_rutas.length == 1) {}
    }
    super.initState();
  }

  cargarViajes(codOperacion, codRuta) async {
    List<Viaje> viajesList = await _embarquesSupScanerServicio.obtenerViajesRutaSupervisor(codOperacion, codRuta);
    setState(() {
      _viajesEncontrados = viajesList;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(Duration(seconds: 2), () async {});
        },
        child: Scaffold(
          drawer: const MyDrawer(),
          appBar: AppBar(
            title: const Text('Embarques'),
            backgroundColor: AppColors.mainBlueColor,
          ),
          body: ModalProgressHUD(
            opacity: 0.0,
            color: AppColors.whiteColor,
            progressIndicator: const CircularProgressIndicator(
              color: AppColors.mainBlueColor,
            ),
            inAsyncCall: _mostrarCarga,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                      const SizedBox(
                        height: 20,
                      ),
                      _tituloSmallScreen(width),
                      const SizedBox(
                        height: 20,
                      ),
                      _filtrosSmallScreen(width),
                      const SizedBox(
                        height: 20,
                      ),
                      //LISTA DE PASAJEROS
                      Container(
                        //height: height * 0.55,
                        padding: EdgeInsets.only(left: 25, right: 25),

                        //color: AppColors.lightGreenColor,
                        child: _viajesEncontrados.isEmpty
                            ? Card(
                                child: ListTile(
                                  title: Text('No hay viajes para mostrar'),
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Column(
                                  children: _viajesEncontrados.map((viaje) {
                                    return GestureDetector(
                                        onTap: () {
                                          // vincularYMostrarEmbarque(viaje);
                                          _modalSincronizacion(context, viaje);
                                        },
                                        child: CardViaje(viaje: viaje));
                                  }).toList(),
                                ),
                              ),
                      )
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  vincularYMostrarEmbarque(Viaje viaje) async {
    Vinculacion vinculacion = await DocumentoServicio().emparejarConductorViajeSupervisor(
      viaje.tipoDocumento,
      viaje.numDocumento,
      viaje.cod_vehiculo,
      viaje.codOperacion,
    );

    if (vinculacion.rpta == "2") {
      setState(() {
        _docs = vinculacion.documentos;
        _escaneado = true;
      });
      _mostrarModalRespuesta("Error", vinculacion.mensaje, false).show();
    } else {
      if (vinculacion.rpta == "0") {
        // await Provider.of<UsuarioProvider>(context, listen: false).emparejar(
        //     vinculacion.nroViaje,
        //     vinculacion.codUnidad,
        //     vinculacion.placa,
        //     vinculacion.fecha);

        // _modalSincronizacion(context, viaje);
        setState(() {
          _escaneado = true;
          _emparejado = true;
        });
        /*_mostrarModalRespuesta("Vinculado", vinculacion.mensaje, true)
                .show();*/
      } else {
        if (vinculacion.rpta == "1") {
          setState(() {
            _escaneado = false;
          });
          _mostrarModalRespuesta("Error", vinculacion.mensaje, false).show();
        }
      }
    }
  }

  void _modalSincronizacion(BuildContext context, Viaje viajee) async {
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    var viajeServicio = new ViajeServicio();

    Viaje viaje;

    viaje = await viajeServicio.obtenerViajeVinculadoBolsaSupervisor_v4(
      viajee.tipoDocumento,
      viajee.numDocumento,
      viajee.nroViaje,
    );

    if (viaje.rpta == "0") {
      if (_cambioDependencia) context = _navigator.context;

      Provider.of<ViajeProvider>(_navigator.context, listen: false).viajeActual(viaje: viaje);

      if (viaje.codOperacion != 'O175') {
        //PASAJEROS HABILITADOS
        await Provider.of<PasajeroHabilitadoProvider>(context, listen: false).obtenerPasajerosHabilitadosBD(viaje.nroViaje, viaje.codOperacion);

        /*List<Pasajero> pasajerosHabilitados =
            Provider.of<PasajeroHabilitadoProvider>(context, listen: false)
                .pasajerosHabilitados;

        //INSERTAR A LOS PASAJEROS EN LA BDLOCAL
        await AppDatabase.instance
            .insertarPasajerosHabilitados(pasajerosHabilitados);*/
        Navigator.pop(context, 'Cancel');
        //Navigator.popAndPushNamed(context, 'navigationViaje');
        Navigator.of(context).pushNamedAndRemoveUntil('navigationViaje', (Route<dynamic> route) => false);
      } else {
        //PRERESERVAS

        final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;

        await Provider.of<PrereservaProvider>(context, listen: false).obtenerListadoPrereservasBD(
          viaje.nroViaje,
          usuarioProvider.tipoDoc,
          usuarioProvider.numDoc,
          viaje.codOperacion,
        );

        List<Pasajero> listadoPrereservas = await Provider.of<PrereservaProvider>(context, listen: false).listdoPrereservas;

        // await AppDatabase.instance.insertarPrereservas(listadoPrereservas);

        Navigator.pop(context, 'Cancel');
        //Navigator.popAndPushNamed(context, 'navigationBolsaViaje');
        Navigator.of(context).pushNamedAndRemoveUntil('navigationBolsaViaje', (Route<dynamic> route) => false);
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;
      Navigator.pop(context, 'Cancel');
      _showDialogError(context, "NO SE PUDO SINCRONIZAR", viaje.mensaje!);
    }
  }

  void _showDialogError(BuildContext context, String titulo, String mensaje) {
    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          Timer modalTimer = new Timer(Duration(seconds: 3), () {
            Navigator.pop(context);
          });

          return AlertDialog(
            title: Text(
              titulo,
              textAlign: TextAlign.center,
            ),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () {
                  modalTimer.cancel();
                  Navigator.pop(context);
                },
                child: Text(
                  "Aceptar",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          );
        });
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

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 3), dismissOnBackKeyPress: false, dismissOnTouchOutside: false);
  }

  _tituloSmallScreen(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: width * 0.9,
          child: FittedBox(
            child: Text(
              'LISTA DE SALIDAS DE HOY',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blueDarkColor),
            ),
          ),
        ),
      ],
    );
  }

  _filtrosSmallScreen(double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              width: width * 0.3,
              height: 25,
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: FittedBox(
                child: Text("Ruta: "),
              ),
            ),
            Container(
              width: width * 0.65,
              height: 25,
              //padding: const EdgeInsets.only(left: 10, right: 25),
              child: _dropdownRutas(width),
            ),
          ],
        ),
        SizedBox(
          height: 15,
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> getOpcionesDropdownRutas(double width) {
    List<DropdownMenuItem<String>> listaRutas = [];

    if (_rutas.isEmpty) {
      listaRutas.add(const DropdownMenuItem<String>(
        value: "-1",
        child: Text(
          "---",
        ),
      ));
    } else {
      for (int i = 0; i < _rutas.length; i++) {
        listaRutas.add(
          DropdownMenuItem(
            child: Container(
                width: width * 0.55,
                height: 25,
                child: FittedBox(
                  child: Text(
                    _rutas[i].ruta,
                  ),
                )
                /*style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.blueColor),*/
                ),
            value: _rutas[i].codRuta,
          ),
        );
      }
    }

    return listaRutas;
  }

  _mostrarMensaje(String mensaje, Color? color) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        mensaje,
        style: TextStyle(color: AppColors.whiteColor),
        textAlign: TextAlign.center,
      ),
      duration: Duration(seconds: 2),
      //behavior: SnackBarBehavior.floating,
      //margin: EdgeInsets.only(bottom: 50, right: 50, left: 50),
      backgroundColor: color,
    ));
  }

  Widget _dropdownRutas(double width) {
    List<DropdownMenuItem<String>> items = [];
    items = getOpcionesDropdownRutas(width);

    return Container(
      //padding: const EdgeInsets.only(left: 10),.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      //LO COMENTADO ES PARA QUE CUANDO ABRA SELECTOR SE HAGA EN ANCHO COMPLETO
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          //key: _keyOrigenes,
          value: _opcionSeleccionadaRuta,
          items: items,
          hint: const Text('---'),
          iconSize: 25,
          isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
          //isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
          onChanged: (value) {
            if (value != '-1') {
              setState(() {
                _opcionSeleccionadaRuta = value.toString();
              });
            }
          },
        ),
      ),
    );
  }

  //TODO: FINALIZAR VIAJE FORZANDO

  Widget TextButonFinalizarViaje(BuildContext context, Viaje viaje) {
    return TextButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) return AppColors.lightBlue;
          return AppColors.whiteColor;
        }),
        backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) return AppColors.blueDarkColor;
          return AppColors.mainBlueColor;
        }),
      ),
      onPressed: () async {
        ViajeServicio viajeServicio = ViajeServicio();
        print(viaje.nroViaje);
        print(viaje.codOperacion);
        String mensaje = await viajeServicio.finalizarViajeForzado(viaje.nroViaje, viaje.codOperacion, Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc, Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc, '${viaje.FechaLlegada} ${viaje.HoraLLegada}:00');

        print(mensaje);
        switch (mensaje) {
          case '0':
            _mostrarMensaje('Viaje finalizado correctamente', AppColors.greenColor);

            String rutaSeleccionada = _opcionSeleccionadaRuta;
            String fechaSeleccionada = DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);
            ViajeServicio servicio = new ViajeServicio();
            setState(() {
              _mostrarCarga = true;
            });
            List<Viaje> viajesBusqueda = await servicio.obtenerViajesNoFinalizados(_usuario.codOperacion, rutaSeleccionada, fechaSeleccionada);
            setState(() {
              _viajesEncontrados = viajesBusqueda;
              _mostrarCarga = false;
            });

            break;
          case '1':
            _mostrarMensaje('El viaje ya se encuentra finalizado', AppColors.redColor);
            break;
          case '2':
            _mostrarMensaje('No se encontró el viaje', AppColors.redColor);

            break;
          case '3':
            _mostrarMensaje('ERROR No se recibió ningún numero de viaje', AppColors.redColor);

            break;
          case '4':
            _mostrarMensaje('Fecha incorrecta', AppColors.redColor);

            break;
        }
      },
      child: Text(
        "Finalizar Viaje",
      ),
    );
  }
}

class CardViaje extends StatelessWidget {
  final Viaje viaje;
  const CardViaje({super.key, required this.viaje});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        //leading: FlutterLogo(size: 72.0),
        title: Container(
          alignment: Alignment.centerLeft,
          height: 25,
          child: FittedBox(
            child: Text(
              "Unidad: " + viaje.unidad,
              //pasajero.apellidos + ", " + pasajero.nombres,
              style: TextStyle(color: AppColors.greenColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(viaje.origen + " - " + viaje.destino),
                Spacer(),
                //Text(pasajero.lugarDesembarque),
              ],
            ),
            Container(
              alignment: Alignment.centerLeft,
              height: 25,
              child: FittedBox(
                child: Text(
                  viaje.fechaSalida + " " + viaje.horaSalida,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
