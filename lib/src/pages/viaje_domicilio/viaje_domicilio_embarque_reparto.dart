import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/warning_widget_internet.dart';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:searchfield/searchfield.dart';

import '../../../main.dart';
import '../../models/usuario.dart';
import '../../models/viaje_domicilio/parada.dart';
import '../../models/viaje_domicilio/paradero.dart';
import '../../providers/connection_status_provider.dart';
import '../../services/viaje_servicio.dart';
import '../../utils/app_database.dart';
import '../../utils/responsive_widget.dart';

class ViajeDomicilioEmbarqueRepartoPage extends StatefulWidget {
  const ViajeDomicilioEmbarqueRepartoPage({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioEmbarqueRepartoPage> createState() => _ViajeDomicilioEmbarqueRepartoPageState();
}

class _ViajeDomicilioEmbarqueRepartoPageState extends State<ViajeDomicilioEmbarqueRepartoPage> {
  bool _mostrarCarga = false;
  //String _opcionSeleccionadaEmbarquePasajero = "-1";
  late Timer _timer;
  late Usuario _usuario;
  final player = AudioPlayer();
  String _opcionSeleccionadaParadero = "-1";

  int numDocAuxiliar = 1000;
  final _pasajeroNuevoController = TextEditingController();
  late NavigatorState _navigator;
  bool _cambioDependencia = false;
  //static List<Widget> iconos = AppVarios.iconosEstados;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    // _timer = new Timer.periodic(Duration(seconds: 10), (timer) {
    //   Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioReparto(_usuario.tipoDoc, _usuario.numDoc, context);
    //   setState(() {});
    //   //actualizar los datos del viaje cada 10 segundos vv
    // });
    _actualizarParadas();
    super.initState();
  }

  _actualizarParadas() async {
    await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);
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
    bool repartoIniciado = _repartoIniciado(_viaje);
    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(Duration(seconds: 1), () async {
            ActualizaViajebajarPantalla(context);
            setState(() {});
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
                                // const SizedBox(
                                //   height: 60,
                                // ),
                                //TITULO
                                // ResponsiveWidget.isSmallScreen(context)
                                //     ? _tituloSmallScreen(
                                //         width, _viaje, esEmbarque)
                                //     : _tituloLargeScreen(_viaje, esEmbarque),

                                //INFORMACION DEL VIAJE
                                _informacionViaje(_viaje, width, esEmbarque, repartoIniciado),
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
                          esEmbarque ? _seccionEmbarque(_viaje, width) : _seccionDesembarque(_viaje),

                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (esEmbarque == false && _esRepartoFInalizado(_viaje) == true)
                    Container(
                      alignment: Alignment.center,
                      width: width,
                      height: 45,
                      color: AppColors.mainBlueColor,
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
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
                            "Reparto Finalizado",
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
    String text = "REPARTO DE PASAJEROS";
    /*if (esEmbarque) {
      text = "EMBARQUE DE PASAJEROS";
    } else {
      text = "REPARTO DE PASAJEROS";
    }*/
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
    String text = "REPARTO DE PASAJEROS"; //this
    /*if (esEmbarque) {
      text = "EMBARQUE DE PASAJEROS";
    } else {
      text = "REPARTO DE PASAJEROS";
    }*/
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

  _informacionViaje(ViajeDomicilio _viaje, double width, bool esEmbarque, bool repartoIniciado) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  esEmbarque ? "EMBARQUE" : "REPARTO",
                  style: TextStyle(fontSize: 23, color: AppColors.whiteColor),
                ),
                SizedBox(
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
              ],
            ),
            if (!repartoIniciado)
              TextButton(
                onPressed: () {},
                child: IconButton(
                  icon: const Icon(Icons.person_add),
                  color: AppColors.lightGreenColor,
                  iconSize: 50,
                  tooltip: 'Nuevo Pasajero',
                  onPressed: () {
                    Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal nuevo pasajero", rpta: "OK");

                    _modalNuevoPasajero(_viaje);
                  },
                ),
              ),
          ],
        ),
        const SizedBox(
          height: 0,
        ),
        /*Row(
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
        ),*/
        esEmbarque ? _datosEmbarque(_viaje) : _datosReparto(_viaje)
      ],
    );
  }

  Widget _datosEmbarque(ViajeDomicilio _viaje) {
    int asignados = _viaje.pasajeros.length;
    int embarcados = calcularCantidadEmbarcados(_viaje);
    int noEmbarcados = calcularCantidadNoEmbarcados(_viaje);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              "Asignados: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              asignados.toString(),
              style: TextStyle(fontSize: 18, color: AppColors.lightBlue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(width: 15),
        Row(
          children: [
            Text(
              "Embarcados: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              //calcularAsientosDisponibles(_viaje).toString(),
              embarcados.toString(),
              style: TextStyle(fontSize: 18, color: embarcados > 0 ? AppColors.lightGreenColor : AppColors.lightRedColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(width: 15),
        Row(
          children: [
            Text(
              "No Embarcados: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              //calcularAsientosDisponibles(_viaje).toString(),
              noEmbarcados.toString(),
              style: TextStyle(fontSize: 18, color: noEmbarcados > 0 ? AppColors.lightGreenColor : AppColors.lightRedColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datosReparto(ViajeDomicilio _viaje) {
    int total = calcularCantidadEmbarcados(_viaje);
    int porRepartir = calcularCantidadPorRepartir(_viaje);
    int repartidos = calcularCantidadRepartidos(_viaje);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              "Total: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              total.toString(),
              style: TextStyle(fontSize: 18, color: AppColors.lightBlue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(width: 15),
        Row(
          children: [
            Text(
              "Por Repartir: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              //calcularAsientosDisponibles(_viaje).toString(),
              porRepartir.toString(),
              style: TextStyle(fontSize: 18, color: porRepartir > 0 ? AppColors.lightGreenColor : AppColors.lightRedColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(width: 15),
        Row(
          children: [
            Text(
              "Repartidos: ",
              style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
            ),
            Text(
              //calcularAsientosDisponibles(_viaje).toString(),
              repartidos.toString(),
              style: TextStyle(fontSize: 18, color: repartidos > 0 ? AppColors.lightGreenColor : AppColors.lightRedColor, fontWeight: FontWeight.bold),
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

  int calcularCantidadNoEmbarcados(ViajeDomicilio viaje) {
    int cantNoEmbarcados = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 0) {
        cantNoEmbarcados++;
      }
    }

    return cantNoEmbarcados;
  }

  int calcularCantidadRepartidos(ViajeDomicilio viaje) {
    int cantRepartidos = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 1 && viaje.pasajeros[i].fechaDesembarque != "") {
        cantRepartidos++;
      }
    }

    return cantRepartidos;
  }

  int calcularCantidadPorRepartir(ViajeDomicilio viaje) {
    int cantPorRepartir = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 1 && viaje.pasajeros[i].fechaDesembarque == "") {
        cantPorRepartir++;
      }
    }

    return cantPorRepartir;
  }

  _seccionDesembarque(ViajeDomicilio _viaje) {
    return Container(
      padding: EdgeInsets.only(left: 25, right: 25),

      //color: AppColors.lightGreenColor,
      child: Column(children: _listaWidgetParadas(_viaje)),
    );
  }

  _seccionEmbarque(ViajeDomicilio _viaje, double width) {
    return Column(
      children: [
        /*Row(
          children: [
            Container(
              width: width * 0.3,
              height: 30,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: FittedBox(
                child: Text("Embarque:"),
              ),
            ),
            Container(
              width: width * 0.7,
              padding: const EdgeInsets.only(left: 10, right: 25),
              child: _paraderosViaje(_viaje),
            ),
          ],
        ),*/
        SizedBox(
          height: 15,
        ),
        Container(
          padding: EdgeInsets.only(left: 25, right: 25),

          //color: AppColors.lightGreenColor,
          child: Column(
            children: _listaWidgetPasajerosNoEmbarcados(_viaje),
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Center(
          child: ElevatedButton(
            child: Text(
              "Embarcar", //this
              style: TextStyle(fontSize: 18),
            ),
            onPressed: _contarPasajerosMarcados(_viaje) == 0
                ? null
                : () {
                    if (_contarPasajerosMarcados(_viaje) > 0) {
                      Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal de embarcar pasajeros: Seguro que desea registrar a los pasajeros marcados", rpta: "OK");

                      _modalEmbarcar(_viaje).show();
                    } else {
                      Log.insertarLogDomicilio(context: context, mensaje: "No se ha seleccionado ningún pasajero para registrar", rpta: "ERROR");

                      _mostrarModalRespuesta("Error", "No se ha seleccionado ningún pasajero", false).show();
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

  bool _repartoIniciado(ViajeDomicilio _viaje) {
    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].fechaArriboUnidad != "") {
        return true;
      }
    }

    return false;
  }

  bool _esRepartoFInalizado(ViajeDomicilio _viaje) {
    int cantidadRepartidos = calcularCantidadRepartidos(_viaje);
    int cantidadEmbarcados = calcularCantidadEmbarcados(_viaje);

    if (cantidadRepartidos == cantidadEmbarcados) {
      return true;
    }

    return false;
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
          hint: const Text('---'),
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
        "---",
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

  List<Parada> _paradasPorIr(ViajeDomicilio viaje) {
    List<Parada> paradas = [];

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 1) {
        Parada paradaPasajero = new Parada();
        paradaPasajero.direccion = viaje.pasajeros[i].direccion;
        paradaPasajero.distrito = viaje.pasajeros[i].distrito;
        paradaPasajero.horaRecojo = viaje.pasajeros[i].horaRecojo;
        paradaPasajero.coordenadas = viaje.pasajeros[i].coordenadas;

        paradas.add(paradaPasajero);
      }
    }
    return paradas;
  }

  List<Widget> _listaWidgetParadas(ViajeDomicilio viaje) {
    List<Widget> lista = [];

    List<Parada> _paradas = viaje.paradas;
    List<Parada> _paradasAux = _paradasPorIr(viaje);

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
        bool encontrado = false;
        for (int j = 0; j < _paradasAux.length; j++) {
          if (_paradas[i].direccion.toUpperCase().trim() == _paradasAux[j].direccion.toUpperCase().trim() && _paradas[i].distrito.toUpperCase().trim() == _paradasAux[j].distrito.toUpperCase().trim() && _paradas[i].coordenadas.toUpperCase().trim() == _paradasAux[j].coordenadas.toUpperCase().trim() && _paradas[i].horaRecojo.toUpperCase().trim() == _paradasAux[j].horaRecojo.toUpperCase().trim()) {
            encontrado = true;
            break;
          }
        }
        if (encontrado) {
          if (_paradas[i].estado != "3") lista.add(_cardWidgetParada(_paradas[i], viaje));
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

    List<PasajeroDomicilio> _pasajerosParada = [];
    for (var i = 0; i < _pasajeros.length; i++) {
      if (_pasajeros[i].direccion == parada.direccion && _pasajeros[i].distrito == parada.distrito && _pasajeros[i].horaRecojo == parada.horaRecojo && _pasajeros[i].coordenadas == parada.coordenadas && _pasajeros[i].fechaDesembarque == "") {
        _pasajerosParada.add(_pasajeros[i]);
      }
    }

    switch (parada.estado) {
      case "0":
        color = AppColors.blackColor;
        break;
      case "1":
        mostrarIcono = true;
        color = AppColors.mainBlueColor;
        icono = ImageIcon(
          AssetImage('assets/icons/route_alt.png'),
          color: color,
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

    String textoUbicacion = "";
    if (parada.direccion.trim() != "") {
      textoUbicacion = parada.direccion;
    } else {
      textoUbicacion = "SIN DIRECCIÓN";
    }

    if (parada.distrito.trim() != "") {
      textoUbicacion += " " + parada.distrito;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _pasajerosParada
                    .map((e) => Text(
                          '* ${e.nombres}',
                          style: TextStyle(
                            fontSize: 19,
                          ),
                        ))
                    .toList(),
              ),
              Text(
                textoUbicacion,
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
                    Log.insertarLogDomicilio(context: context, mensaje: "Muestra el modal de llego al PUNTO DE REPARTO", rpta: "OK");
                    _modalLlegoConductor(viaje, parada, _pasajerosParada).show();
                  }
                  if (parada.estado == "2") {
                    await Provider.of<DomicilioProvider>(context, listen: false).actualizarParada(parada);

                    if (_pasajerosParada.length > 1) {
                      Navigator.pushNamed(context, 'reparto');
                    } else {
                      _modalReparto(parada, _pasajerosParada, viaje).show();
                    }
                  }
                }),
    );
  }

  List<Widget> _listaWidgetPasajerosNoEmbarcados(ViajeDomicilio viaje) {
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
        if (_pasajeros[i].embarcado == 2) lista.add(_cardWidgetPasajero(_pasajeros[i])); //&& _pasajeros[i].fechaEmbarque == ""
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
    Widget icono = Icon(Icons.bus_alert);

    switch (pasajero.embarcado) {
      case 0:
        color = AppColors.redColor;

        icono = ImageIcon(
          AssetImage('assets/icons/person_not_check.png'),
          color: color,
          size: 50,
        );
        break;
      case 1:
        color = AppColors.greenColor;

        icono = ImageIcon(
          AssetImage('assets/icons/person_check.png'),
          color: color,
          size: 50,
        );
        break;
      case 2:
        icono = ImageIcon(
          AssetImage('assets/icons/person_time.png'),
          color: color,
          size: 50,
        );
        break;
      default:
    }

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
          contentPadding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
          //horizontalTitleGap: 10,
          leading: icono,
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
          subtitle: pasajero.embarcado == 2
              ? Container(
                  alignment: Alignment.center,
                  child: ToggleButtons(
                    direction: Axis.horizontal, // vertical ? Axis.vertical : Axis.horizontal,
                    onPressed: (int index) {
                      setState(() {
                        // The button that is tapped is set to true, and the others to false.
                        for (int i = 0; i < pasajero.selectedStatus.length; i++) {
                          if (index == i) {
                            pasajero.selectedStatus[i] = true;
                          } else {
                            pasajero.selectedStatus[i] = false;
                          }
                        }

                        if (index == 0) {
                          pasajero.embarcadoAux = 1; //Embarcado
                          pasajero.fechaEmbarque = obtenerFechaFormateada();
                        } else if (index == 1) {
                          pasajero.embarcadoAux = 0; //No embarcado
                          pasajero.fechaEmbarque = "";
                        } else if (index == 2) {
                          pasajero.embarcadoAux = 2; //En espera
                          pasajero.fechaEmbarque = "";
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderColor: Colors.transparent,
                    selectedBorderColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    selectedColor: Colors.black,
                    fillColor: pasajero.embarcadoAux == 1
                        ? AppColors.greenColor
                        : pasajero.embarcadoAux == 0
                            ? AppColors.redColor
                            : AppColors.whiteColor,
                    //color: Colors.blue[400],
                    isSelected: pasajero.selectedStatus,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 75,
                        color: pasajero.embarcadoAux == 1 ? AppColors.whiteColor : AppColors.greenColor,
                      ),
                      Icon(
                        Icons.close_rounded,
                        size: 75,
                        color: pasajero.embarcadoAux == 0 ? AppColors.whiteColor : AppColors.redColor,
                      ),
                      Icon(
                        Icons.replay,
                        size: 40,
                        color: AppColors.mainBlueColor,
                      ),
                    ],
                  ),
                )
              : (pasajero.embarcado == 1)
                  ? Text("Recogido a las " + _obtenerHoraEmbarque(pasajero.fechaEmbarque))
                  : (pasajero.embarcado == 0)
                      ? Text("No recogido")
                      : Text("")

          //trailing: Icon(Icons.more_vert),
          //isThreeLine: true,
          ),
    );
  }

  String obtenerFechaFormateada() {
    DateTime now = DateTime.now();

    String dia = now.day.toString().padLeft(2, '0');
    String mes = now.month.toString().padLeft(2, '0');
    String anio = now.year.toString();

    String hora = now.hour.toString().padLeft(2, '0');
    String minuto = now.minute.toString().padLeft(2, '0');
    String segundo = now.second.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto:$segundo';
  }

  _obtenerHoraEmbarque(String fechaEmbarque) {
    final fechaSplit = fechaEmbarque.split(" ");
    final hora = fechaSplit[1].split(":");

    if (hora[0].length == 1) {
      hora[0] = "0" + hora[0];
    }

    if (hora[1].length == 1) {
      hora[1] = "0" + hora[1];
    }

    final nuevaHora = hora[0] + ":" + hora[1];

    return nuevaHora;
  }

  //TODO
  AwesomeDialog _modalLlegoConductor(ViajeDomicilio _viaje, Parada parada, List<PasajeroDomicilio> pasajeros) {
    String titulo = "PUNTO DE REPARTO";

    String direccion = parada.direccion.trim() == "" ? "de reparto" : parada.direccion.trim();

    String cuerpo = "¿Ha llegado a la dirección ${direccion}?";

    if (pasajeros.length == 1) {
      cuerpo = "Ha llegado a la dirección ${direccion}. ¿Desea desembarcar al pasajero ${pasajeros[0].nombres}?";
    }

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
        Log.insertarLogDomicilio(context: context, mensaje: "Presiona SI", rpta: "OK");
        await registrarFechaArriboUnidad(_viaje, parada);

        if (pasajeros.length == 1) {
          await registrarDesembarque(_viaje, parada);
        } else {
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarParada(parada);

          Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla reparto de pasajeros en el punto", rpta: "OK");

          final result = await Navigator.pushNamed(context, 'reparto');

          if (result != null) {
            // Aquí puedes verificar si algo cambió y actualizar la pantalla
            //ActualizaViajebajarPantalla(context);

            setState(() async {
              await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);
            });
          }
        }
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  AwesomeDialog _modalReparto(Parada parada, List<PasajeroDomicilio> pasajeros, ViajeDomicilio viaje) {
    String titulo = "Desembarque";
    String cuerpo = "";
    bool pasarSiguiente = false;
    if (pasajeros.length == 1) {
      cuerpo = "¿Desea desembarcar a " + pasajeros[0].nombres + "?";
      pasarSiguiente = false;
    } else {
      cuerpo = "¿Desea desembarcar a todos los pasajeros de este punto de acopio?";
      pasarSiguiente = true;
    }

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
        registrarDesembarque(viaje, parada);
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {
        if (pasarSiguiente) {
          Navigator.pushNamed(context, 'reparto');
        }
      },
    );
  }

  AwesomeDialog _modalEmbarcar(ViajeDomicilio viaje) {
    String titulo = "EMBARCAR";
    String cuerpo = "¿Seguro que desea embarcar a los pasajeros seleccionados?";

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
        Log.insertarLogDomicilio(context: context, mensaje: "Presiona SI", rpta: "OK");
        await registrarEmbarque(viaje);
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }
  //embarcarpasajero-gps
  Future<void> registrarEmbarque(ViajeDomicilio _viaje) async {
    PasajeroServicio servicio = new PasajeroServicio();
    String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].embarcadoAux != 2) {
        _viaje.pasajeros[i].coordenadasParadero = posicionActual;

        _viaje.pasajeros[i].embarcado = _viaje.pasajeros[i].embarcadoAux;
        // _viaje.pasajeros[i].fechaEmbarque = fechaHoraEmb;
        _viaje.pasajeros[i].modificado = 0;
        // _viaje.pasajeros[i].embarcadoAux = 2;
        _viaje.pasajeros[i].idEmbarqueReal = "0"; //_opcionSeleccionadaParadero;
        _viaje.pasajeros[i].nuevo = "0";

        setState(() {
          _mostrarCarga = true;
        });

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Embarcar al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "OK");

        String rpta = await servicio.cambiarEstadoEmbarquePasajeroDomicilio_Reparto(_viaje.pasajeros[i], _viaje.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición:Embarcar al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        setState(() {
          _mostrarCarga = false;
        });

        switch (rpta) {
          case "0":
            _viaje.pasajeros[i].modificado = 1;
            break;
          case "-1":
            /* Eliminamos del provider y de la bd local */
            /*await AppDatabase.instance
                  .eliminarPasajero(_viajeProvider.pasajeros[i]);*/
            _viaje.pasajeros.removeWhere((element) => element.numDoc == _viaje.pasajeros[i].numDoc);

            break;
          case "-4": //Cuando el pasajero ya se encuentra registrado en BD y tiene una reserva
            break;
          case "-2":
          case "-3": //Error en la transacción
          case "-9":
            datosPorSincronizar = true;
            _viaje.pasajeros[i].modificado = 0;
            break;
          default:
        }

        int status = await AppDatabase.instance.Update(
          table: "pasajero_domicilio",
          value: _viaje.pasajeros[i].toJsonBDLocal(),
          where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
        );

        Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

        //Actualizamos la variable provider de viaje
        //await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viaje.pasajeros[i]);
        /*await Provider.of<DomicilioProvider>(context, listen: false)
              .actualizarMarkerMostrar();*/
      }
    }

    await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);

    setState(() async {});
  }

  int _contarPasajerosMarcados(ViajeDomicilio _viaje) {
    int total = 0;
    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].embarcadoAux != 2) {
        total++;
      }
    }
    return total;
  }
  //registrarfechaarribounidad-gps
  Future<void> registrarFechaArriboUnidad(ViajeDomicilio _viaje, Parada parada) async {
    String fechaHoraArribo = DateFormat.yMd().add_Hms().format(new DateTime.now());

    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    if (_viaje.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < _viaje.pasajeros.length; i++) {
        if (_viaje.pasajeros[i].direccion.toUpperCase().trim() == parada.direccion.toUpperCase().trim() && _viaje.pasajeros[i].distrito.toUpperCase().trim() == parada.distrito.toUpperCase().trim() && _viaje.pasajeros[i].coordenadas.toUpperCase().trim() == parada.coordenadas.toUpperCase().trim() && _viaje.pasajeros[i].horaRecojo.toUpperCase().trim() == parada.horaRecojo.toUpperCase().trim() && _viaje.pasajeros[i].embarcado == 1) {
          _viaje.pasajeros[i].fechaArriboUnidad = fechaHoraArribo;
          _viaje.pasajeros[i].modificadoFechaArribo = 0;

          if (_viaje.pasajeros[i].coordenadas == "" || _viaje.pasajeros[i].coordenadas.trim() == "0, 0") {
            _viaje.pasajeros[i].coordenadas = posicionActual;
          }

          switch (_viaje.pasajeros[i].nuevo) {
            //0: El pasajero ya tenia su reserva
            //3: Es pasajero nuevo con reserva nueva ya registrada
            case "0":
              setState(() {
                _mostrarCarga = true;
              });

              Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Registra la fecha llegada unidad domicilio #${_viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "OK");

              String rpta = await servicio.registrarFechaLlegadaUnidadDomicilio(_viaje.pasajeros[i], _viaje.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

              Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Registra la fecha llegada unidad domicilio  #${_viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

              setState(() {
                _mostrarCarga = false;
              });

              switch (rpta) {
                case "0":
                  _viaje.pasajeros[i].modificadoFechaArribo = 1;
                  break;
                case "1":
                  _viaje.pasajeros[i].modificadoFechaArribo = 1;
                  break;
                case "2":
                  break;
                case "3":
                case "9":
                  _viaje.pasajeros[i].modificadoFechaArribo = 0;
                  datosPorSincronizar = true;
                  break;
                default:
              }
              break;
          }

          int status = await AppDatabase.instance.Update(
            table: "pasajero_domicilio",
            value: _viaje.pasajeros[i].toJsonBDLocal(),
            where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

          //Actualizamos la variable provider de viaje
          //await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viajeProvider.pasajeros[i]);
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();
        }
      }

      if (parada.coordenadas == "" || parada.coordenadas == "0, 0") {
        parada.coordenadas = posicionActual;
      }

      await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);
      //_mostrarModalRespuesta('REGISTRADO', 'Hora de arribo registrada', true).show();
    } else {
      Log.insertarLogDomicilio(context: context, mensaje: "Modal mensaje no existen pasajeros", rpta: "OK");

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
    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, showCloseIcon: true, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 3));
  }

  _modalNuevoPasajero(ViajeDomicilio viaje) {
    List<PasajeroDomicilio> posiblesPasajeros = Provider.of<DomicilioProvider>(context, listen: false).posiblesPasajeros;

    PasajeroDomicilio nuevoPasajero = new PasajeroDomicilio();
    PasajeroDomicilio pasajeroTap = new PasajeroDomicilio();
    String textoError = "";

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (stfContext, stfSetState) {
            return Dialog(
              insetPadding: EdgeInsets.all(15),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                          margin: EdgeInsets.only(top: 10, left: 15, right: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "NUEVO PASAJERO",
                                style: TextStyle(fontSize: 25, color: AppColors.mainBlueColor),
                              ),
                              InkWell(
                                child: Icon(
                                  Icons.close,
                                  size: 30,
                                  color: AppColors.mainBlueColor,
                                ),
                                onTap: () {
                                  Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal nuevo pasajero", rpta: "OK");

                                  Navigator.pop(context);
                                },
                              )
                            ],
                          )),
                      Container(
                        margin: EdgeInsets.only(top: 10, left: 15, right: 15),
                        child: SearchField<PasajeroDomicilio>(
                          suggestions: posiblesPasajeros
                              .map(
                                (e) => SearchFieldListItem<PasajeroDomicilio>(
                                  e.nombres,
                                  item: e,
                                  // Use child to show Custom Widgets in the suggestions
                                  // defaults to Text widget
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        /*CircleAvatar(
                                          backgroundImage: NetworkImage(e.flag),
                                        ),*/
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(e.nombres),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          suggestionDirection: SuggestionDirection.up,
                          controller: _pasajeroNuevoController,
                          onSubmit: (pasajeroNuevo) {},
                          onSuggestionTap: (pasajero) {
                            if (pasajero.item != null) {
                              pasajeroTap = pasajero.item!;
                            }
                          },
                        ),
                      ),
                      if (textoError != "")
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          child: Text(
                            textoError,
                            style: TextStyle(color: AppColors.redColor),
                          ),
                        ),
                      Container(
                        margin: EdgeInsets.only(top: 10, bottom: 10),
                        child: ElevatedButton(
                          child: Text(
                            "Embarcar",
                            style: TextStyle(fontSize: 18),
                          ),
                          onPressed: () async {
                            String texto = _pasajeroNuevoController.text.trim();
                            if (texto == "") {
                              Log.insertarLogDomicilio(context: context, mensaje: "Ingrese el nombre del pasajero", rpta: "ERROR");

                              stfSetState(() {
                                textoError = "Ingrese el nombre del pasajero";
                              });
                              return;
                            } else {
                              bool registrado = false;

                              //Si hizo tap y el nombre del pasajero es el mismo que el del controller entonces no es nuevo pasajero
                              if (pasajeroTap.tipoDoc != "" && pasajeroTap.numDoc != "" && pasajeroTap.nombres == texto) {
                                nuevoPasajero.tipoDoc = pasajeroTap.tipoDoc;
                                nuevoPasajero.numDoc = pasajeroTap.numDoc;
                                nuevoPasajero.nombres = pasajeroTap.nombres;
                                nuevoPasajero.direccion = pasajeroTap.direccion;
                                nuevoPasajero.distrito = pasajeroTap.distrito;
                                nuevoPasajero.coordenadas = pasajeroTap.coordenadas == "0, 0" ? "" : pasajeroTap.coordenadas;
                                nuevoPasajero.nuevo = "2";
                                registrado = _yaRegistrado(1, viaje, nuevoPasajero);
                              } else {
                                nuevoPasajero.nombres = texto;
                                nuevoPasajero.tipoDoc = 'DNI';
                                nuevoPasajero.numDoc = "A" + numDocAuxiliar.toString();
                                nuevoPasajero.nuevo = "1";
                                nuevoPasajero.direccion = "";
                                nuevoPasajero.distrito = "";
                                nuevoPasajero.coordenadas = "";
                                numDocAuxiliar++;
                                registrado = _yaRegistrado(2, viaje, nuevoPasajero);
                              }

                              if (!registrado) {
                                nuevoPasajero.nroViaje = viaje.nroViaje;
                                nuevoPasajero.embarcado = 1;
                                nuevoPasajero.horaRecojo = viaje.horaLlegada;
                                nuevoPasajero.asiento = "1";
                                nuevoPasajero.nombres = nuevoPasajero.nombres.toUpperCase();

                                Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal ¿Seguro que desea embarcar al pasajero ${nuevoPasajero.nombres}", rpta: "OK");

                                _modalEmbarcarNuevoPasajero(viaje, nuevoPasajero).show();
                              } else {
                                Log.insertarLogDomicilio(context: context, mensaje: "Ya se encuentra en la lista de pasajeros", rpta: "ERROR");

                                stfSetState(() {
                                  textoError = "Ya se encuentra en la lista de pasajeros";
                                });
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
                  ),
                ),
              ),
            );
          });
        }).then((value) {
      _pasajeroNuevoController.text = "";
    });
  }

  bool _yaRegistrado(int tipo, ViajeDomicilio viaje, PasajeroDomicilio pasajeroBuscar) {
    //Tipo 1: Verificar por tipo y numero de documento
    if (tipo == 1) {
      for (int i = 0; i < viaje.pasajeros.length; i++) {
        if (viaje.pasajeros[i].tipoDoc.trim() == pasajeroBuscar.tipoDoc.trim() && viaje.pasajeros[i].numDoc.trim() == pasajeroBuscar.numDoc.trim()) {
          return true;
        }
      }
    }

    //Tipo 2: Verificar por nombre
    if (tipo == 2) {
      for (int i = 0; i < viaje.pasajeros.length; i++) {
        if (viaje.pasajeros[i].nombres.toUpperCase().trim() == pasajeroBuscar.nombres.toUpperCase().trim()) {
          return true;
        }
      }
    }

    return false;
  }
  //embarcarpasajero-gps
  Future<void> registrarEmbarqueNuevoPasajero(ViajeDomicilio _viaje, PasajeroDomicilio nuevoPasajero) async {
    PasajeroServicio servicio = new PasajeroServicio();
    String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

    await Provider.of<DomicilioProvider>(context, listen: false).addNuevoPasajeroReparto(context, nuevoPasajero);

    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].tipoDoc == nuevoPasajero.tipoDoc && _viaje.pasajeros[i].numDoc == nuevoPasajero.numDoc) {
        _viaje.pasajeros[i].coordenadasParadero = posicionActual;

        _viaje.pasajeros[i].embarcado = 1;
        _viaje.pasajeros[i].fechaEmbarque = fechaHoraEmb;
        _viaje.pasajeros[i].modificado = 0;
        _viaje.pasajeros[i].embarcadoAux = 2;
        _viaje.pasajeros[i].idEmbarqueReal = "0"; //_opcionSeleccionadaParadero;

        setState(() {
          _mostrarCarga = true;
        });

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Embarcar al nuevo pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "OK");

        String rpta = await servicio.cambiarEstadoEmbarquePasajeroDomicilio_Reparto(_viaje.pasajeros[i], _viaje.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición:Embarcar al nuevo pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        setState(() {
          _mostrarCarga = false;
        });

        String nuevoNumDoc = "";
        String rptaAux = "";
        if (rpta[0] == '0') {
          rptaAux = '0';
        } else {
          rptaAux = rpta;
        }

        switch (rptaAux) {
          case "0":
            //Si es nuevo pasajero
            switch (_viaje.pasajeros[i].nuevo) {
              case "1":
                List<String> aux = rpta.split('/');
                nuevoNumDoc = aux[1];
                String numDocLocal = _viaje.pasajeros[i].numDoc;
                _viaje.pasajeros[i].nuevo = '0';
                _viaje.pasajeros[i].numDoc = nuevoNumDoc;

                //Actualiza el pasajero
                int status = await AppDatabase.instance.Update(
                  table: "pasajero_domicilio",
                  value: _viaje.pasajeros[i].toJsonBDLocal(),
                  where: "numDoc = '$numDocLocal'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
                );

                Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero nuevo en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

                break;
              case "2":
                _viaje.pasajeros[i].nuevo = '0';

                break;
              default:
                break;
            }

            _viaje.pasajeros[i].modificado = 1;
            break;
          case "-1":
            /* Eliminamos del provider y de la bd local */
            /*await AppDatabase.instance
                  .eliminarPasajero(_viajeProvider.pasajeros[i]);*/
            _viaje.pasajeros.removeWhere((element) => element.numDoc == _viaje.pasajeros[i].numDoc);

            break;
          case "-4": //Cuando el pasajero ya se encuentra registrado en BD y tiene una reserva
            break;
          case "-2":
          case "-3": //Error en la transacción
          case "-9":
            datosPorSincronizar = true;
            _viaje.pasajeros[i].modificado = 0;
            break;
          default:
        }

        int status = await AppDatabase.instance.Update(
          table: "pasajero_domicilio",
          value: _viaje.pasajeros[i].toJsonBDLocal(),
          where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
        );

        Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

        //Actualizamos la variable provider de viaje
        //await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viaje.pasajeros[i]);
        /*await Provider.of<DomicilioProvider>(context, listen: false)
              .actualizarMarkerMostrar();*/
        break;
      }
    }
    await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);

    setState(() {});
  }

  AwesomeDialog _modalEmbarcarNuevoPasajero(ViajeDomicilio viaje, PasajeroDomicilio nuevoPasajero) {
    String titulo = "EMBARCAR";
    String cuerpo = "¿Seguro que desea embarcar al pasajero ${nuevoPasajero.nombres}?";

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
          Log.insertarLogDomicilio(context: context, mensaje: "Presiona SI", rpta: "OK");
          await registrarEmbarqueNuevoPasajero(viaje, nuevoPasajero);
        },
        btnCancelText: "No",
        btnCancelColor: AppColors.redColor,
        btnCancelOnPress: () {},
        onDismissCallback: (type) {
          Log.insertarLogDomicilio(context: context, mensaje: "Regresa a la pantalla del listado de embarque de pasajeros REPARTO", rpta: "OK");

          if (type == DismissType.btnOk) {
            Navigator.pop(context);
          }
        });
  }
  //desembarque-gps
  Future<void> registrarDesembarque(ViajeDomicilio viaje, Parada parada) async {
    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    String fechaHoraDesemb = DateFormat.yMd().add_Hms().format(new DateTime.now());
    if (viaje.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < viaje.pasajeros.length; i++) {
        if (viaje.pasajeros[i].embarcado == 1 && viaje.pasajeros[i].fechaDesembarque == "" && viaje.pasajeros[i].direccion == parada.direccion && viaje.pasajeros[i].coordenadas == parada.coordenadas && viaje.pasajeros[i].distrito == parada.distrito && viaje.pasajeros[i].horaRecojo == parada.horaRecojo) {
          viaje.pasajeros[i].coordenadasParadero = posicionActual;
          viaje.pasajeros[i].fechaDesembarque = fechaHoraDesemb;
          viaje.pasajeros[i].idDesembarqueReal = "0";
          viaje.pasajeros[i].modificadoAccion = 0; //2 <-- desembarque

          switch (viaje.pasajeros[i].nuevo) {
            case "0":
              setState(() {
                _mostrarCarga = true;
              });

              Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Registra desembarque pasajaro #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "OK");

              String rpta = await servicio.registrarDesembarquePasajeroDomicilio(viaje.pasajeros[i], viaje.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

              Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Registra desembarque pasajaro #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

              setState(() {
                _mostrarCarga = false;
              });

              switch (rpta) {
                case "0":
                  viaje.pasajeros[i].modificadoAccion = 1;
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
                  viaje.pasajeros[i].modificadoAccion = 0;
                  break;
                default:
              }

              break;
          }

          int status = await AppDatabase.instance.Update(
            table: "pasajero_domicilio",
            value: viaje.pasajeros[i].toJsonBDLocal(),
            where: "numDoc = '${viaje.pasajeros[i].numDoc}'  AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

          //Actualizamos la variable provider de viaje
          //await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(viaje.pasajeros[i]);
          ///await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();
        }
      }

      setState(() async {
        await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);
        // _mostrarModalRespuesta("HECHO", "Pasajeros desembarcados", true).show();
        /*new Timer(Duration(seconds: 2), () {
          if (_verificarSalir(viaje, parada)) {
            Navigator.pop(context);
          }
        });*/
      });
    } else {
      Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal automatico no existen pasajeros", rpta: "OK");
      _mostrarModalRespuesta('ERROR', 'No existen pasajeros', false);
    }
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

          Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioRepartoDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
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

        await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);
        setState(() {});

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
}
