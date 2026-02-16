import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/warning_widget_internet.dart';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/paradero.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../main.dart';
import '../../models/usuario.dart';
import '../../models/viaje_domicilio/parada.dart';
import '../../utils/app_varios.dart';
import '../../utils/responsive_widget.dart';

class ViajeDomicilioEmbarqueRecojoPage extends StatefulWidget {
  const ViajeDomicilioEmbarqueRecojoPage({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioEmbarqueRecojoPage> createState() => _ViajeDomicilioEmbarqueRecojoPageState();
}

class _ViajeDomicilioEmbarqueRecojoPageState extends State<ViajeDomicilioEmbarqueRecojoPage> {
  bool _mostrarCarga = false;
  //String _opcionSeleccionadaEmbarquePasajero = "-1";
  late Timer _timer;
  late Usuario _usuario;
  final player = AudioPlayer();

  late NavigatorState _navigator;
  bool _cambioDependencia = false;
  String _opcionSeleccionadaParadero = "-1";

  bool estaSincronizacionDetenida = false;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _timer = new Timer.periodic(Duration(seconds: 10), (timer) {
      if (!estaSincronizacionDetenida) {
        Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilio(_usuario.tipoDoc, _usuario.numDoc, context);
        setState(() {});
      }
    });
    _actualizarParadas();
    super.initState();
  }

  _actualizarParadas() async {
    await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();
    //setState(() {});
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
    bool esEmbarque = _esEmbarque(_viaje);
    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(Duration(seconds: 1), () async {
            // var viajeServicio = new ViajeServicio();

            // ViajeDomicilio viaje;

            // viaje =
            //     await viajeServicio.obtenerViajeVinculadoDomicilio(_usuario);

            // if (viaje.rpta == "0") {
            //   if (_cambioDependencia) context = _navigator.context;
            //   await Provider.of<DomicilioProvider>(_navigator.context,
            //           listen: false)
            //       .actualizarViaje(viaje);

            //   await Provider.of<DomicilioProvider>(context, listen: false)
            //       .actualizarMarkerMostrar();
            // }

            // await Provider.of<DomicilioProvider>(context, listen: false)
            //     .sincronizarNuevosPasajerosDomicilio(
            //         _usuario.tipoDoc, _usuario.numDoc, context);

            ActualizaViajebajarPantalla(context);

            setState(() {
              //_opcionSeleccionadaEmbarqueViaje = "-1";
            });
          });
        },
        child: Scaffold(
          appBar: AppBar(
            title: ResponsiveWidget.isSmallScreen(context) ? _tituloSmallScreen(width, _viaje, esEmbarque) : _tituloLargeScreen(_viaje, esEmbarque),
            leading: IconButton(
              onPressed: () async {
                Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla de inicio", rpta: "OK");

                Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.whiteColor,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.mainBlueColor,
          ),
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
                                //TITULO
                                // ResponsiveWidget.isSmallScreen(context)
                                //     ? _tituloSmallScreen(
                                //         width, _viaje, esEmbarque)
                                //     : _tituloLargeScreen(_viaje, esEmbarque),

                                //INFORMACION DEL VIAJE
                                _informacionViaje(_viaje, width, esEmbarque),
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
                          _seccionEmbarque(_viaje),

                          // esEmbarque
                          // ? _seccionEmbarque(_viaje)
                          // : _seccionDesembarque(_viaje, width),

                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (esEmbarque == false)
                    Container(
                      alignment: Alignment.center,
                      width: width,
                      height: 45,
                      color: AppColors.mainBlueColor,
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla de inicio", rpta: "OK");

                              Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
                            },
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Recojo Finalizado",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ],
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

  _tituloLargeScreen(ViajeDomicilio _viaje, bool esEmbarque) {
    String text = "RECOJO DE PASAJEROS";
    if (esEmbarque) {
      text = "RECOJO DE PASAJEROS";
    } else {
      text = "DESEMBARQUE DE PASAJEROS";
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: AppColors.whiteColor),
        ),
        SizedBox(
          width: 10,
        ),
        //_puntosEmbarqueViaje(),
      ],
    );
  }

  _tituloSmallScreen(double width, ViajeDomicilio _viaje, bool esEmbarque) {
    String text = "RECOJO DE PASAJEROS";
    if (esEmbarque) {
      text = "RECOJO DE PASAJEROS"; //this
    } else {
      text = "DESEMBARQUE DE PASAJEROS";
    }
    return Column(
      children: [
        Container(
          width: width * 0.8,
          child: FittedBox(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor),
            ),
          ),
        ),
      ],
    );
  }

  _informacionViaje(ViajeDomicilio _viaje, double width, bool esEmbarque) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     SizedBox(
        //       width: width * 0.05,
        //     ),
        //     Column(
        //       children: [
        //         Container(
        //           //color: AppColors.greenColor,
        //           height: 45,
        //           width: width * 0.3,
        //           child: FittedBox(
        //             child: Text(
        //               _viaje.origen,
        //               textAlign: TextAlign.center,
        //               style: TextStyle(color: AppColors.turquesaLinea),
        //             ),
        //           ),
        //         ),
        //         /*Container(
        //           height: 25,
        //           width: width * 0.3,
        //           child: FittedBox(
        //             child: Text(
        //               "ORIGEN",
        //             ),
        //           ),
        //         ),*/
        //       ],
        //     ),
        //     SizedBox(
        //       width: width * 0.05,
        //     ),
        //     Container(
        //       //color: AppColors.blueColor,
        //       height: 45,
        //       width: width * 0.2,
        //       child: FittedBox(
        //         child: const Icon(Icons.double_arrow,
        //             color: AppColors.whiteColor //AppColors.mainBlueColor,
        //             ),
        //       ),
        //     ),
        //     SizedBox(
        //       width: width * 0.05,
        //     ),
        //     // Column(
        //     //   children: [
        //     //     Container(
        //     //       //color: AppColors.redColor,
        //     //       height: 45,
        //     //       width: width * 0.3,
        //     //       child: FittedBox(
        //     //         child: Text(
        //     //           _viaje.destino,
        //     //           textAlign: TextAlign.center,
        //     //           style: TextStyle(color: AppColors.turquesaLinea),
        //     //         ),
        //     //       ),
        //     //     ),
        //     //     /*Container(
        //     //       height: 25,
        //     //       width: width * 0.3,
        //     //       child: FittedBox(
        //     //         child: Text(
        //     //           "DESTINO",
        //     //         ),
        //     //       ),
        //     //     ),*/
        //     //   ],
        //     // ),
        //     SizedBox(
        //       width: width * 0.05,
        //     ),
        //   ],
        // ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hora Llegada: ",
              style: TextStyle(fontSize: 23, color: AppColors.whiteColor),
            ),
            Text(
              _viaje.horaLlegada == "" ? "00:00" : _viaje.horaLlegada,
              style: TextStyle(fontSize: 25, color: AppColors.turquesaLinea),
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
              esEmbarque ? _viaje.horaSalida : _viaje.horaLlegada,
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
            // Text(
            //   "Capac: ",
            //   style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            // ),
            // Text(
            //   _viaje.cantAsientos.toString(),
            //   style: TextStyle(
            //       fontSize: 18,
            //       color: AppColors.lightBlue,
            //       fontWeight: FontWeight.bold),
            // ),
            // SizedBox(
            //   width: width * 0.05,
            // ),
            Row(
              children: [
                Text(
                  "Por Recoger: ",
                  style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                ),
                Text(
                  "${(int.parse(_viaje.pasajeros.length.toString()) - int.parse(calcularCantidadEmbarcados(_viaje).toString()) - int.parse(calcularCantidadNOEmbarcados(_viaje).toString())).abs()}",
                  style: TextStyle(fontSize: 18, color: AppColors.lightBlue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(width: 15),
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

  int calcularCantidadNOEmbarcados(ViajeDomicilio viaje) {
    int cantNOEmbarcados = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 0) {
        cantNOEmbarcados++;
      }
    }

    return cantNOEmbarcados;
  }

  _seccionEmbarque(ViajeDomicilio _viaje) {
    return Container(
      padding: EdgeInsets.only(left: 25, right: 25),

      //color: AppColors.lightGreenColor,
      child: Column(children: _listaWidgetParadas(_viaje)),
    );
  }

  _seccionDesembarque(ViajeDomicilio _viaje, double width) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: width * 0.3,
              height: 30,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: FittedBox(
                child: Text("Desembarque:"),
              ),
            ),
            Container(
              width: width * 0.7,
              padding: const EdgeInsets.only(left: 10, right: 25),
              child: _paraderosViaje(_viaje),
            ),
          ],
        ),
        SizedBox(
          height: 15,
        ),
        Container(
          padding: EdgeInsets.only(left: 25, right: 25),

          //color: AppColors.lightGreenColor,
          child: Column(
            children: _listaWidgetPasajerosEmbarcados(_viaje),
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Center(
          child: ElevatedButton(
            child: Text(
              "Desembarcar",
              style: TextStyle(fontSize: 18),
            ),
            onPressed: () {
              if (_opcionSeleccionadaParadero == "-1")
                _mostrarModalRespuesta("Error", "Debe seleccionar un paradero de desembarque", false).show();
              else {
                if (_contarPasajerosSeleccionados(_viaje) > 0) {
                  _modalDesembarcar(_viaje).show();
                } else {
                  _mostrarModalRespuesta("Error", "No se ha seleccionado ningún pasajero", false).show();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.whiteColor,
              backgroundColor: AppColors.mainBlueColor,
            ),
          ),
        ),
      ],
    );
  }

  bool _esEmbarque(ViajeDomicilio _viaje) {
    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].embarcado == 2) {
        return true;
      }
    }

    return false;
  }

  _playSuccessSound() {
    player.play(AssetSource('sounds/success_sound.mp3'));
  }

  int _contarPasajerosSeleccionados(ViajeDomicilio viaje) {
    int total = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].desEmb == true && viaje.pasajeros[i].fechaDesembarque == "" && viaje.pasajeros[i].embarcado == 1) {
        total++;
      }
    }
    return total;
  }

  Widget _paraderosViaje(ViajeDomicilio viaje) {
    List<DropdownMenuItem<String>> items = [];
    items = getOpcionesDropdownParaderos(viaje);

    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      //LO COMENTADO ES PARA QUE CUANDO ABRA SELECTOR SE HAGA EN ANCHO COMPLETO
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          //key: _keyOrigenes,
          value: _opcionSeleccionadaParadero,
          items: items,
          hint: const Text('Seleccione Paradero'),
          iconSize: 30,
          isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
          //isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
          onChanged: (value) {
            if (value != '-1') {
              setState(() {
                _opcionSeleccionadaParadero = value.toString();
              });
            }
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> getOpcionesDropdownParaderos(ViajeDomicilio viaje) {
    List<DropdownMenuItem<String>> listaParaderos = [];
    List<Paradero> paraderos = [];

    paraderos = viaje.paraderos;
    listaParaderos.add(const DropdownMenuItem<String>(
      value: "-1",
      child: Text(
        "Seleccione Paradero",
      ),
    ));
    if (paraderos.isNotEmpty) {
      for (int i = 0; i < paraderos.length; i++) {
        //0 = abierto y/o no eliminado
        listaParaderos.add(
          DropdownMenuItem(
            child: Text(
              paraderos[i].nombre,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blueColor),
            ),
            value: paraderos[i].id,
          ),
        );
      }
    }

    return listaParaderos;
  }

  /*_playErrorSound() {
    player.play(AssetSource('sounds/error_sound2.mp3'));
  }

  _playBeepSound() {
    player.play(AssetSource('sounds/beep_sound.mp3'));
  }*/

  List<Widget> _listaWidgetParadas(ViajeDomicilio viaje) {
    List<Widget> lista = [];

    List<Parada> _paradas = viaje.paradas;

    if (_paradas.isEmpty) {
      lista.add(
        Card(
          child: ListTile(
            title: Text('No hay paradas para mostrar'),
          ),
        ),
      );
    } else {
      for (int i = 0; i < _paradas.length; i++) {
        if (_paradas[i].estado != "3") {
          lista.add(_cardWidgetParada(_paradas[i], viaje));
        }
      }

      if (lista.isEmpty) {
        lista.add(
          Card(
            child: ListTile(
              title: Text(
                'No hay paradas para mostrar',
              ),
            ),
          ),
        );
      }
    }

    return lista;
  }

  _cardWidgetParada(Parada parada, ViajeDomicilio viaje) {
    Color color = AppColors.blackColor;
    bool mostrarIcono = false;
    Widget icono = Icon(Icons.bus_alert);

    List<PasajeroDomicilio> _pasajeros = viaje.pasajeros;

    List<PasajeroDomicilio> _pasajeroParada = [];
    for (var i = 0; i < _pasajeros.length; i++) {
      if (_pasajeros[i].direccion == parada.direccion && _pasajeros[i].distrito == parada.distrito && _pasajeros[i].horaRecojo == parada.horaRecojo && _pasajeros[i].coordenadas == parada.coordenadas) {
        _pasajeroParada.add(_pasajeros[i]);
      }
    }

    switch (parada.estado) {
      case "0":
        color = AppColors.blackColor;
        mostrarIcono = parada.recojoTaxi == "0" ? false : true;
        icono = ImageIcon(
          AssetImage(parada.recojoTaxi == "0" ? 'assets/icons/route_alt.png' : "assets/icons/car_punto.png"),
          color: (parada.recojoTaxi == "0" ? AppColors.mainBlueColor : Colors.yellow.shade700),
          size: 50,
        );
        break;
      case "1":
        mostrarIcono = true;
        color = AppColors.mainBlueColor;
        icono = ImageIcon(
          AssetImage(parada.recojoTaxi == "0" ? 'assets/icons/route_alt.png' : "assets/icons/car_punto.png"),
          color: (parada.recojoTaxi == "0" ? AppColors.mainBlueColor : Colors.yellow.shade700),
          size: 50,
        );
        break;
      case "2":
        mostrarIcono = true;
        color = AppColors.darkTurquesa;
        icono = Icon(
          Icons.person_pin_circle,
          color: color,
          size: 50,
        );
        break;
      case "3":
        mostrarIcono = true;
        color = AppColors.greyColor;
        icono = Icon(
          Icons.check_rounded,
          color: color,
          size: 50,
        );
        break;
      default:
    }

    return Card(
      elevation: _usuario.vinculacionActiva == "0" ? 0 : 1,
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
            child: Text(
              parada.horaRecojo,
              style: TextStyle(
                fontSize: 33,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: _pasajeroParada
                    .map((e) => Text(
                          '* ${e.nombres}',
                          style: TextStyle(
                            fontSize: 19,
                          ),
                        ))
                    .toList(),
              ),
              Text(
                "${parada.direccion} - ${parada.distrito.toUpperCase()}",
                style: TextStyle(
                  fontSize: 17,
                  color: color,
                ),
              ),
            ],
          ),

          //trailing: Icon(Icons.more_vert),
          //isThreeLine: true,
          onTap: _usuario.vinculacionActiva == "0"
              ? null
              : () async {
                  if (parada.estado == "1") {
                    Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal automatico llego al punto de recojo en la direccion: ${parada.direccion}", rpta: "OK");

                    await _modalLlegoConductor(parada).show();
                  } else if (parada.estado == "2") {
                    await Provider.of<DomicilioProvider>(context, listen: false).actualizarParada(parada);

                    Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla recojo del pasajero en la parada dirección:${parada.direccion}- taxi:${parada.recojoTaxi}", rpta: "OK");
                    estaSincronizacionDetenida = true;
                    final result = await Navigator.pushNamed(context, 'recojo');

                    // Cuando regreses de la pantalla de recojo, restablece estaSincronizacionDetenida
                    if (result == true) {
                      estaSincronizacionDetenida = false;
                    }
                  }
                }),
    );
  }

  List<Widget> _listaWidgetPasajerosEmbarcados(ViajeDomicilio viaje) {
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
        if (_pasajeros[i].embarcado == 1 && _pasajeros[i].fechaDesembarque == "") {
          lista.add(_cardWidgetPasajero(_pasajeros[i]));
        }
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

  _cardWidgetPasajero(PasajeroDomicilio pasajero) {
    Color color = AppColors.blackColor;

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        //horizontalTitleGap: 10,
        leading: Transform.scale(
          scale: 2,
          child: Checkbox(
            checkColor: AppColors.mainBlueColor,
            fillColor: MaterialStateProperty.resolveWith(AppVarios.getColor),
            value: pasajero.desEmb,
            onChanged: (value) {
              setState(() {
                pasajero.desEmb = value!;
              });
            },
          ),
        ),
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
        /*subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [],
        ),*/

        //trailing: Icon(Icons.more_vert),
        //isThreeLine: true,
      ),
    );
  }

  AwesomeDialog _modalLlegoConductor(Parada parada) {
    String titulo = "PUNTO DE RECOJO";
    String cuerpo = "¿Ha llegado a la dirección " + parada.direccion + "?";

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
        await registrarFechaArriboUnidad(parada);
        Provider.of<DomicilioProvider>(context, listen: false).actualizarParada(parada);

        Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla recojo del pasajero en la parada dirección:${parada.direccion}- taxi:${parada.recojoTaxi}", rpta: "OK");
        estaSincronizacionDetenida = true;
        final result = await Navigator.pushNamed(context, 'recojo');

        // Cuando regreses de la pantalla de recojo, restablece estaSincronizacionDetenida
        if (result == true) {
          estaSincronizacionDetenida = false;
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
      // onDismissCallback: (type) {
      // if (type.index == 0) {
      //   Provider.of<DomicilioProvider>(context, listen: false).actualizarParada(parada);

      //   Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla recojo del pasajero en la parada dirección:${parada.direccion}- taxi:${parada.recojoTaxi}", rpta: "OK");

      //   Navigator.pushNamed(context, 'recojo'); //this -- por primera vez
      // }
      // },
    );
  }

  AwesomeDialog _modalDesembarcar(ViajeDomicilio viaje) {
    String titulo = "DESEMBARCAR";
    String cuerpo = "¿Seguro que desea desembarcar a los pasajeros seleccionados?";

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
        await registrarDesembarque(viaje);
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }
  //registrardesembarque-gps
  Future<void> registrarDesembarque(ViajeDomicilio viaje) async {
    String fechaHoraDesemb = DateFormat.yMd().add_Hms().format(new DateTime.now());
    if (viaje.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < viaje.pasajeros.length; i++) {
        if (viaje.pasajeros[i].embarcado == 1 && viaje.pasajeros[i].desEmb == true && viaje.pasajeros[i].fechaDesembarque == "") {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          String posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
          viaje.pasajeros[i].coordenadasParadero = posicionActual;
          viaje.pasajeros[i].fechaDesembarque = fechaHoraDesemb;
          viaje.pasajeros[i].modificado = 2; //2 <-- desembarque
          viaje.pasajeros[i].idDesembarqueReal = _opcionSeleccionadaParadero;

          setState(() {
            _mostrarCarga = true;
          });

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: registra desembarque al pasajero #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "OK");

          String rpta = await servicio.registrarDesembarquePasajeroDomicilio(viaje.pasajeros[i], viaje.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: registra al pasajero #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

          setState(() {
            _mostrarCarga = false;
          });

          viaje.pasajeros[i].desEmb = false;

          switch (rpta) {
            case "0":
              viaje.pasajeros[i].modificado = 1;
              viaje.pasajeros[i].estadoDesem = "1"; //0 <-- desembarque
              break;
            case "1":
              /* Eliminamos del provider y de la bd local */
              /*await AppDatabase.instance
                  .eliminarPasajero(_viajeProvider.pasajeros[i]);*/
              viaje.pasajeros.removeWhere((element) => element.numDoc == viaje.pasajeros[i].numDoc);

              break;
            case "2":
            case "9":
              datosPorSincronizar = true;
              viaje.pasajeros[i].modificado = 2;
              break;
            default:
          }
          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(viaje.pasajeros[i]);
        }
      }

      setState(() {
        _mostrarModalRespuesta("HECHO", "Pasajeros desembarcados", true).show();
      });
    } else {
      _mostrarModalRespuesta('ERROR', 'No existen pasajeros', false);
    }
  }

  Future<void> registrarFechaArriboUnidad(Parada parada) async {
    ViajeDomicilio _viajeProvider = await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    String fechaHoraArribo = DateFormat.yMd().add_Hms().format(new DateTime.now());

    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();

      estaSincronizacionDetenida = true;

      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].direccion.toUpperCase().trim() == parada.direccion.toUpperCase().trim() && _viajeProvider.pasajeros[i].distrito.toUpperCase().trim() == parada.distrito.toUpperCase().trim() && _viajeProvider.pasajeros[i].horaRecojo.toUpperCase().trim() == parada.horaRecojo.toUpperCase().trim() && _viajeProvider.pasajeros[i].coordenadas.toUpperCase().trim() == parada.coordenadas.toUpperCase().trim() && _viajeProvider.pasajeros[i].embarcado == 2) {
          _viajeProvider.pasajeros[i].fechaArriboUnidad = fechaHoraArribo;
          _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;

          if (_viajeProvider.pasajeros[i].coordenadas == "" || _viajeProvider.pasajeros[i].coordenadas.trim() == "0, 0") {
            _viajeProvider.pasajeros[i].coordenadas = posicionActual;
          }

          setState(() {
            _mostrarCarga = true;
          });

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: registra fecha llegada unidad #${_viajeProvider.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "OK");

          String rpta = await servicio.registrarFechaLlegadaUnidadDomicilio(_viajeProvider.pasajeros[i], _viajeProvider.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición:  registra fecha llegada unidad #${_viajeProvider.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

          switch (rpta) {
            case "0":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              break;
            case "1":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              break;
            case "2":
              break;
            case "3":
            case "9":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;
              datosPorSincronizar = true;
              break;
            default:
          }

          //UPDATE BD LOCAL
          int status = await AppDatabase.instance.Update(
            table: "pasajero_domicilio",
            value: _viajeProvider.pasajeros[i].toJsonBDLocal(),
            where: "numDoc = '${_viajeProvider.pasajeros[i].numDoc}' AND nroViaje = '${_viajeProvider.pasajeros[i].nroViaje}'",
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el pasajero con fecha llegada unidad BDLocal #${_viajeProvider.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR->${status}"}");

          await AppDatabase.instance.Update(
            table: "usuario",
            value: {
              "sesionSincronizada": _viajeProvider.pasajeros[i].modificadoFechaArribo == 0 ? 1 : 0,
            },
            where: "numDoc = '${_usuario.numDoc}'",
          );

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viajeProvider.pasajeros[i]);

          setState(() {
            _mostrarCarga = false;
          });
        }
      }

      estaSincronizacionDetenida = false;

      if (parada.coordenadas == '' || parada.coordenadas == '0, 0') {
        parada.coordenadas = posicionActual;
      }

      await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();
      // await _mostrarModalRespuestaRegistro(
      //         'REGISTRADO', 'Hora de arribo registrada', true, parada)
      //     .show();
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

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    if (success) _playSuccessSound();

    return AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.topSlide,
      showCloseIcon: true,
      title: titulo,
      desc: cuerpo,
      autoHide: Duration(seconds: 2),
    );
  }

  AwesomeDialog _mostrarModalRespuestaRegistro(String titulo, String cuerpo, bool success, Parada parada) {
    if (success) _playSuccessSound();

    return AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.topSlide,
      showCloseIcon: true,
      title: titulo,
      desc: cuerpo,
      autoHide: Duration(seconds: 2),
      onDismissCallback: (type) {
        Provider.of<DomicilioProvider>(context, listen: false).actualizarParada(parada);
        estaSincronizacionDetenida = true;
        Navigator.pushNamed(context, 'recojo');
      },
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

  ActualizaViajebajarPantalla(BuildContext context) async {
    Log.insertarLogDomicilio(context: context, mensaje: "Baja la pantalla para actualizar", rpta: "OK");
    Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal SINCRONIZANDO DATOS", rpta: "OK");
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    if (_hayConexion()) //si hay conexion a internet
    {
      List<Map<String, Object?>> ListaViajesLocal = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");

      Log.insertarLogDomicilio(context: context, mensaje: "Si hay conexión a internet", rpta: "OK");

      Log.insertarLogDomicilio(context: context, mensaje: "Cantidad de viajes obtenidos de BDLocal ${ListaViajesLocal.length}", rpta: "OK");

      if (ListaViajesLocal.isNotEmpty) {
        List<Map<String, Object?>> listaViajeDomi = [...ListaViajesLocal];

        for (var i = 0; i < ListaViajesLocal.length; i++) {
          ViajeDomicilio viaje = await ActualizarViajeClicEmbarque(listaViajeDomi[i]);

          Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
        }
      }

      var viajeServicio = new ViajeServicio();

      Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Obtener los viajes del conductor #${_usuario.numDoc} -> PA:obtener_viajes_domicilio_conductor", rpta: "OK");

      final viajes = await viajeServicio.obtenerViajesConductorVinculadoDomicilio(_usuario);

      Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Obtener los viajes del conductor #${_usuario.numDoc} -> PA:obtener_viajes_domicilio_conductor", rpta: "OK");
      var nrosViajes = viajes.map((objeto) => objeto.nroViaje.toString()).join(', ');

      Log.insertarLogDomicilio(context: context, mensaje: "Los viajes obtenidos del conductor son ${nrosViajes}", rpta: "OK");

      if (viajes.isNotEmpty && viajes[0].rpta == "0") {
        await AppDatabase.instance.Eliminar(tabla: "pasajero_domicilio");
        await AppDatabase.instance.Eliminar(tabla: "viaje_domicilio");
        await AppDatabase.instance.Eliminar(tabla: "tripulante");
        await AppDatabase.instance.Eliminar(tabla: "parada");
        await AppDatabase.instance.Eliminar(tabla: "paradero");

        if (_cambioDependencia) context = _navigator.context;

        Log.insertarLogDomicilio(context: context, mensaje: "Limpiamos las tablas (pasajero_domicilio,viaje_domicilio,tripulante,parada,paradero) BDLocal -> TBL:viaje_domicilio", rpta: "OK");

        for (var i = 0; i < viajes.length; i++) {
          int statusv = await AppDatabase.instance.Guardar(tabla: "viaje_domicilio", value: viajes[i].toMapDatabaseLocal()); //27/06/2023 16:53 -- JOHN SAMUEL : GUARDA EL VIAJE DOMICILIO EN BD LOCAL
          Log.insertarLogDomicilio(context: context, mensaje: "Guardar viaje #${viajes[i].nroViaje} BDLocal -> TBL:viaje_domicilio", rpta: "${statusv > 0 ? "OK" : "ERROR->${statusv}"}");

          for (var pasajero in viajes[i].pasajeros) {
            int statusp = await AppDatabase.instance.Guardar(tabla: "pasajero_domicilio", value: pasajero.toJsonBDLocal()); //27/06/2023  -- JOHN SAMUEL : GUARDA EL PASAJERO DOMICILIO EN BD LOCAL
            Log.insertarLogDomicilio(context: context, mensaje: "Guardar pasajero #${pasajero.numDoc} BDLocal -> TBL:pasajero_domicilio", rpta: "${statusp > 0 ? "OK" : "ERROR->${statusp}"}");
          }

          for (var tripulante in viajes[i].tripulantes) {
            int statust = await AppDatabase.instance.Guardar(tabla: "tripulante", value: tripulante.toMapDatabase()); //27/06/2023  -- JOHN SAMUEL : GUARDA EL TRIPULANTE DOMICILIO EN BD LOCAL
            Log.insertarLogDomicilio(context: context, mensaje: "Guardar tripulante #${tripulante.numDoc} BDLocal -> TBL:tripulante", rpta: "${statust > 0 ? "OK" : "ERROR->${statust}"}");
          }

          for (var parada in viajes[i].paradas) {
            int statusp = await AppDatabase.instance.Guardar(tabla: "parada", value: parada.toJson()); //27/06/2023  -- JOHN SAMUEL : GUARDA LA PARADA DOMICILIO EN BD LOCAL
            Log.insertarLogDomicilio(context: context, mensaje: "Guardar parada ${parada.direccion} BDLocal -> TBL:tripulante", rpta: "${statusp > 0 ? "OK" : "ERROR->${statusp}"}");
          }

          for (var paradero in viajes[i].paraderos) {
            int statusprdro = await AppDatabase.instance.Guardar(tabla: "paradero", value: paradero.toJson()); //27/06/2023  -- JOHN SAMUEL : GUARDA LA PARADERO DOMICILIO EN BD LOCAL
            Log.insertarLogDomicilio(context: context, mensaje: "Guardar paradero ${paradero.nombre} BDLocal -> TBL:paradero", rpta: "${statusprdro > 0 ? "OK" : "ERROR->${statusprdro}"}");
          }
        }
        List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio", where: "seleccionado = '1'");

        ViajeDomicilio viajeselecionado = ViajeDomicilio();
        if (listaViajeDomicilio.isEmpty) {
          List<Map<String, Object?>> listaViajesDomicilios = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");

          for (var i = 0; i < listaViajesDomicilios.length; i++) {
            ViajeDomicilio viaje = await ActualizarViajeClicEmbarque(listaViajesDomicilios[i]);

            if (_usuario.viajeEmp.trim() == "") {
              if (_cambioDependencia) context = _navigator.context;
              Navigator.pop(context);

              Log.insertarLogDomicilio(context: context, mensaje: "Discontinuidad con los datos", rpta: "ERROR-> el campo viajeEmp esta vacio");

              _mostrarModalRespuesta("Lo Sentimos", "Error al procesar la consulta. precione en el icono refrescar", false).show();
              return;
            }

            if (viaje.nroViaje == _usuario.viajeEmp) {
              int status = await AppDatabase.instance.Update(
                  table: "viaje_domicilio",
                  value: {
                    "seleccionado": "1",
                  },
                  where: "nroViaje = '${viaje.nroViaje}'");

              Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el viaje seleccionado BDLocal -> TBL:viaje_domicilio", rpta: "${status > 0 ? "OK" : "ERROR->${status}"}");

              viajeselecionado = viaje;
            }
          }
        } else {
          viajeselecionado = ViajeDomicilio.fromJsonMapBDLocal(listaViajeDomicilio[0]);
        }

        await Provider.of<DomicilioProvider>(_navigator.context, listen: false).actualizarViaje(viajeselecionado);

        await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();

        await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();

        Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal SINCRONIZANDO DATOS", rpta: "OK");

        Navigator.pop(context, 'Cancel');
      } else {
        Navigator.pop(context, 'Cancel');

        Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal SINCRONIZANDO DATOS", rpta: "OK");
        Log.insertarLogDomicilio(context: context, mensaje: "No hay conexión a internet", rpta: "OK");

        _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
      }
    } else {
      if (_cambioDependencia) context = _navigator.context;
      Navigator.pop(context);
      Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal SINCRONIZANDO DATOS", rpta: "OK");
      Log.insertarLogDomicilio(context: context, mensaje: "No hay conexión a internet", rpta: "OK");

      _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
    }
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  Future<ViajeDomicilio> ActualizarViajeClicEmbarque(Map<String, dynamic> json) async {
    ViajeDomicilio viaje;
    viaje = ViajeDomicilio.fromJsonMapBDLocal(json);

    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero_domicilio", where: "nroViaje = '${viaje.nroViaje}'");

    List<PasajeroDomicilio> _pasajeros = listaPasajeros.map((e) => PasajeroDomicilio.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaParada = await AppDatabase.instance.Listar(tabla: "parada", where: "nroViaje = '${viaje.nroViaje}'");

    List<Parada> _paradas = listaParada.map((e) => Parada.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaParadero = await AppDatabase.instance.Listar(tabla: "paradero");

    List<Paradero> _paraderos = listaParadero.map((e) => Paradero.fromJsonMap(e)).toList();

    viaje.pasajeros = _pasajeros;
    viaje.paradas = _paradas;
    viaje.paraderos = _paraderos;

    return viaje;
  }
}
