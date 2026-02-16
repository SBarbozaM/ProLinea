import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/warning_widget_internet.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../main.dart';
import '../../models/usuario.dart';
import '../../utils/responsive_widget.dart';

class ViajeDomicilioEmbarquePage extends StatefulWidget {
  const ViajeDomicilioEmbarquePage({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioEmbarquePage> createState() => _ViajeDomicilioEmbarquePageState();
}

class _ViajeDomicilioEmbarquePageState extends State<ViajeDomicilioEmbarquePage> {
  bool _mostrarCarga = false;
  //String _opcionSeleccionadaEmbarquePasajero = "-1";
  late Timer _timer;
  late Usuario _usuario;

  final player = AudioPlayer();

  late NavigatorState _navigator;
  bool _cambioDependencia = false;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _timer = new Timer.periodic(Duration(seconds: 10), (timer) {
      Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilio(_usuario.tipoDoc, _usuario.numDoc, context);
      setState(() {});
      //actualizar los datos del viaje cada 10 segundos
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    setState(() {
      _cambioDependencia = true;
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'es';
    initializeDateFormatting();

    /*String estadoInternet = internetChecker.internet;*/
    ViajeDomicilio _viaje = Provider.of<DomicilioProvider>(context).viaje;

    double width = MediaQuery.of(context).size.width;
    //double espacioCabecera = estadoInternet == "online" ? 50 : 20;

    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(Duration(seconds: 1), () async {
            await Provider.of<DomicilioProvider>(context, listen: false).sincronizarNuevosPasajerosDomicilio(_usuario.tipoDoc, _usuario.numDoc, context);

            setState(() {
              //_opcionSeleccionadaEmbarqueViaje = "-1";
            });
          });
        },
        child: Scaffold(
          body: ModalProgressHUD(
            opacity: 0.0,
            color: AppColors.whiteColor,
            progressIndicator: const CircularProgressIndicator(
              color: AppColors.mainBlueColor,
            ),
            inAsyncCall: _mostrarCarga,
            child: GestureDetector(
              onTap: () => hideKeyboard(context),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      child: Column(
                        children: [
                          //color: AppColors.backColor,
                          Container(
                            decoration: BoxDecoration(color: AppColors.mainBlueColor, boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 1.0, offset: Offset(0.0, 0.75))]),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 60,
                                ),
                                //TITULO
                                ResponsiveWidget.isSmallScreen(context) ? _tituloSmallScreen(width) : _tituloLargeScreen(),

                                //INFORMACION DEL VIAJE
                                _informacionViaje(_viaje, width),
                                const SizedBox(
                                  height: 5,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),
                          //LISTA DE PASAJEROS
                          Container(
                            padding: EdgeInsets.only(left: 25, right: 25),

                            //color: AppColors.lightGreenColor,
                            child: Column(children: _listaWidgetPasajeros(_viaje)),
                          ),

                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  WarningWidgetInternet(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  hideKeyboard(BuildContext context) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  _tituloLargeScreen() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'EMBARQUE DE PASAJEROS',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppColors.whiteColor),
        ),
        SizedBox(
          width: 10,
        ),
        //_puntosEmbarqueViaje(),
      ],
    );
  }

  _tituloSmallScreen(double width) {
    return Column(
      children: [
        Container(
          width: width * 0.8,
          child: FittedBox(
            child: Text(
              'EMBARQUE DE PASAJEROS',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor),
            ),
          ),
        ),
      ],
    );
  }

  _informacionViaje(ViajeDomicilio _viaje, double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: width * 0.05,
            ),
            Column(
              children: [
                Container(
                  //color: AppColors.greenColor,
                  height: 45,
                  width: width * 0.3,
                  child: FittedBox(
                    child: Text(
                      _viaje.origen,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.turquesaLinea),
                    ),
                  ),
                ),
                /*Container(
                  height: 25,
                  width: width * 0.3,
                  child: FittedBox(
                    child: Text(
                      "ORIGEN",
                    ),
                  ),
                ),*/
              ],
            ),
            SizedBox(
              width: width * 0.05,
            ),
            Container(
              //color: AppColors.blueColor,
              height: 45,
              width: width * 0.2,
              child: FittedBox(
                child: const Icon(Icons.double_arrow, color: AppColors.whiteColor //AppColors.mainBlueColor,
                    ),
              ),
            ),
            SizedBox(
              width: width * 0.05,
            ),
            Column(
              children: [
                Container(
                  //color: AppColors.redColor,
                  height: 45,
                  width: width * 0.3,
                  child: FittedBox(
                    child: Text(
                      _viaje.destino,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.turquesaLinea),
                    ),
                  ),
                ),
                /*Container(
                  height: 25,
                  width: width * 0.3,
                  child: FittedBox(
                    child: Text(
                      "DESTINO",
                    ),
                  ),
                ),*/
              ],
            ),
            SizedBox(
              width: width * 0.05,
            ),
          ],
        ),
        const SizedBox(
          height: 0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: width * 0.01,
            ),
            Text(
              "Fecha: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              _viaje.fechaSalida,
              style: TextStyle(fontSize: 18, color: AppColors.turquesaLinea),
            ),
            SizedBox(
              width: 22.5,
            ),
            Text(
              "Hora: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              _viaje.horaSalida,
              style: TextStyle(fontSize: 18, color: AppColors.turquesaLinea),
            ),
            SizedBox(
              width: width * 0.01,
            ),
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Unidad: ",
              style: TextStyle(fontSize: 18, color: AppColors.whiteColor),
            ),
            Text(
              _viaje.unidad,
              style: TextStyle(fontSize: 18, color: AppColors.turquesaLinea),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Capac: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              _viaje.cantAsientos.toString(),
              style: TextStyle(fontSize: 18, color: AppColors.lightBlue, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: width * 0.05,
            ),
            Text(
              "Embarcados: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              //calcularAsientosDisponibles(_viaje).toString(),
              calcularCantidadEmbarcados(_viaje).toString(),
              style: TextStyle(fontSize: 18, color: calcularCantidadEmbarcados(_viaje) > 0 ? AppColors.lightGreenColor : AppColors.lightRedColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  int calcularAsientosDisponibles(ViajeDomicilio viaje) {
    int cantPasajeros = viaje.pasajeros.length;
    return viaje.cantAsientos - cantPasajeros;
  }

  int calcularCantidadEmbarcados(ViajeDomicilio viaje) {
    int cantEmbarcados = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 1) {
        cantEmbarcados++;
      }
    }

    return cantEmbarcados;
  }

  _playSuccessSound() {
    player.play(AssetSource('sounds/success_sound.mp3'));
  }

  /*_playErrorSound() {
    player.play(AssetSource('sounds/error_sound2.mp3'));
  }

  _playBeepSound() {
    player.play(AssetSource('sounds/beep_sound.mp3'));
  }*/

  List<Widget> _listaWidgetPasajeros(ViajeDomicilio viaje) {
    List<Widget> lista = [];

    List<PasajeroDomicilio> _pasajeros = viaje.pasajeros;

    if (_pasajeros.isEmpty) {
      lista.add(
        Card(
          child: ListTile(
            title: Text('No hay pasajeros para mostrar'),
          ),
        ),
      );
    } else {
      for (int i = 0; i < _pasajeros.length; i++) {
        lista.add(_cardWidget(_pasajeros[i]));
      }

      if (lista.isEmpty) {
        lista.add(
          Card(
            child: ListTile(
              title: Text(
                'No hay pasajeros para mostrar',
              ),
            ),
          ),
        );
      }
    }

    return lista;
  }

  _cardWidget(PasajeroDomicilio pasajero) {
    Color color = AppColors.blackColor;
    bool mostrarIcono = false;
    Widget icono = Icon(Icons.bus_alert);

    bool puedeRegistrarLlegada = false;
    bool puedeEmbarcar = false;
    if (pasajero.tocaRecojo && pasajero.embarcado == 2) {
      if (pasajero.fechaArriboUnidad == "") {
        puedeRegistrarLlegada = true;
        color = AppColors.mainBlueColor;
        icono = ImageIcon(
          AssetImage('assets/icons/route_alt.png'),
          color: color,
          size: 50,
        );
        /*Icon(
          Icons.emoji_transportation,
          color: color,
          size: 50,
        );*/
      } else {
        puedeEmbarcar = true;
        color = AppColors.darkTurquesa;

        icono = Icon(
          Icons.person_pin_circle,
          color: color,
          size: 50,
        ); /*ImageIcon(
          AssetImage('assets/icons/car_punto.png'),
          color: color,
          size: 50,
        );*/
      }
      mostrarIcono = true;
    } else if (!pasajero.tocaRecojo && pasajero.embarcado != 2) {
      color = AppColors.greyColor;
      if (pasajero.embarcado == 0) {
        mostrarIcono = true;
        icono = ImageIcon(
          AssetImage('assets/icons/person_not_check.png'),
          color: color,
          size: 50,
        );
      }

      if (pasajero.embarcado == 1) {
        mostrarIcono = true;
        icono = ImageIcon(
          AssetImage('assets/icons/person_check.png'),
          color: color,
          size: 50,
        );
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
          contentPadding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
          //horizontalTitleGap: 10,
          leading: !mostrarIcono ? null : icono,
          title: Container(
            alignment: Alignment.centerLeft,
            height: 30,
            child: FittedBox(
              child: Text(
                pasajero.nombres.toUpperCase(),
                //pasajero.apellidos + ", " + pasajero.nombres,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pasajero.horaRecojo,
                style: TextStyle(
                  fontSize: 25,
                  color: color,
                ),
              ),
              Text(
                "Dirección: " + pasajero.direccion,
              ),
              Text(
                "Distrito: " + pasajero.distrito,
              ),
            ],
          ),

          //trailing: Icon(Icons.more_vert),
          //isThreeLine: true,
          onTap: () {
            //_modalEmbarque_Desembarque(pasajero, pasajero.embarcado.toString());
            if (pasajero.embarcado == 2 && pasajero.fechaArriboUnidad != "" && puedeEmbarcar) _modalSubio(pasajero, "0").show();
            if (pasajero.embarcado == 2 && pasajero.fechaArriboUnidad == "" && puedeRegistrarLlegada) _modalLlegoConductor(pasajero).show();
          }),
    );
  }

  AwesomeDialog _modalSubio(PasajeroDomicilio pasajero, String estado) {
    String titulo = "¿SUBIÓ?";
    String cuerpo = pasajero.nombres;

    return AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      //customHeader: null,
      animType: AnimType.topSlide,
      //showCloseIcon: true,
      title: titulo,
      desc: cuerpo,
      reverseBtnOrder: true,
      buttonsTextStyle: TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        await cambiarEstadoEmbarque(pasajero, "0");
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () async {
        await cambiarEstadoEmbarque(pasajero, "1");
      },
    );
  }

  AwesomeDialog _modalLlegoConductor(PasajeroDomicilio pasajero) {
    String titulo = "PUNTO DE RECOJO";
    String cuerpo = "¿Ha llegado al punto de recojo del pasajero " + pasajero.nombres + "?";

    return AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      //customHeader: null,
      animType: AnimType.topSlide,
      //showCloseIcon: true,
      title: titulo,
      desc: cuerpo,
      reverseBtnOrder: true,
      buttonsTextStyle: TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        if (pasajero.embarcado == 2 && pasajero.fechaArriboUnidad == "") await registrarFechaArriboUnidad(pasajero);
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }
  //embarcarpasajero
  Future<void> cambiarEstadoEmbarque(PasajeroDomicilio pasajero, String estado) async {
    int nuevoEstado = 1;
    if (estado == "0") {
      nuevoEstado = 1;
    } else {
      if (estado == "1") {
        nuevoEstado = 0;
      }
    }

    ViajeDomicilio _viajeProvider = await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].tipoDoc == pasajero.tipoDoc && _viajeProvider.pasajeros[i].numDoc == pasajero.numDoc && _viajeProvider.pasajeros[i].embarcado != nuevoEstado) {
          String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

          _viajeProvider.pasajeros[i].embarcado = nuevoEstado;
          _viajeProvider.pasajeros[i].fechaEmbarque = fechaHoraEmb;
          _viajeProvider.pasajeros[i].modificado = 0;

          setState(() {
            _mostrarCarga = true;
          });
          String rpta = await servicio.cambiarEstadoEmbarquePasajeroDomicilio(_viajeProvider.pasajeros[i], _viajeProvider.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());
          setState(() {
            _mostrarCarga = false;
          });

          switch (rpta) {
            case "0":
              _viajeProvider.pasajeros[i].modificado = 1;
              break;
            case "1":
              /* Eliminamos del provider y de la bd local */
              /*await AppDatabase.instance
                  .eliminarPasajero(_viajeProvider.pasajeros[i]);*/
              _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);
              _mostrarMensaje("El pasajero ya no se encuentra en la lista", AppColors.redColor);
              break;
            case "2":
            case "9":
              datosPorSincronizar = true;
              _viajeProvider.pasajeros[i].modificado = 0;
              break;
            default:
          }

          _modalSubioRespuesta(estado, _viajeProvider.pasajeros[i]); //Sin embarcar -> Embarcar automaticamente

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viajeProvider.pasajeros[i]);
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();
          setState(() {});
          break;
        }
      }
    } else {
      _mostrarMensaje('No existen pasajeros', null);
    }
  }
  //arribo-gps
  Future<void> registrarFechaArriboUnidad(PasajeroDomicilio pasajero) async {
    ViajeDomicilio _viajeProvider = await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].tipoDoc == pasajero.tipoDoc && _viajeProvider.pasajeros[i].numDoc == pasajero.numDoc && _viajeProvider.pasajeros[i].embarcado == 2 && _viajeProvider.pasajeros[i].fechaArriboUnidad == "") {
          String fechaHoraArribo = DateFormat.yMd().add_Hms().format(new DateTime.now());

          _viajeProvider.pasajeros[i].fechaArriboUnidad = fechaHoraArribo;
          _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;

          if (_viajeProvider.pasajeros[i].coordenadas == "" || _viajeProvider.pasajeros[i].coordenadas.trim() == "0, 0") {
            Position posicionActualGPS = await Geolocator.getCurrentPosition();
            String posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
            _viajeProvider.pasajeros[i].coordenadas = posicionActual;
          }

          setState(() {
            _mostrarCarga = true;
          });
          String rpta = await servicio.registrarFechaLlegadaUnidadDomicilio(_viajeProvider.pasajeros[i], _viajeProvider.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());
          setState(() {
            _mostrarCarga = false;
          });

          switch (rpta) {
            case "0":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              _mostrarModalLlegadaRegistrada('REGISTRADO', 'Hora de arribo registrada', true).show();

              break;
            case "1":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              _mostrarModalLlegadaRegistrada('ERROR', 'Ya existe una hora de arribo registrada', false).show();
              break;
            case "2":
              break;
            case "3":
            case "9":
              _mostrarModalLlegadaRegistrada('', 'Hora de arribo registrada', true).show();
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;
              datosPorSincronizar = true;
              break;
            default:
          }

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viajeProvider.pasajeros[i]);
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();
          setState(() {});
          break;
        }
      }
    } else {
      _mostrarMensaje('No existen pasajeros', null);
    }
  }

  _mostrarMensaje(String mensaje, Color? color) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        mensaje,
        style: TextStyle(color: AppColors.whiteColor),
        textAlign: TextAlign.center,
      ),
      duration: Duration(seconds: 2),
      backgroundColor: color,
    ));
  }

  _modalSubioRespuesta(String accion, PasajeroDomicilio pasajero) {
    String cuerpo = "";
    String titulo = "";
    bool success = false;
    switch (accion) {
      case "0":
        titulo = "Embarcado";
        cuerpo = pasajero.nombres;
        success = true;
        break;
      case "1":
        titulo = "No Embarcado";
        cuerpo = pasajero.nombres;
        success = false;
        break;
    }

    return _mostrarModalSubioRespuesta(titulo, cuerpo, success).show();
  }

  AwesomeDialog _mostrarModalSubioRespuesta(String titulo, String cuerpo, bool success) {
    _playSuccessSound();

    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, showCloseIcon: true, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 3));
  }

  AwesomeDialog _mostrarModalLlegadaRegistrada(String titulo, String cuerpo, bool success) {
    _playSuccessSound();

    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, showCloseIcon: true, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 3));
  }
}
