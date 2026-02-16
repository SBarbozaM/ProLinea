import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:collection/collection.dart';
import 'package:embarques_tdp/main.dart';
import 'package:embarques_tdp/src/Bloc/unidadScaner/embarques_sup_scaner_bloc.dart';
import 'package:embarques_tdp/src/Bloc/vincularInicio/vincular_inicio_bloc.dart';
import 'package:embarques_tdp/src/components/warning_widget_internet.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/pages/inicio.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/components/sliverSubHeader.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/pasajero.dart';
import '../../models/usuario.dart';

class ViajeBolsaEmbarquePage_Embarcador extends StatefulWidget {
  const ViajeBolsaEmbarquePage_Embarcador({Key? key}) : super(key: key);

  @override
  State<ViajeBolsaEmbarquePage_Embarcador> createState() => _ViajeBolsaEmbarquePage_EmbarcadorState();
}

class _ViajeBolsaEmbarquePage_EmbarcadorState extends State<ViajeBolsaEmbarquePage_Embarcador> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _mostrarCarga = false;
  String _opcionSeleccionadaEmbarqueViaje = "-1";
  //String _opcionSeleccionadaEmbarquePasajero = "-1";
  String _opcionSeleccionadaEstado = "1"; //1 Embarcado 0 No embarcado
  late Timer _timer;
  late Timer _timer2 = Timer(Duration.zero, () {});
  late Usuario _usuario;
  FocusNode _focusNumDoc = new FocusNode();
  final TextEditingController _numDocController = TextEditingController();

  List<PuntoEmbarque> pe = [];

  final player = AudioPlayer();

  late NavigatorState _navigator;
  bool _cambioDependencia = false;

  bool _mostarLoadin = false;

  bool estadoPECerrado = true;

  List listaPasajerosEPunto = [];

  bool CodigoExternoOdni = true;

  @override
  void initState() {
    //VALIDA EL DNI DEL INPUT
    _focusNumDoc.onKey = (node, event) {
      if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
        _validarInputDni();
      }
      return KeyEventResult.ignored;
    };
    //OBTIENE EL USUARIO ASIGNADO EN EL PROVIDER GLOBAL
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    //TIMER PARA VERIFICAR LA CONEXION CADA 5 SEGUNDOS
    _timer = new Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_timer2.isActive) {
        _timer2 = new Timer.periodic(Duration(seconds: 10), (timer2) {
          if (_hayConexion()) {
            print(_timer2.tick);

            if (_timer2.tick == 1) {
              //SE SINCRONIZAN LOS DATOS CON
              SincronizarViajeBolsa();
            }
          } else {
            _timer2.cancel();
          }

          setState(() {});
        });
      }

      //actualizar los datos del viaje cada 10 segundos
    });
    // _init();
    super.initState();
    ingreso("INGRESO A EMBARQUE PASAJEROS");
    _showDialog();
  }

  //->
  SincronizarViajeBolsa() async {
    List<Map<String, Object?>> listaViajeBolsa = await AppDatabase.instance.Listar(tabla: "viaje", where: "seleccionado = '1'");
    Viaje viaje = await ActualizarViajeEmbarqueBolsaBDLocal(listaViajeBolsa[0]);
    if (_hayConexion()) {
      Provider.of<ViajeProvider>(context, listen: false).sincronizacionContiniaDeViajeBolsaDesdeHome(
        _usuario.tipoDoc,
        _usuario.numDoc,
        _usuario.codOperacion,
        context,
        viaje,
      );
      setState(() {});
      //actualizar los datos del viaje cada 10 segundos
    }
    _timer2.cancel();
  }

  Future<Viaje> ActualizarViajeEmbarqueBolsaBDLocal(Map<String, dynamic> json) async {
    Viaje viaje;
    //TRAE LOS DATOS DE LA BASE DE DATOS LOCAL VIAJE
    viaje = Viaje.fromJsonMapVinculadoLocal(json);
    //ENLISTA LOS PASAJEROS DE LA BASE DE DATOS LOCAL
    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero");
    List<Pasajero> _pasajeros = listaPasajeros.map((e) => Pasajero.fromJsonMapDBLocal(e)).toList();
    //ENLISTA LOS PUNTOS DE EMBARQUE LOCALES
    List<Map<String, Object?>> listaPuntosEmbarque = await AppDatabase.instance.Listar(tabla: "punto_embarque", where: "nroViaje = '${viaje.nroViaje}'");
    List<PuntoEmbarque> _puntosEmbarque = listaPuntosEmbarque.map((e) => PuntoEmbarque.fromJsonMapBDLocal(e)).toList();
    //ENLISTA LOS TRIPULANTES LOCALES
    List<Map<String, Object?>> listaTripulantes = await AppDatabase.instance.Listar(tabla: "tripulante", where: "nroViaje = '${viaje.nroViaje}'");
    List<Tripulante> _tripulantes = listaTripulantes.map((e) => Tripulante.fromJsonMap(e)).toList();

    //AÑADE LAS LISTAS AL OBJETO INICIADO EN LA FUNCIÓN
    viaje.pasajeros = _pasajeros;
    viaje.puntosEmbarque = _puntosEmbarque;
    viaje.tripulantes = _tripulantes;
    //RETORNA EL OBJETO
    return viaje;
  }

  //RETORNA TRUE O FALSE AL VERIFICAR LA CONEXION
  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  _showDialog() async {
    await Future.delayed(Duration(milliseconds: 50));

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              contentPadding: EdgeInsets.all(0),
              scrollable: true,
              content: Container(
                width: MediaQuery.of(context).size.width,
                child: _filtrosSmallScreen(MediaQuery.of(context).size.width),
              ),
            ),
          );
        });
  }

  //NUEVO REGISTRO EN LA BITACORA LOCAL
  ingreso(String Mensaje) async {
    var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    await AppDatabase.instance.NuevoRegistroBitacora(
      context,
      "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
      "${usuarioLogin.codOperacion}",
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "Embarque ${usuarioLogin.perfil}: ${Mensaje}",
      "Exitoso",
    );
  }

  //VE LOS CAMBIOS
  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    setState(() {
      _cambioDependencia = true;
    });
    super.didChangeDependencies();
  }

  //ENLISTA LOS PUNTOS DE EMBARQUE POR RUTA
  _init() async {
    _opcionSeleccionadaEmbarqueViaje = "-1";

    var viajeServicio = new ViajeServicio();
    final viaje = Provider.of<ViajeProvider>(context, listen: false).viaje;

    final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
      viaje.nroViaje,
      viaje.codOperacion,
    );

    if (puntosEmabarque.isEmpty) {
      _opcionSeleccionadaEmbarqueViaje = "-1";
    } else {
      _opcionSeleccionadaEmbarqueViaje = Provider.of<ViajeProvider>(context, listen: false).puntoDeEmbarque;
    }
    viaje.puntosEmbarque = puntosEmabarque;

    Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viaje);

    // pe = puntosEmabarque;
    // PuntoEmbarque p =
    //     new PuntoEmbarque(id: "", nombre: "", nroViaje: "", eliminado: 0);
    // if (pe.isNotEmpty) {
    //   for (int i = 0; i < pe.length; i++) {
    //     if (pe[i].eliminado == 0) {
    //       //0 = abierto y/o no eliminado
    //       p = pe[i];
    //       break;
    //     }
    //   }

    //   if (p.id != "" && p.eliminado == 0) {
    //     //0 = abierto y/o no eliminado
    //     setState(() {
    //       _opcionSeleccionadaEmbarqueViaje = p.id;
    //     });
    //   }
    // }
  }

  //SE EJECUTA AL CERRAR
  @override
  void dispose() {
    _timer.cancel();
    _timer2.cancel();
    _focusNumDoc.dispose();
    _numDocController.dispose();
    super.dispose();
  }

  //COMPONENTE
  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'es';
    initializeDateFormatting();

    /*String estadoInternet = internetChecker.internet;*/
    Viaje _viaje = Provider.of<ViajeProvider>(context).viaje;
    double width = MediaQuery.of(context).size.width;
    //double espacioCabecera = estadoInternet == "online" ? 50 : 20;

    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          setState(() {
            _mostarLoadin = true;

            //_opcionSeleccionadaEmbarqueViaje = "-1";
          });

          ingreso("BAJAR LA PANTALLA, ACTUALIZAR PRERESERVAS");

          return Future.delayed(Duration(seconds: 1), () async {
            final embarquesBlocSuccess = context.read<EmbarquesSupScanerBloc>() as EmbarquesSupScanerSuccess;
            final vincularBlocSuccess = context.read<VincularInicioBloc>() as VincularInicioSuccess;
            ActualizarBajarPantalla(
              vincularBlocSuccess.tDocConducto1,
              vincularBlocSuccess.nDocConducto1,
              _usuario.codOperacion,
              embarquesBlocSuccess.numViaje,
            );
            _init();
            setState(() {
              _mostarLoadin = false;
              _opcionSeleccionadaEmbarqueViaje = "-1";
            });
          });
        },
        child: Scaffold(
          // drawer: MyDrawer(),
          // appBar: AppBar(
          //   centerTitle: true,
          //   elevation: 0,
          //   title: const Text(
          //     'EMBARQUE DE PASAJEROS',
          //     style: TextStyle(
          //         fontWeight: FontWeight.bold, color: AppColors.whiteColor),
          //   ),
          //   backgroundColor: AppColors.mainBlueColor,
          // ),

          key: _scaffoldKey,
          body: _mostarLoadin
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : ModalProgressHUD(
                  opacity: 0.0,
                  color: AppColors.whiteColor,
                  progressIndicator: const CircularProgressIndicator(
                    color: AppColors.mainBlueColor,
                  ),
                  inAsyncCall: _mostrarCarga,
                  child: GestureDetector(
                    onTap: () => hideKeyboard(context),
                    child: SafeArea(
                      child: CustomScrollView(
                        scrollDirection: Axis.vertical,
                        slivers: [
                          SliverAppBar(
                            leading: IconButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                              ),
                            ),
                            titleTextStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteColor,
                            ),
                            title: Text('EMBARQUE DE PASAJEROS SUPERVISOR'),
                            floating: false,
                            elevation: 0,
                            pinned: true,
                            backgroundColor: AppColors.mainBlueColor,
                            expandedHeight: 150,
                            flexibleSpace: FlexibleSpaceBar(
                              background: Column(
                                children: [
                                  SizedBox(
                                    height: 45,
                                  ),
                                  _informacionViaje(_viaje, width),
                                ],
                              ),
                            ),
                          ),
                          SliverSubHeader(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Unidad: ",
                                      style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
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
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.3,
                                      height: 28,
                                      child: FittedBox(
                                        child: Text(
                                          "Pto Emb: ",
                                          style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.3,
                                      height: 32,
                                      child: FittedBox(
                                        child: Text(
                                          "${Provider.of<ViajeProvider>(context, listen: false).nombrepuntoDeEmbarque}",
                                          style: TextStyle(fontSize: 20, color: AppColors.turquesaLinea),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      child: Row(
                                        children: [
                                          Text(
                                            "Capac: ",
                                            style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                                          ),
                                          Text(
                                            _viaje.cantAsientos.toString(),
                                            style: TextStyle(fontSize: 18, color: AppColors.lightBlue, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width * 0.1),
                                    Container(
                                      child: Row(
                                        children: [
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
                                    )
                                  ],
                                ),
                              ],
                            ),
                            colorContainer: AppColors.mainBlueColor,
                            minHeight: 87,
                            maxHeight: 87,
                          ),
                          SliverSubHeader(
                            minHeight: 70,
                            maxHeight: 70,
                            colorContainer: AppColors.whiteColor,
                            child: Column(
                              children: [
                                //Filtros
                                // SizedBox(height: 10),
                                // ResponsiveWidget.isSmallScreen(context)
                                //     ? _filtrosSmallScreen(width)
                                //     : _filtrosLargeScreen(width),

                                _inputDni(width),
                              ],
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Container(
                              width: width,
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),

                                  //LISTA DE PASAJEROS
                                  Container(
                                      padding: EdgeInsets.only(left: 25, right: 25),
                                      child: Column(
                                        children: _listaWidgetPasajeros2(),
                                      )),

                                  const SizedBox(
                                    height: 50,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                )),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                WarningWidgetInternet(),
                if (estadoPECerrado)
                  Container(
                    child: _botonCerrarPuntoEmbarque(width, _viaje),
                  ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
        ),
      ),
    );
  }

  //VERIFIA EL ESTADO TEXTINPUT
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
        SizedBox(
          height: 40,
          width: width * 0.7,
          child: FittedBox(
            child: Text(
              'EMBARQUE DE PASAJEROS',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.whiteColor),
            ),
          ),
        ),
        /*Text(
          'EMBARQUE DE PASAJEROS',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: /*22*/ 25, fontWeight: FontWeight.bold),
        ),*/
        /*Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'EN',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 10,
            ),
            _puntosEmbarqueViaje(),
          ],
        ),*/
      ],
    );
  }

  _filtrosSmallScreen(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
            onPressed: () {
              Navigator.pushNamed(context, 'inicio');
            },
            icon: Icon(Icons.arrow_back_ios)),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.2,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/inicioAppBus.png"),
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: width * 0.5,
            height: 50,
            child: FittedBox(
              child: Text(
                "Punto Embarque",
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(left: 15, right: 15, bottom: 15),
          width: width,
          child: _puntosEmbarqueViaje(),
        ),
      ],
    );
  }

  _filtrosLargeScreen(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: width * 0.15, padding: const EdgeInsets.only(left: 25, right: 10), child: Text("Embarque:")),
        Container(
          width: width * 0.30,
          padding: const EdgeInsets.only(left: 10),
          child: _puntosEmbarqueViaje(),
        ),
        /*SizedBox(
          width: 20,
        ),
        Container(
            width: width * 0.15,
            padding: const EdgeInsets.only(left: 25, right: 10),
            child: Text("Estado:")),
        Container(
          width: width * 0.30,
          padding: const EdgeInsets.only(left: 10, right: 25),
          child: _estadosPasajero(),
        ),*/
      ],
    );
  }

  //COMPONENTE PARA LA INFORMACIÓN DEL VIAJE
  _informacionViaje(Viaje _viaje, double width) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(
                    //color: AppColors.greenColor,
                    height: 30,
                    width: width * 0.3,
                    child: FittedBox(
                      child: Text(
                        _viaje.origen,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.turquesaLinea),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                //color: AppColors.blueColor,
                height: 30,
                width: width * 0.2,
                child: FittedBox(
                  child: const Icon(Icons.double_arrow, color: AppColors.whiteColor //AppColors.mainBlueColor,
                      ),
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    //color: AppColors.redColor,
                    height: 30,
                    width: width * 0.3,
                    child: FittedBox(
                      child: Text(
                        _viaje.destino,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.turquesaLinea),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Empresa: ",
                style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
              ),
              SizedBox(
                height: 24,
                width: width * 0.3,
                child: FittedBox(
                  child: Text(
                    '${_viaje.subOperacionNombre} ',
                    style: TextStyle(fontSize: 18, color: AppColors.turquesaLinea),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Row(
                  children: [
                    Text(
                      "Servicio: ",
                      style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                    ),
                    SizedBox(
                      height: 24,
                      width: width * 0.3,
                      child: FittedBox(
                        child: Text(
                          _viaje.servicio,
                          style: TextStyle(fontSize: 18, color: AppColors.turquesaLinea),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Row(
                  children: [
                    Text(
                      "Fecha: ",
                      style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                    ),
                    SizedBox(
                      height: 24,
                      width: width * 0.3,
                      child: FittedBox(
                        child: Text(
                          _viaje.fechaSalida,
                          style: TextStyle(fontSize: 18, color: AppColors.turquesaLinea),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                child: Row(
                  children: [
                    Text(
                      "Hora: ",
                      style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                    ),
                    SizedBox(
                      height: 24,
                      width: width * 0.15,
                      child: FittedBox(
                        child: Text(
                          _viaje.horaSalida,
                          style: TextStyle(fontSize: 18, color: AppColors.turquesaLinea),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  int calcularAsientosDisponibles(Viaje viaje) {
    int cantPasajeros = viaje.pasajeros.length;
    return viaje.cantAsientos - cantPasajeros;
  }

  int calcularCantidadEmbarcados(Viaje viaje) {
    int cantEmbarcados = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].embarcado == 1) {
        cantEmbarcados++;
      }
    }

    return cantEmbarcados;
  }

  //COMPONENTE DE LOS PUNTOS DE EMBARQUE
  Widget _puntosEmbarqueViaje() {
    List<DropdownMenuItem<String>> items = [];
    items = getOpcionesDropdownPuntosEmbViaje();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      //LO COMENTADO ES PARA QUE CUANDO ABRA SELECTOR SE HAGA EN ANCHO COMPLETO
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton(
            //key: _keyOrigenes,
            value: _opcionSeleccionadaEmbarqueViaje,
            items: items,
            hint: const Text('Seleccione'),
            iconSize: 30,
            isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
            isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
            onChanged: (value) {
              if (value != '-1') {
                ingreso("SELECCIONO PUNTO DE EMBARQUE ${value}");
                String nombre = Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque.firstWhereOrNull((element) => element.id == value)!.nombre;
                Provider.of<ViajeProvider>(context, listen: false).AsignarPuntoEmbarque(value!, nombre);
                setState(() {
                  _opcionSeleccionadaEmbarqueViaje = value.toString();
                });
                Navigator.pop(context);
                _focusNumDoc.requestFocus();
              }
            },
          ),
        ),
      ),
    );
  }

  //COMPONENTE SELECT DE LOS PUNTOS DE EMBARQUE
  List<DropdownMenuItem<String>> getOpcionesDropdownPuntosEmbViaje() {
    List<DropdownMenuItem<String>> listaPuntosEmbarqueViaje = [];
    List<PuntoEmbarque> puntosEmbProvider = [];

    puntosEmbProvider = Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque;

    listaPuntosEmbarqueViaje.add(const DropdownMenuItem<String>(
      value: "-1",
      child: Text(
        "Seleccione",
      ),
    ));

    if (puntosEmbProvider.isNotEmpty) {
      for (int i = 0; i < puntosEmbProvider.length; i++) {
        if (puntosEmbProvider[i].eliminado == 0) {
          //0 = abierto y/o no eliminado
          listaPuntosEmbarqueViaje.add(
            DropdownMenuItem(
              child: Text(
                puntosEmbProvider[i].nombre,
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.blueColor),
              ),
              value: puntosEmbProvider[i].id,
            ),
          );
        }
      }
    }

    return listaPuntosEmbarqueViaje;
  }

  /*Widget _estadosPasajero() {
    List<DropdownMenuItem<String>> items = [];
    items = getOpcionesDropdownEstados();

    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      //color: Colors.white,
      //LO COMENTADO ES PARA QUE CUANDO ABRA SELECTOR SE HAGA EN ANCHO COMPLETO
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          //key: _keyOrigenes,
          value: _opcionSeleccionadaEstado,
          items: items,
          hint: const Text('No Embarcado'),
          iconSize: 30,
          isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
          //isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
          onChanged: (value) {
            setState(() {
              _opcionSeleccionadaEstado = value.toString();
            });
          },
        ),
      ),
    );
  }*/
  //VER LAS OPCIONES DEL ESTADO
  List<DropdownMenuItem<String>> getOpcionesDropdownEstados() {
    List<DropdownMenuItem<String>> listaEstados = [];

    listaEstados.add(const DropdownMenuItem<String>(
      value: "0",
      child: Text(
        "No embarcado",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ));

    listaEstados.add(const DropdownMenuItem<String>(
      value: "1",
      child: Text(
        "Embarcado",
        style: TextStyle(color: AppColors.greenColor, fontWeight: FontWeight.bold),
      ),
    ));

    return listaEstados;
  }

  //COMPONENTE PARA CERRAR EL PUNTO DE EMBARQUE
  _botonCerrarPuntoEmbarque(double _width, Viaje _viaje) {
    return Container(
      height: 35,
      margin: EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(color: _opcionSeleccionadaEmbarqueViaje != '-1' ? AppColors.mainBlueColor : AppColors.greyColor, borderRadius: BorderRadius.circular(25)),
      child: TextButton(
        child: Text(
          "Cerrar Embarque",
          style: TextStyle(color: AppColors.whiteColor, fontSize: 13),
        ),
        onPressed: _opcionSeleccionadaEmbarqueViaje != '-1'
            ? () async {
                if (_opcionSeleccionadaEmbarqueViaje == '-1') {
                  _mostrarMensaje("Seleccione el Punto de Embarque que desea cerrar", null);
                } else {
                  List<PuntoEmbarque> puntosEmbarque = Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque;
                  String nombrePunto = "";
                  for (int i = 0; i < puntosEmbarque.length; i++) {
                    if (puntosEmbarque[i].id == _opcionSeleccionadaEmbarqueViaje) {
                      nombrePunto = puntosEmbarque[i].nombre;
                    }
                  }
                  return showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: AppColors.redColor,
                                size: 30,
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              SizedBox(
                                width: _width * 0.5,
                                child: FittedBox(
                                  child: Text(
                                    "ADVERTENCIA",
                                    style: TextStyle(color: AppColors.redColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "¿Seguro que desea cerrar el punto de embarque " + nombrePunto + "?",
                                    textAlign: TextAlign.start,
                                  )
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'NO',
                                style: TextStyle(color: null),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                _showDialogSincronizandoDatos(context, "Cargando...");
                                if (listaPasajerosEPunto.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                    ..showSnackBar(SnackBar(
                                      content: Text(
                                        "No puedes cerrar el punto embarque por que no hay ningun pasajero embarcado",
                                        style: TextStyle(color: AppColors.whiteColor),
                                        textAlign: TextAlign.center,
                                      ),
                                      duration: Duration(seconds: 3),
                                      backgroundColor: AppColors.redColor,
                                    ));
                                  Navigator.pop(context);
                                  return;
                                }

                                //TODO: Elimina la variable local del viaje vinculado
                                // final SharedPreferences pref = await SharedPreferences.getInstance();
                                // await pref.remove("usuarioVinculado");

                                CerrarELPuntoEmbarque(_viaje);
                              },
                              child: Text(
                                'SI',
                                style: TextStyle(color: AppColors.redColor),
                              ),
                            ),
                          ],
                        );
                      });
                }
              }
            : null,
      ),
    );
  }

  //FUNCION PARA CERRAR EL PUNTO DE EMBARQUE
  CerrarELPuntoEmbarque(Viaje _viaje) async {
    List<PuntoEmbarque> pEmbarque = Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque;
    List<PuntoEmbarque> newPEmbarque = [];
    if (pEmbarque.isNotEmpty) {
      for (PuntoEmbarque p in pEmbarque) {
        if (p.id == _opcionSeleccionadaEmbarqueViaje) {
          p.eliminado = 1; //1 = cerrado y/o eliminado
          p.fechaAccion = DateFormat.yMd().add_Hms().format(new DateTime.now());
          p.modificado = 0; //modificado
          bool responseSuccess = false;

          ViajeServicio servicio = new ViajeServicio();
          Response? resp = await servicio.cambiarEstadoPuntoEmbarqueV2(p, _usuario.tipoDoc, _usuario.numDoc, _viaje);

          if (resp != null) {
            if (resp.body == "0") {
              responseSuccess = true;
            } else {
              responseSuccess = false;
            }
          } else {
            responseSuccess = false;
          }

          Log.ingreso(context, "EMBARCADOR: PUNTO EMBARQUE ${p.nombre} CERRADO /  ${DateTime.now()} / ${responseSuccess ? "SINCRONIZADO" : "NO SINCRONIZADO"} ");

          //Editamos el estado de la BD Local
          await AppDatabase.instance.Update(
            table: "punto_embarque",
            value: {"eliminado": "1", "sincronizado": responseSuccess ? "0" : "1"},
            where: "id = '${p.id}' AND nroViaje='${p.nroViaje}'",
          );

          await AppDatabase.instance.Update(
            table: "usuario",
            value: {"vinculacionActiva": "0"},
            where: "numDoc = '${_usuario.numDoc}'",
          );

          // await Provider.of<UsuarioProvider>(context, listen: false).emparejar("", "", "", "", "0");

          break;
        } else {
          newPEmbarque.add(p);
        }
      }

      BuildContext context2 = context;

      if (_cambioDependencia) context2 = _navigator.context;

      await Provider.of<ViajeProvider>(context2, listen: false).puntosEmbarqueViajeActuales(puntosEmbarque: newPEmbarque);

      await Provider.of<ViajeProvider>(context2, listen: false).actualizarSeleccionadaEmbarqueManifiestor("-1");

      if (_usuario.acciones.firstWhereOrNull((accion) => accion.toUpperCase() == "GESTIONAREMBARQUECONDUCTOR") != null) {
        Navigator.pop(context);
      } else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => InicioPage()));
        ingreso("ENTRO A INICIO ");
      }

      _mostrarMensaje("Punto de Embarque cerrado correctamente", AppColors.blueColor);
      setState(() {
        estadoPECerrado = false;
      });
    }
  }

  //SONIDOS AL TIMBRAR EL CODIGO DEL PASAJERO
  _playSuccessSound() {
    player.play(AssetSource('sounds/success_sound.mp3'));
  }

  _playErrorSound() {
    player.play(AssetSource('sounds/error_sound2.mp3'));
  }

  _playBeepSound() {
    player.play(AssetSource('sounds/beep_sound.mp3'));
  }

  /*Widget _listarPasajeros() {
    return Container(
      //color: AppColors.lightBlue,
      child: ListView(
        padding: EdgeInsets.all(0),
        children: _listaWidgetPasajeros(),
      ),
    );
  }*/
  //ENLISTA LOS PASAJEROS
  List<Widget> _listaWidgetPasajeros2() {
    List<Widget> lista = [];
    List<Widget> listaEmbarcados = [];

    Viaje _viajeProv = Provider.of<ViajeProvider>(context, listen: false).viaje;
    List<Pasajero> _pasajeros = _viajeProv.pasajeros;

    if (_pasajeros.isEmpty) {
      listaEmbarcados = [];
      lista.add(
        Card(
          child: ListTile(
            title: Text('No hay pasajeros para mostrar'),
          ),
        ),
      );
    } else {
      for (int i = 0; i < _pasajeros.length; i++) {
        if (_opcionSeleccionadaEmbarqueViaje != '-1') {
          if (_pasajeros[i].embarcado.toString() == '1' && _pasajeros[i].idEmbarqueReal == _opcionSeleccionadaEmbarqueViaje && _pasajeros[i].estado == 'A') {
            lista.add(_cardWidget(_pasajeros[i]));
            listaEmbarcados.add(_cardWidget(_pasajeros[i]));
          } else {}
        }
      }

      if (lista.isEmpty) {
        listaEmbarcados = [];
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

    setState(() {
      listaPasajerosEPunto = listaEmbarcados;
    });
    return lista;
  }

  /*List<Widget> _listaWidgetPasajeros() {
    List<Widget> lista = [];

    Viaje _viajeProv = Provider.of<ViajeProvider>(context, listen: false).viaje;
    List<Pasajero> _pasajeros = _viajeProv.pasajeros;

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
        if (_opcionSeleccionadaEmbarqueViaje != '-1') {
          if (_pasajeros[i].embarcado.toString() == _opcionSeleccionadaEstado &&
              _pasajeros[i].idEmbarque == _opcionSeleccionadaEmbarqueViaje) {
            lista.add(_cardWidget(_pasajeros[i]));
          }
        } else {
          /*if (_pasajeros[i].embarcado.toString() == _opcionSeleccionadaEstado) {
            lista.add(_cardWidget(_pasajeros[i]));
          }*/
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
  }*/
  //CARD DE LOS PASAJEROS
  _cardWidget(Pasajero pasajero) {
    return Card(
      elevation: estadoPECerrado ? 1 : 0,
      child: ListTile(
          //leading: FlutterLogo(size: 72.0),
          title: Container(
            alignment: Alignment.centerLeft,
            height: 20,
            width: MediaQuery.of(context).size.width * 0.3,
            child: FittedBox(
              child: Text(
                pasajero.nombres.toUpperCase(),
                //pasajero.apellidos + ", " + pasajero.nombres,
                style: TextStyle(color: _opcionSeleccionadaEstado == "1" ? AppColors.greenColor : null, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("COD ${pasajero.numDoc}"), //TODO: CAMBIO A COD
                  Spacer(),
                  //Text(pasajero.lugarDesembarque),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                height: 20,
                width: MediaQuery.of(context).size.width * 0.3,
                child: FittedBox(
                  child: Text(
                    "Desembarque: " + pasajero.lugarDesembarque,
                  ),
                ),
              ),
            ],
          ),

          //trailing: Icon(Icons.more_vert),
          //isThreeLine: true,
          onTap: !estadoPECerrado
              ? null
              : () {
                  if (_opcionSeleccionadaEmbarqueViaje == "-1") {
                    _mostrarMensaje('Seleccione un Punto de Embarque', null);
                  } else {
                    _ModalRevertirEmbarque(pasajero);
                  }
                }),
    );
  }
  //REVIRTE EL EMBARQUE DEL PASAJERO SELECCIONADO
  Future<dynamic> _ModalRevertirEmbarque(Pasajero pasajero) {
    double _width = MediaQuery.of(context).size.width;
    String titulo = "";
    String cuerpo = "";
    late Widget icono;

    titulo = "REVERTIR EMBARQUE";
    cuerpo = "¿Seguro que desea REVERTIR el embarque del pasajero " + pasajero.nombres + "?";
    /*cuerpo = "¿Seguro que desea DESEMBARCAR al pasajero " +
          pasajero.apellidos +
          ", " +
          pasajero.nombres +
          "?";*/
    icono = Icon(
      Icons.no_transfer,
      color: AppColors.blueColor,
      size: _width * 0.1,
    );

    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                icono,
                SizedBox(
                  width: 15,
                ),
                SizedBox(
                  width: _width * 0.5,
                  child: FittedBox(
                    child: Text(
                      titulo,
                      style: TextStyle(color: AppColors.blueColor),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cuerpo,
                      textAlign: TextAlign.start,
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'NO',
                  style: TextStyle(color: null),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} REVERTIR EMBARQUE /  ${DateTime.now()}");
                  Navigator.pop(context);
                  await RevertirPasajero(pasajero);
                  _modalAutomatico('1', pasajero);
                },
                child: Text(
                  'SI',
                  style: TextStyle(color: AppColors.blueColor),
                ),
              ),
            ],
          );
        });
  }

  /*Future<dynamic> _modalEmbarque_Desembarque(Pasajero pasajero, String estado) {
    double _width = MediaQuery.of(context).size.width;
    String titulo = "";
    String cuerpo = "";
    late Widget icono;

    if (estado == "0") {
      titulo = "EMBARCAR PASAJERO";
      /*cuerpo = "¿Seguro que desea EMBARCAR al pasajero " +
          pasajero.apellidos +
          ", " +
          pasajero.nombres +
          "?";*/

      cuerpo = "¿Seguro que desea EMBARCAR al pasajero " + pasajero.nombres + "?";
      icono = Icon(
        Icons.bus_alert,
        color: AppColors.greenColor,
        size: _width * 0.1,
      );
    } else {
      titulo = "REVERTIR EMBARQUE";
      cuerpo = "¿Seguro que desea REVERTIR el embarque del pasajero " + pasajero.nombres + "?";
      /*cuerpo = "¿Seguro que desea DESEMBARCAR al pasajero " +
          pasajero.apellidos +
          ", " +
          pasajero.nombres +
          "?";*/
      icono = Icon(
        Icons.no_transfer,
        color: AppColors.blueColor,
        size: _width * 0.1,
      );
    }

    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                icono,
                SizedBox(
                  width: 15,
                ),
                SizedBox(
                  width: _width * 0.5,
                  child: FittedBox(
                    child: Text(
                      titulo,
                      style: TextStyle(color: estado == "0" ? AppColors.greenColor : AppColors.blueColor),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cuerpo,
                      textAlign: TextAlign.start,
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'NO',
                  style: TextStyle(color: null),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;

                  await AppDatabase.instance.NuevoRegistroBitacora(
                    context,
                    "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
                    "${usuarioLogin.codOperacion}",
                    DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
                    "Embarque ${usuarioLogin.perfil}:  ${pasajero.numDoc} REVERTIO EMBARQUE",
                    "Exitoso",
                  );

                  await cambiarEstadoEmbarque(pasajero, estado);
                },
                child: Text(
                  'SI',
                  style: TextStyle(color: estado == "0" ? AppColors.greenColor : AppColors.blueColor),
                ),
              ),
            ],
          );
        });
  }*/
  //CAMBIA EL ESTADO DEL EMBARQUE DEL PASAJERO
  Future<void> cambiarEstadoEmbarque(Pasajero pasajero, String estado) async {
    int nuevoEstado = 1;
    if (estado == "0") {
      nuevoEstado = 1;
    } else {
      if (estado == "1") {
        nuevoEstado = 0;
      }
    }

    Viaje _viajeProvider = await Provider.of<ViajeProvider>(context, listen: false).viaje;

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();

      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].tipoDoc == pasajero.tipoDoc && _viajeProvider.pasajeros[i].numDoc == pasajero.numDoc && _viajeProvider.pasajeros[i].embarcado != nuevoEstado) {
          bool esPasajeroDesembarcado = false;
          String nuevoNroViaje = "0";
          String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

          Pasajero pasajeroDesembarcado = new Pasajero();

          _viajeProvider.pasajeros[i].embarcado = nuevoEstado;
          _viajeProvider.pasajeros[i].idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
          _viajeProvider.pasajeros[i].fechaEmbarque = fechaHoraEmb;
          _viajeProvider.pasajeros[i].modificado = 0;

          if (nuevoEstado == 0) {
            _viajeProvider.pasajeros[i].nroViaje = _viajeProvider.nroViaje;
            esPasajeroDesembarcado = true;
            // _viajeProvider.pasajeros[i].asiento = 0;
            _viajeProvider.pasajeros[i].estado = 'P';
            _viajeProvider.pasajeros[i].idRuta = pasajero.idRuta;
            nuevoNroViaje = "0";
          } else {
            _viajeProvider.pasajeros[i].nroViaje = _viajeProvider.nroViaje;
            // _viajeProvider.pasajeros[i].asiento = 0;
            _viajeProvider.pasajeros[i].estado = 'A';
            nuevoNroViaje = _viajeProvider.nroViaje;
            esPasajeroDesembarcado = false;
          }

          setState(() {
            _mostrarCarga = true;
          });

          String rpta = await servicio.cambiarEstadoPrereservaV2(pasajero, _viajeProvider.codOperacion, nuevoNroViaje, _usuario.tipoDoc + _usuario.numDoc);
          setState(() {
            _mostrarCarga = false;
          });
          bool pasajeroNoEliminado = true;

          switch (rpta) {
            case "0":
              /*Si el nuevo estado es 0 (NO EMBARCADO) 
                Añadirlo a la lista de prereservas
                y Eliminarlo de la lista de pasajeros y 
                */
              _viajeProvider.pasajeros[i].modificado = 1;
              if (nuevoEstado == 0) {
                pasajeroDesembarcado = _viajeProvider.pasajeros[i];

                await Provider.of<PrereservaProvider>(context, listen: false).agregarPrereserva(_viajeProvider.pasajeros[i]);
                await AppDatabase.instance.eliminarPasajero(_viajeProvider.pasajeros[i]);

                _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);

                pasajeroNoEliminado = false;
                esPasajeroDesembarcado = true;
              } else {
                esPasajeroDesembarcado = false;
              }

              break;
            case "1":
              /* Eliminamos del provider y de la bd local */
              await AppDatabase.instance.eliminarPasajero(_viajeProvider.pasajeros[i]);
              _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);
              _mostrarMensaje("El pasajero ya no se encuentra en la lista", AppColors.redColor);
              pasajeroNoEliminado = false;
              break;
            case "2":
              break;
            case "3":
            case "4":
              _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);
              pasajeroNoEliminado = false;
              estado = "4";
              esPasajeroDesembarcado = true;
              break;
            case "9":
              datosPorSincronizar = true;
              _viajeProvider.pasajeros[i].modificado = 0;
              break;
            default:
          }

          if (pasajeroNoEliminado) {
            //Actualizamos el pasajero en la bd local
            await AppDatabase.instance.insertarActualizarPasajero(_viajeProvider.pasajeros[i]);
            _modalAutomatico(estado, _viajeProvider.pasajeros[i]); //Sin embarcar -> Embarcar automaticamente
          } else {
            if (esPasajeroDesembarcado) {
              _modalAutomatico(estado, pasajeroDesembarcado);
            }
          }

          //Actualizamos la variable provider de viaje
          Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: _viajeProvider);
          setState(() {});
          break;
        }
      }
    } else {
      _mostrarMensaje('No existen pasajeros', null);
    }
  }
  //FUNCION
  //embarcarpasajero-gps
  Future<void> EmbarcarPasajero(Pasajero pasajero) async {
    Viaje _viajeProvider = await Provider.of<ViajeProvider>(context, listen: false).viaje;

    if (await Permission.location.request().isGranted) {}

    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }
    pasajero.embarcadoPor = CodigoExternoOdni ? "COD" : 'NDI';
    pasajero.coordenadas = posicionActual;

    pasajero.embarcado = 1;
    pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
    pasajero.fechaEmbarque = DateFormat.yMd().add_Hms().format(new DateTime.now());
    ;
    // pasajero.asiento = 0;
    pasajero.estado = 'A';

    final nuevoNroViaje = _viajeProvider.nroViaje;
    setState(() {
      _mostrarCarga = true;
    });

    bool responseSuccess = false;
    bool errorValidacion = false;

    PasajeroServicio servicio = new PasajeroServicio();
    Response? resp = await servicio.cambiarEstadoPrereservaV5(pasajero, _viajeProvider.codOperacion, nuevoNroViaje, _usuario.tipoDoc + _usuario.numDoc, _viajeProvider.nroViaje);

    if (resp != null) {
      final decodeData = json.decode(resp.body);
      if (decodeData["rpta"] == "0") {
        responseSuccess = true;
      }

      if (decodeData["rpta"] != "0" && decodeData["rpta"] != "500") {
        responseSuccess = false;
        errorValidacion = true;
        setState(() {
          _mostrarCarga = false;
        });
        Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} EMBARCADO /  ${DateTime.now()} / ${decodeData["mensaje"]} ");
        return _mostrarModalRespuesta("Error", decodeData["mensaje"], false).show();
      }
    } else {
      responseSuccess = false;
    }

    if (!errorValidacion) {
      Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} EMBARCADO /  ${DateTime.now()} / ${responseSuccess ? "SINCRONIZADO" : "NO SINCRONIZADO"} ");

      //UPDATE LOCAL
      await AppDatabase.instance.Update(
        table: "pasajero",
        value: {
          "estado": "A",
          "idEmbarqueReal": _opcionSeleccionadaEmbarqueViaje,
          "embarcado": 1,
          "nroViaje": "${_viajeProvider.nroViaje}",
          "sincronizar": responseSuccess ? "0" : "1",
          "embarcadoPor": CodigoExternoOdni ? "COD" : 'NDI',
          "coordenadas": "${pasajero.coordenadas}",
          "fechaEmbarque": "${pasajero.fechaEmbarque}",
        },
        where: "numDoc ='${pasajero.numDoc}' AND idRuta='${pasajero.idRuta}'",
      );

      await AppDatabase.instance.Update(
        table: "usuario",
        value: {
          "sesionSincronizada": responseSuccess ? "0" : "1",
        },
        where: "numDoc ='${_usuario.numDoc}'",
      );

      //ACTUALIZAMOS EL PROVIDER
      await Provider.of<ViajeProvider>(context, listen: false).embarcarPasajero(pasajero);
      setState(() {
        _mostrarCarga = false;
      });

      // Navigator.pop(context);
      _modalAutomatico('0', pasajero);
    }
  }

  Future<void> RevertirPasajero(Pasajero pasajero) async {
    Viaje _viajeProvider = await Provider.of<ViajeProvider>(context, listen: false).viaje;
    pasajero.embarcado = 0;
    pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
    pasajero.fechaEmbarque = DateFormat.yMd().add_Hms().format(new DateTime.now());

    pasajero.nroViaje = _viajeProvider.nroViaje;
    // pasajero.asiento = 0;
    pasajero.estado = 'P';
    pasajero.idRuta = pasajero.idRuta;

    final nuevoNroViaje = "0";

    setState(() {
      _mostrarCarga = true;
    });

    bool responseSuccess = false;
    PasajeroServicio servicio = new PasajeroServicio();
    Response? resp = await servicio.cambiarEstadoPrereservaV5(pasajero, _viajeProvider.codOperacion, nuevoNroViaje, _usuario.tipoDoc + _usuario.numDoc, _viajeProvider.nroViaje);

    if (resp != null) {
      final decodeData = json.decode(resp.body);
      if (decodeData["rpta"] == "0") {
        responseSuccess = true;
      } else {
        responseSuccess = false;
        setState(() {
          _mostrarCarga = false;
        });
        return _mostrarModalRespuesta("Error", decodeData["mensaje"], false).show();
      }
    } else {
      responseSuccess = false;
    }

    Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} REVERTIDO /  ${DateTime.now()} / ${responseSuccess ? "SINCRONIZADO" : "NO SINCRONIZADO"} ");

    //UPDATE LOCAL
    await AppDatabase.instance.Update(
      table: "pasajero",
      value: {
        "estado": "P",
        "idEmbarqueReal": '0',
        "embarcado": 0,
        "nroViaje": "0",
        "sincronizar": responseSuccess ? "0" : "1",
        "fechaDesembarque": "${pasajero.fechaDesembarque}",
      },
      where: "numDoc ='${pasajero.numDoc}' AND idRuta='${pasajero.idRuta}'",
    );

    await AppDatabase.instance.Update(
      table: "usuario",
      value: {
        "sesionSincronizada": responseSuccess ? "0" : "1",
      },
      where: "numDoc ='${_usuario.numDoc}'",
    );

    //ACTUALIZAMOS EL PROVIDER
    await Provider.of<ViajeProvider>(context, listen: false).desembarcarPasajero(pasajero);

    setState(() {
      _mostrarCarga = false;
    });
  }

  /* Future<void> cambiarEstadoEmbarquePasajero(Pasajero pasajero, String estado) async {
    int nuevoEstado = 1;
    if (estado == "0") {
      nuevoEstado = 1;
    } else {
      if (estado == "1") {
        nuevoEstado = 0;
      }
    }

    Viaje _viajeProvider = await Provider.of<ViajeProvider>(context, listen: false).viaje;

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();

      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].tipoDoc == pasajero.tipoDoc && _viajeProvider.pasajeros[i].numDoc == pasajero.numDoc && _viajeProvider.pasajeros[i].embarcado != nuevoEstado) {
          bool esPasajeroDesembarcado = false;
          String nuevoNroViaje = "0";
          String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

          Pasajero pasajeroDesembarcado = Pasajero();

          _viajeProvider.pasajeros[i].embarcado = nuevoEstado;
          _viajeProvider.pasajeros[i].idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
          _viajeProvider.pasajeros[i].fechaEmbarque = fechaHoraEmb;
          _viajeProvider.pasajeros[i].modificado = 0;

          if (nuevoEstado == 0) {
            _viajeProvider.pasajeros[i].nroViaje = _viajeProvider.nroViaje;
            esPasajeroDesembarcado = true;
            _viajeProvider.pasajeros[i].asiento = 0;
            _viajeProvider.pasajeros[i].estado = 'P';
            _viajeProvider.pasajeros[i].idRuta = pasajero.idRuta;
            nuevoNroViaje = "0";
          } else {
            _viajeProvider.pasajeros[i].nroViaje = _viajeProvider.nroViaje;
            _viajeProvider.pasajeros[i].asiento = 0;
            _viajeProvider.pasajeros[i].estado = 'A';
            nuevoNroViaje = _viajeProvider.nroViaje;
            esPasajeroDesembarcado = false;
          }

          setState(() {
            _mostrarCarga = true;
          });

          String rpta = await servicio.cambiarEstadoPrereservaV2(pasajero, _viajeProvider.codOperacion, nuevoNroViaje, _usuario.tipoDoc + _usuario.numDoc);
          setState(() {
            _mostrarCarga = false;
          });
          bool pasajeroNoEliminado = true;

          switch (rpta) {
            case "0":
              /*Si el nuevo estado es 0 (NO EMBARCADO) 
                Añadirlo a la lista de prereservas
                y Eliminarlo de la lista de pasajeros y 
                */
              _viajeProvider.pasajeros[i].modificado = 1;
              if (nuevoEstado == 0) {
                pasajeroDesembarcado = _viajeProvider.pasajeros[i];

                await Provider.of<PrereservaProvider>(context, listen: false).agregarPrereserva(_viajeProvider.pasajeros[i]);
                await AppDatabase.instance.eliminarPasajero(_viajeProvider.pasajeros[i]);

                _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);

                pasajeroNoEliminado = false;
                esPasajeroDesembarcado = true;
              } else {
                esPasajeroDesembarcado = false;
              }

              break;
            case "1":
              /* Eliminamos del provider y de la bd local */
              await AppDatabase.instance.eliminarPasajero(_viajeProvider.pasajeros[i]);
              _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);
              _mostrarMensaje("El pasajero ya no se encuentra en la lista", AppColors.redColor);
              pasajeroNoEliminado = false;
              break;
            case "2":
              break;
            case "3":
            case "4":
              _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);
              pasajeroNoEliminado = false;
              estado = "4";
              esPasajeroDesembarcado = true;
              break;
            case "9":
              datosPorSincronizar = true;
              _viajeProvider.pasajeros[i].modificado = 0;
              break;
            default:
          }

          if (pasajeroNoEliminado) {
            //Actualizamos el pasajero en la bd local
            await AppDatabase.instance.insertarActualizarPasajero(_viajeProvider.pasajeros[i]);
            _modalAutomatico(estado, _viajeProvider.pasajeros[i]); //Sin embarcar -> Embarcar automaticamente
          } else {
            if (esPasajeroDesembarcado) {
              _modalAutomatico(estado, pasajeroDesembarcado);
            }
          }

          //Actualizamos la variable provider de viaje
          Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: _viajeProvider);
          setState(() {});
          break;
        }
      }
    } else {
      _mostrarMensaje('No existen pasajeros', null);
    }
  }*/

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

  Widget _inputDni(double width) {
    return Container(
      //color: AppColors.lightyellowColor,
      padding: EdgeInsets.only(left: width * 0.08, right: width * 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              enabled: estadoPECerrado,
              //keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              focusNode: _focusNumDoc,
              controller: _numDocController,
              onEditingComplete: () {
                _validarInputDni();
              },
              decoration: InputDecoration(
                label: Text(
                  "${CodigoExternoOdni ? "Tarjeta de embarque" : "Nro. Doc. de Identidad"}",
                  style: TextStyle(
                    color: AppColors.mainBlueColor,
                  ),
                ),
              ),
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      CodigoExternoOdni = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: CodigoExternoOdni ? AppColors.mainBlueColor : Colors.grey.shade200,
                    ),
                    child: Text(
                      "COD",
                      style: TextStyle(
                        color: CodigoExternoOdni ? Colors.white : AppColors.mainBlueColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      CodigoExternoOdni = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: !CodigoExternoOdni ? AppColors.mainBlueColor : Colors.grey.shade200,
                    ),
                    child: Text(
                      "D.I",
                      style: TextStyle(
                        color: !CodigoExternoOdni ? Colors.white : AppColors.mainBlueColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _validarInputDni() async {
    if (_opcionSeleccionadaEmbarqueViaje == '-1') {
      _numDocController.text = "";
      _focusNumDoc.requestFocus();
      _mostrarMensaje('Seleccione un Punto de Embarque', null);
    } else {
      String numDocBuscar = _numDocController.text.trim();

      if (numDocBuscar.trim().length <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Ingresé el dni de pasajero",
            style: TextStyle(color: AppColors.whiteColor),
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2),
          //behavior: SnackBarBehavior.floating,
          //margin: EdgeInsets.only(bottom: 50, right: 50, left: 50),
          backgroundColor: AppColors.amberColor,
        ));
        return;
      }

      if (numDocBuscar != "") {
        _numDocController.text = "";
        _focusNumDoc.requestFocus();

        Log.ingreso(context, "EMBARCADOR: DNI  ${numDocBuscar} / ${DateTime.now()}");

        int tamCadena = numDocBuscar.length;

        String ultimoCaracter = numDocBuscar[tamCadena - 1];

        RegExp _isLetterRegExp = RegExp(r'[a-z]', caseSensitive: false);
        bool isLetter(String letter) => _isLetterRegExp.hasMatch(letter);

        final viaje = Provider.of<ViajeProvider>(context, listen: false).viaje;

        if (_usuario.codOperacion == 'O175') {
          if (isLetter(ultimoCaracter)) {
            numDocBuscar = numDocBuscar.substring(0, tamCadena - 1);
          }
        }

        if (viaje.caracterSplit.trim() != "" && viaje.indexLectura.trim() != "") {
          final caracter = numDocBuscar.indexOf("${viaje.caracterSplit}");
          if (caracter != -1) {
            numDocBuscar = numDocBuscar.trim().split("${viaje.caracterSplit}")[int.parse(viaje.indexLectura)];
            tamCadena = numDocBuscar.length;
          }
        }

        if (viaje.corteLadoCantidad.trim() != "") {
          int indexDerecha = viaje.corteLadoCantidad.indexOf("D");
          if (indexDerecha != -1) {
            int cantidadDerecha = int.parse(viaje.corteLadoCantidad[indexDerecha + 1]);
            numDocBuscar = numDocBuscar.substring(0, tamCadena - cantidadDerecha);
            tamCadena = numDocBuscar.length;
          }

          int indexIzquierda = viaje.corteLadoCantidad.indexOf("I");
          if (indexIzquierda != -1) {
            int cantidadIzquierda = int.parse(viaje.corteLadoCantidad[indexIzquierda + 1]);
            numDocBuscar = numDocBuscar.substring(cantidadIzquierda, tamCadena);
            tamCadena = numDocBuscar.length;
          }
        }

        Log.ingreso(context, "EMBARCADOR: DNI  LIMPIO ${numDocBuscar} / ${DateTime.now()}");

        Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
        bool encontrado = false;

        Pasajero pasajero = Pasajero();

        if (viajeActual.pasajeros.isNotEmpty) {
          if (!CodigoExternoOdni) {
            var pasajeroEncontrado = viajeActual.pasajeros.firstWhereOrNull((element) => element.numeroDoc == numDocBuscar);
            if (pasajeroEncontrado != null) {
              pasajero = pasajeroEncontrado;
              numDocBuscar = pasajeroEncontrado.numDoc;
              encontrado = true;
            } else {
              encontrado = false;
            }
          } else {
            for (int i = 0; i < viajeActual.pasajeros.length; i++) {
              if (viajeActual.pasajeros[i].numDoc.trim() == numDocBuscar) {
                pasajero = viajeActual.pasajeros[i];
                encontrado = true;
                break;
              }
            }
          }

          if (encontrado == false) {
            Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} NO ENCONTRADO /  ${DateTime.now()}");
            _ModalPasajeroNoEncontrado(numDocBuscar); //JS: 18/7/23 Pasajeros no encontrado
            return;
          }

          if (encontrado) {
            switch (pasajero.embarcado) {
              case 0:
                if (pasajero.idEmbarque != _opcionSeleccionadaEmbarqueViaje) {
                  Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} NO PUNTO DE EMBARQUE /  ${DateTime.now()}");
                  return await _mostrarModalPasajeroNoPuntoEmbarque(pasajero); //JS: 18/7/23 No es su lugar de embarque
                }
                if (viajeActual.codRuta != pasajero.idRuta) {
                  Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} NO RUTA /  ${DateTime.now()}");
                  return await _mostrarModalPasajeroNoRuta(pasajero);
                }
                if (viajeActual.servicio != pasajero.servicio) {
                  Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} NO SERVICIO /  ${DateTime.now()}");
                  return await _mostrarModalPasajeroNoServicio(pasajero);
                }
                String fechaHoraSalidaViaje = (viajeActual.fechaSalida + " " + viajeActual.horaSalida);
                if (fechaHoraSalidaViaje != pasajero.fechaViaje) {
                  Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} NO FECHA O HORA /  ${DateTime.now()}");
                  return await _mostrarModalPasajeroNoFecha(pasajero);
                }
                if (pasajero.idEmbarque == _opcionSeleccionadaEmbarqueViaje) {
                  Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} ENCONTRADO /  ${DateTime.now()}");
                  return await EmbarcarPasajero(pasajero); // JS: 18/07/23 PASAJERO EMBARCADO
                }
                break;
              case 1:
                Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} YA EMBARCADO /  ${DateTime.now()}");
                return _mostrarModalAutomaticoYaEmbarcado(pasajero); //Ya embarcado
              default:
            }
          }
        } else {
          Log.ingreso(context, "EMBARCADOR: ${numDocBuscar} NO HAY PASAJEROS POR EMBARCAR/  ${DateTime.now()}");
          _ModalPasajeroNoEncontrado(numDocBuscar); //JS: 18/7/23 No hay pasajeros para embarcar/desembarcar
        }
      }
    }
  }

  insertarLog(String mensaje, String estado) async {
    var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    await AppDatabase.instance.NuevoRegistroBitacora(
      context,
      "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
      "${usuarioLogin.codOperacion}",
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      mensaje,
      estado,
    );

    // insertarLog("Embarque ${usuarioLogin.perfil}:${pasajero.numDoc} No es su lugar de embarque");
    // "Embarque ${usuarioLogin.perfil}:${pasajero.numDoc} Ya embarcado",
  }

  Future<dynamic> _modalAutomatico(String accion, Pasajero pasajero) {
    double _width = MediaQuery.of(context).size.width;
    String cuerpo = "";
    String titulo = "";
    Widget icono = Icon(
      Icons.check_circle,
      color: AppColors.greenColor,
      size: _width * 0.1,
    );
    Color color = AppColors.greenColor;

    switch (accion) {
      case "0":
        titulo = "EMBARCADO";
        cuerpo = "PASAJERO AUTORIZADO";
        break;
      case "1":
        titulo = "DESEMBARCADO";
        cuerpo = "PASAJERO DESEMBARCADO";
        icono = Icon(
          Icons.transit_enterexit,
          color: AppColors.blueColor,
          size: _width * 0.1,
        );
        color = AppColors.blueColor;
        break;
      case "3":
        titulo = "RECHAZADO";
        cuerpo = "NO ES SU LUGAR DE EMBARQUE";
        icono = Icon(
          Icons.no_transfer,
          color: AppColors.blueDarkColor,
          size: _width * 0.1,
        );
        color = AppColors.blueDarkColor;
        break;
      case "4":
        titulo = "RECHAZADO";
        cuerpo = "El pasajero " + pasajero.nombres + " ya se embarco en otra unidad.";
        icono = Icon(
          Icons.no_transfer,
          color: AppColors.blueDarkColor,
          size: _width * 0.1,
        );
        color = AppColors.blueDarkColor;
        break;
    }

    return _mostrarModalAutomatico(titulo, cuerpo, icono, color, pasajero);
  }

  Future<void> _modalPasajeroNoEncontradoProgramado() async {}

  /* Future<dynamic> _modalPasajeroNoEncontrado(String numDocBuscar) async {
    double _width = MediaQuery.of(context).size.width;
    String cuerpo = "Pasajero no encontrado";
    String titulo = "PASAJERO NO ENCONTRADO";
    Color color = AppColors.redColor;
    Widget icono = Icon(
      Icons.cancel,
      color: AppColors.redColor,
      size: _width * 0.1,
    );
    List<Pasajero> listadoPrereserva = Provider.of<PrereservaProvider>(context, listen: false).listdoPrereservas;

    bool encontrado = false;
    Pasajero pasajeroEncontrado = new Pasajero();

    if (listadoPrereserva.isNotEmpty) {
      for (Pasajero prereserva in listadoPrereserva) {
        if (prereserva.numDoc.trim() == numDocBuscar.trim()) {
          encontrado = true;
          print(prereserva);
          pasajeroEncontrado = prereserva;
          break;
        }
      }

      if (encontrado) {
        String cambiarPrereserva = await cambiarEstadoPrereserva(pasajeroEncontrado);

        switch (cambiarPrereserva) {
          case "A":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc}, NO HAY ASIENTOS DISPONIBLES",
              "Exitoso",
            );
            titulo = "NO HAY ASIENTOS DISPONIBLES";
            cuerpo = "El pasajero " + pasajeroEncontrado.nombres + " no puede embarcar porque no hay asientos disponibles.";
            break;
          case "L":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc}, NO ES SU LUGAR DE EMBARQUE",
              "Exitoso",
            );
            titulo = "NO ES SU LUGAR DE EMBARQUE";
            cuerpo = "El pasajero " + pasajeroEncontrado.nombres + " su lugar de embarque es: ${pasajeroEncontrado.lugarEmbarque}";
            icono = Icon(
              Icons.no_transfer,
              color: AppColors.blueDarkColor,
              size: _width * 0.1,
            );
            color = AppColors.blueDarkColor;
          // return _mostrarModalPasajeroNoPuntoEmbarque(titulo, cuerpo, icono, color, _width, pasajeroEncontrado.numDoc, pasajeroEncontrado);
          case "S":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc}, EMBARCADO",
              "Exitoso",
            );

            titulo = "EMBARCADO";
            cuerpo = "PASAJERO AUTORIZADO";
            icono = Icon(
              Icons.check_circle,
              color: AppColors.greenColor,
              size: _width * 0.1,
            );

            color = AppColors.greenColor;
            return _mostrarModalAutomatico(titulo, cuerpo, icono, color, pasajeroEncontrado);
          case "F":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc}, DIFERENTE HORA DE EMBARQUE",
              "Exitoso",
            );

            titulo = "HORA DE EMBARQUE";
            cuerpo = "El pasajero " + pasajeroEncontrado.nombres + " tiene una reserva para la fecha " + pasajeroEncontrado.fechaViaje + ".";
          // return _mostrarModalPasajeroNoFecha(titulo, cuerpo, icono, color, _width, pasajeroEncontrado.numDoc, pasajeroEncontrado);
          case "1":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc}, PASAJERO NO ENCONTRADO",
              "Exitoso",
            );

            titulo = "PASAJERO NO ENCONTRADO";
            cuerpo = "El pasajero " + pasajeroEncontrado.nombres + " ya no se encuentra en la lista de reservas. Verifique si no ha sido embarcado en otro bus o si su reserva ha sido eliminada.";
            break;
          case "4":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc}, YA SE EMBARCO EN OTRA UNIDAD",
              "Exitoso",
            );

            titulo = "RECHAZADO";
            cuerpo = "El pasajero " + pasajeroEncontrado.nombres + " ya se embarco en otra unidad.";
            icono = Icon(
              Icons.no_transfer,
              color: AppColors.blueDarkColor,
              size: _width * 0.1,
            );
            color = AppColors.blueDarkColor;
            break;
          case "10":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc},RESERVA VIAJE PARA OTRA RUTA: ${pasajeroEncontrado.ruta}",
              "Exitoso",
            );

            titulo = "RECHAZADO";
            cuerpo = "El pasajero " + pasajeroEncontrado.nombres + " tiene una reserva para un viaje de otra ruta: ${pasajeroEncontrado.ruta}";
            icono = Icon(
              Icons.no_transfer,
              color: AppColors.blueDarkColor,
              size: _width * 0.1,
            );
            color = AppColors.blueDarkColor;
          // return _mostrarModalPasajeroNoRuta(titulo, cuerpo, icono, color, _width, pasajeroEncontrado.numDoc, pasajeroEncontrado);
          case "11":
            var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
            await AppDatabase.instance.NuevoRegistroBitacora(
              context,
              "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
              "${usuarioLogin.codOperacion}",
              DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
              "Embarque ${usuarioLogin.perfil}:${pasajeroEncontrado.numDoc}, RESERVA VIAJE PARA OTRO SERVICIO: ${pasajeroEncontrado.servicio}",
              "Exitoso",
            );

            titulo = "RECHAZADO";
            cuerpo = "El pasajero " + pasajeroEncontrado.nombres + " tiene una reserva para un viaje de otro servicio: ${pasajeroEncontrado.servicio}";
            icono = Icon(
              Icons.no_transfer,
              color: AppColors.blueDarkColor,
              size: _width * 0.1,
            );
            color = AppColors.blueDarkColor;
          // return _mostrarModalPasajeroNoServicio(titulo, cuerpo, icono, color, _width, pasajeroEncontrado.numDoc, pasajeroEncontrado);
          /*case "2":
            titulo = "VIAJE YA FINALIZADO";
            cuerpo = "Parece que el viaje actual ya ha sido finalizado";
            break;*/
        }
      } else {
        var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
        await AppDatabase.instance.NuevoRegistroBitacora(
          context,
          "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
          "${usuarioLogin.codOperacion}",
          DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
          "Embarque ${usuarioLogin.perfil}: ${numDocBuscar} PASAJERO NO ENCONTRADO ",
          "Exitoso",
        );

        titulo = "PASAJERO NO ENCONTRADO";
        cuerpo = "El pasajero ${numDocBuscar} no se encuentra en la lista de reservas para los viajes programados para el día de hoy.";
        // return _mostrarModalPasajeroNoEncontradoRegistrar(titulo, cuerpo, icono, color, _width, numDocBuscar);
      }
    } else {
      var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
      await AppDatabase.instance.NuevoRegistroBitacora(
        context,
        "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
        "${usuarioLogin.codOperacion}",
        DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
        "Embarque ${usuarioLogin.perfil}: LISTA DE RESERVAS VACIA",
        "Exitoso",
      );

      titulo = "LISTA DE RESERVAS VACIA";
      cuerpo = "La lista de reservas con la ruta y fecha actual se encuentra vacía";
    }

    return _mostrarModalPasajeroNoEncontrado(titulo, cuerpo, icono, color, _width);
  }*/
  /* Future<String> cambiarEstadoPrereserva(Pasajero prereserva) async {
    //VERIFICAR ASIENTOS DISPONIBLES
    //int asientoDisponible = buscarAsientoDisponible();
    bool verificarAsientoDisponible = verificarAsientosDisponibles();

    if (verificarAsientoDisponible) {
      Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
      String fechaHoraSalidaViaje = (viajeActual.fechaSalida + " " + viajeActual.horaSalida);

      if (viajeActual.codRuta != prereserva.idRuta) {
        //"536109" ==
        return "10";
      }

      if (viajeActual.servicio != prereserva.servicio) {
        return "11";
      }

      if (fechaHoraSalidaViaje == prereserva.fechaViaje) {
        if (prereserva.idEmbarque == _opcionSeleccionadaEmbarqueViaje) {
          //CAMBIAR ESTADO PRERESERVA

          String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

          PasajeroServicio servicio = new PasajeroServicio();

          /*viajeActual.cantEmbarcados += 1;
          viajeActual.cantDisponibles -= 1;*/

          prereserva.nroViaje = viajeActual.nroViaje;
          prereserva.estado = 'A';
          prereserva.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
          prereserva.fechaEmbarque = fechaHoraEmb;
          prereserva.asiento = 0;
          prereserva.embarcado = 1;
          prereserva.modificado = 2;

          setState(() {
            _mostrarCarga = true;
          });

          String rpta = await servicio.cambiarEstadoPrereservaV2(prereserva, viajeActual.codOperacion, viajeActual.nroViaje, _usuario.tipoDoc + _usuario.numDoc);

          setState(() {
            _mostrarCarga = false;
          });
          bool agregarPrereservaAViaje = true;

          switch (rpta) {
            case "0":
              prereserva.modificado = 1;
              break;
            case "1":
              agregarPrereservaAViaje = false;
              break;
            case "2":
              agregarPrereservaAViaje = false;
              break;
            case "3":
            case "4":
              agregarPrereservaAViaje = false;
              break;
            case "9":
              datosPorSincronizar = true;
              prereserva.modificado = 2;
              break;
            default:
          }

          //Eliminar del listado de prereservas
          await Provider.of<PrereservaProvider>(context, listen: false).eliminarPrereservaDelListado(prereserva);
          await AppDatabase.instance.eliminarPrereserva(prereserva);

          if (agregarPrereservaAViaje) {
            await AppDatabase.instance.insertarActualizarPasajero(prereserva);
            viajeActual.pasajeros.add(prereserva);
            Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viajeActual);

            return "S"; //SUCCESS
          } else {
            return rpta;
          }
        } else {
          return "L"; //Lugar de embarque
        }
      } else {
        return "F";
      }
    } else {
      return "A"; //Asiento
    }
  }
  */

  /*int buscarAsientoDisponible() {
    Viaje viajeActual =
        Provider.of<ViajeProvider>(context, listen: false).viaje;

    int capacidad = viajeActual.cantAsientos;
    int reservados = viajeActual.pasajeros.length;
    int disponibles = capacidad - reservados;

    int asiento = 0;

    if (disponibles > 0) {
      bool ocupado = false;

      for (int i = 1; i <= capacidad; i++) {
        ocupado = false;

        for (int j = 0; j < viajeActual.pasajeros.length; j++) {
          if (i == viajeActual.pasajeros[j].asiento) {
            ocupado = true;
            break;
          }
        }

        if (!ocupado) {
          asiento = i;
          break;
        }
      }
    }

    return asiento;
  }*/

  bool verificarAsientosDisponibles() {
    Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;

    int capacidad = viajeActual.cantAsientos;
    int embarcados = calcularCantidadEmbarcados(viajeActual);
    int disponibles = capacidad - embarcados;

    if (disponibles > 0) {
      return true;
    }

    return false;
  }

  Future _mostrarModalAutomatico(String titulo, String cuerpo, Widget icono, Color color, Pasajero pasajero) {
    if (color == AppColors.greenColor || color == AppColors.blueColor) {
      _playSuccessSound();
    }

    if (color == AppColors.blueDarkColor || color == AppColors.redColor) {
      _playErrorSound();
    }

    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          /*Timer modalTimer =*/ new Timer(Duration(seconds: 2), () {
            Navigator.pop(context);
          });

          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    icono,
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
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          pasajero.nombres, //pasajero.apellidos + ", " + pasajero.nombres,
                          textAlign: TextAlign.start,
                          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          pasajero.tipoDoc + ": " + pasajero.numDoc,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        Text.rich(
                          TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                            TextSpan(
                              text: "Embarque en: ",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: pasajero.lugarEmbarque,
                              style: TextStyle(
                                fontSize: 18,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]),
                        ),
                        if (pasajero.asiento > 0)
                          Text.rich(
                            TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                              TextSpan(
                                text: "Asiento : ",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: pasajero.asiento.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  }

  Future _mostrarModalAutomaticoYaEmbarcado(Pasajero pasajero) {
    final titulo = "YA EMBARCADO";
    final cuerpo = "EMBARQUE YA REGISTRADO";
    final icono = Icon(
      Icons.warning,
      color: AppColors.amberColor,
      size: (MediaQuery.of(context).size.width) * 0.1,
    );
    final color = AppColors.amberColor;
    _playBeepSound();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    icono,
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
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          pasajero.nombres,
                          textAlign: TextAlign.start,
                          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          pasajero.tipoDoc + ": " + pasajero.numDoc,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        Text.rich(
                          TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                            TextSpan(
                              text: "Embarque en: ",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: pasajero.lugarEmbarque,
                              style: TextStyle(
                                fontSize: 18,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]),
                        ),
                        if (pasajero.asiento > 0)
                          Text.rich(
                            TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                              TextSpan(
                                text: "Asiento : ",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: pasajero.asiento.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} REVERTIR EMBARQUE /  ${DateTime.now()}");
                      //modalTimer.cancel();
                      Navigator.pop(context);
                      await RevertirPasajero(pasajero);
                      _modalAutomatico('1', pasajero);
                    },
                    child: Text(
                      "Revertir Embarque",
                      style: TextStyle(fontSize: 18, color: AppColors.redColor),
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  }

  /* Future _mostrarModalPasajeroNoEncontrado(String titulo, String cuerpo, Widget icono, Color color, double _width) {
    _playErrorSound();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          new Timer(Duration(seconds: 5), () {
            Navigator.pop(context);
          });

          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    icono,
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: _width * 0.5,
                      child: FittedBox(
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color),
                        ),
                      ),
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
                          style: TextStyle(fontSize: null),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  } */

  Future _mostrarModalPasajeroNoRuta(Pasajero pasajero) {
    final _width = MediaQuery.of(context).size.width;
    final titulo = "RECHAZADO";
    final cuerpo = "El pasajero " + pasajero.nombres + " tiene una reserva para un viaje de otra ruta: ${pasajero.ruta}";
    final icono = Icon(
      Icons.no_transfer,
      color: AppColors.blueDarkColor,
      size: _width * 0.1,
    );
    final color = AppColors.blueDarkColor;
    _playErrorSound();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    icono,
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: _width * 0.5,
                      child: FittedBox(
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color),
                        ),
                      ),
                    ),
                    /*Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold),
                      ),
                    )*/
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
                          style: TextStyle(fontSize: null),
                        ),
                        if (pasajero.asiento > 0)
                          Text.rich(
                            TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                              TextSpan(
                                text: "Asiento : ",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: pasajero.asiento.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancelar",
                      style: TextStyle(fontSize: 18, color: AppColors.redColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
                      Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
                      String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());
                      // pasajero.nroViaje = viajeActual.nroViaje;
                      pasajero.estado = 'A';
                      pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
                      pasajero.fechaEmbarque = fechaHoraEmb;
                      // pasajero.asiento = 0;
                      pasajero.embarcado = 1;
                      Navigator.pop(context);
                      await EmbarcarPasajero(pasajero);
                      // _modalAutomatico('0', pasajero);
                    },
                    child: Text(
                      "Embarcar de todo modos",
                      style: TextStyle(fontSize: 18, color: AppColors.blueColor),
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  }

  Future _mostrarModalPasajeroNoServicio(Pasajero pasajero) {
    final _width = MediaQuery.of(context).size.width;
    final titulo = "RECHAZADO";
    final cuerpo = "El pasajero " + pasajero.nombres + " tiene una reserva para un viaje de otro servicio: ${pasajero.servicio}";
    final icono = Icon(
      Icons.no_transfer,
      color: AppColors.blueDarkColor,
      size: _width * 0.1,
    );
    final color = AppColors.blueDarkColor;

    _playErrorSound();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    icono,
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: _width * 0.5,
                      child: FittedBox(
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color),
                        ),
                      ),
                    ),
                    /*Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold),
                      ),
                    )*/
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
                          style: TextStyle(fontSize: null),
                        ),
                        if (pasajero.asiento > 0)
                          Text.rich(
                            TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                              TextSpan(
                                text: "Asiento : ",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: pasajero.asiento.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancelar",
                      style: TextStyle(fontSize: 18, color: AppColors.redColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
                      Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
                      String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());
                      // pasajero.nroViaje = viajeActual.nroViaje;
                      pasajero.estado = 'A';
                      pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
                      pasajero.fechaEmbarque = fechaHoraEmb;
                      // pasajero.asiento = 0;
                      pasajero.embarcado = 1;
                      Navigator.pop(context);
                      await EmbarcarPasajero(pasajero);
                      // _modalAutomatico('0', pasajero);
                    },
                    child: Text(
                      "Embarcar de todo modos",
                      style: TextStyle(fontSize: 18, color: AppColors.blueColor),
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  }

  Future _mostrarModalPasajeroNoFecha(Pasajero pasajero) {
    final _width = MediaQuery.of(context).size.width;
    Color color = AppColors.redColor;
    Widget icono = Icon(
      Icons.cancel,
      color: AppColors.redColor,
      size: _width * 0.1,
    );
    final titulo = "HORA DE EMBARQUE";
    final cuerpo = "El pasajero " + pasajero.nombres + " tiene una reserva para la fecha " + pasajero.fechaViaje + ".";

    _playErrorSound();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    icono,
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: _width * 0.5,
                      child: FittedBox(
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color),
                        ),
                      ),
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
                          style: TextStyle(fontSize: null),
                        ),
                        if (pasajero.asiento > 0)
                          Text.rich(
                            TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                              TextSpan(
                                text: "Asiento : ",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: pasajero.asiento.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancelar",
                      style: TextStyle(fontSize: 18, color: AppColors.redColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
                      Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
                      String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());
                      // pasajero.nroViaje = viajeActual.nroViaje;
                      pasajero.estado = 'A';
                      pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
                      pasajero.fechaEmbarque = fechaHoraEmb;
                      // pasajero.asiento = 0;
                      pasajero.embarcado = 1;
                      Navigator.pop(context);
                      await EmbarcarPasajero(pasajero);
                      // _modalAutomatico('0', pasajero);
                    },
                    child: Text(
                      "Embarcar de todo modos",
                      style: TextStyle(fontSize: 18, color: AppColors.blueColor),
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  }

  Future _mostrarModalPasajeroNoPuntoEmbarque(Pasajero pasajero) {
    final _width = MediaQuery.of(context).size.width;
    final titulo = "NO ES SU LUGAR DE EMBARQUE";
    final cuerpo = "El pasajero " + pasajero.nombres + " su lugar de embarque es: ${pasajero.lugarEmbarque}";
    final icono = Icon(
      Icons.no_transfer,
      color: AppColors.blueDarkColor,
      size: _width * 0.1,
    );
    final color = AppColors.blueDarkColor;
    _playErrorSound();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    icono,
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: _width * 0.5,
                      child: FittedBox(
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color),
                        ),
                      ),
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
                          style: TextStyle(fontSize: null),
                        ),
                        if (pasajero.asiento > 0)
                          Text.rich(
                            TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                              TextSpan(
                                text: "Asiento : ",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: pasajero.asiento.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancelar",
                      style: TextStyle(fontSize: 18, color: AppColors.redColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Log.ingreso(context, "EMBARCADOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
                      Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
                      String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());
                      // pasajero.nroViaje = viajeActual.nroViaje;
                      pasajero.estado = 'A';
                      pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
                      pasajero.fechaEmbarque = fechaHoraEmb;
                      // pasajero.asiento = 0;
                      pasajero.embarcado = 1;
                      Navigator.pop(context);
                      await EmbarcarPasajero(pasajero);
                    },
                    child: Text(
                      "Embarcar de todo modos",
                      style: TextStyle(fontSize: 18, color: AppColors.blueColor),
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                return Future.value(true);
              });
        });
  }

  Future _ModalPasajeroNoEncontrado(String numDocBuscar) {
    final titulo = "PASAJERO NO ENCONTRADO";
    final cuerpo = "El pasajero ${numDocBuscar} no se encuentra en la lista de reservas para los viajes programados para el día de hoy.";
    final _width = MediaQuery.of(context).size.width;
    _playErrorSound();
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.cancel,
                      color: AppColors.redColor,
                      size: _width * 0.1,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: _width * 0.5,
                      child: FittedBox(
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.redColor),
                        ),
                      ),
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
                          style: TextStyle(fontSize: null),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Aceptar",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                return Future.value(true);
              });
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

  ActualizarBajarPantalla(String tipoDoc, String numDoc, String codOperacion, String numViaje) async {
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    if (_hayConexion()) //si hay conexion a internet
    {
      await SincronizarViajeBolsa();
      var viajeServicio = new ViajeServicio();
      final viajes = await viajeServicio.obtenerViajeVinculadoBolsaSupervisor_v4(tipoDoc, numDoc, numViaje);

      if (viajes.rpta == "0") {
        List<Map<String, Object?>> listaViajesBolsa = await AppDatabase.instance.Listar(tabla: "viaje");

        await AppDatabase.instance.Eliminar(tabla: "viaje");
        await AppDatabase.instance.Eliminar(tabla: "punto_embarque");
        // await AppDatabase.instance.Eliminar(tabla: "pasajero");#JS:23112023
        await AppDatabase.instance.Eliminar(tabla: "tripulante");

        Viaje viajeExist = Viaje.fromJsonMapVinculadoLocal(listaViajesBolsa.firstWhere((element) => element["nroViaje"] == viajes.nroViaje)); //#JS:24112023

        viajes.fechaConsultada = DateTime.now().toString(); //#JS:24112023
        await AppDatabase.instance.Guardar(tabla: "viaje", value: viajes.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA EL VIAJE EN BD LOCAL

        final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
          viajes.nroViaje,
          viajes.codOperacion,
        );

        for (var puntoEmabarque in puntosEmabarque) {
          puntoEmabarque.nroViaje = viajes.nroViaje;
          await AppDatabase.instance.Guardar(tabla: "punto_embarque", value: puntoEmabarque.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PUNTOS DE EMBARQUE DEL VIAJE EN BD LOCAL
        }
        //#JS:24112023 -------------
        var fechaParse = DateTime.parse(viajeExist.fechaConsultada);
        var fechaConsult = DateFormat('dd/MM/yyyy HH:mm').format(fechaParse);

        var servicio = new PasajeroServicio();
        final listadoPrereservas = await servicio.obtener_nuevos_pasajeros(
          fecha: fechaConsult,
          nroViaje: viajes.nroViaje,
          tDocUsuario: _usuario.tipoDoc,
          nDocUsuario: _usuario.numDoc,
          codOperacion: viajes.subOperacionId,
        );
        //--------------

        for (var prereserva in listadoPrereservas) {
          // await AppDatabase.instance.Guardar(tabla: "pasajero", value: prereserva.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PRERESERVA DEL VIAJE EN BD LOCAL
          //#JS:24112023 -------------
          List<Map<String, Object?>> exist = await AppDatabase.instance.Listar(tabla: "pasajero", where: "tipoDoc='${prereserva.tipoDoc}' AND numDoc= '${prereserva.numDoc}'");

          if (exist.length > 0) {
            await AppDatabase.instance.Update(table: "pasajero", value: prereserva.toMapDatabase(), where: "tipoDoc='${prereserva.tipoDoc}' AND numDoc= '${prereserva.numDoc}'"); //#JS:24112023
          } else {
            await AppDatabase.instance.Guardar(tabla: "pasajero", value: prereserva.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PRERESERVA DEL VIAJE EN BD LOCAL
          }
          //--------------
        }

        for (var pasajero in viajes.pasajeros) {
          await AppDatabase.instance.EliminarUno(tabla: "pasajero", where: "tipoDoc='${pasajero.tipoDoc}' AND numDoc= '${pasajero.numDoc}'"); //JS:24112023
          await AppDatabase.instance.Guardar(tabla: "pasajero", value: pasajero.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PASAJEROS DEL VIAJE EN BD LOCAL
        }

        for (var j = 0; j < viajes.tripulantes.length; j++) {
          if (viajes.tripulantes[j].numDoc != "") {
            viajes.tripulantes[j].orden = "${j + 1}";
            await AppDatabase.instance.Guardar(tabla: "tripulante", value: viajes.tripulantes[j].toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA TRIPULANTES DEL VIAJE EN BD LOCAL
          }
        }

        List<Map<String, Object?>> listaViajeBolsa = await AppDatabase.instance.Listar(tabla: "viaje", where: "seleccionado = '1'");

        Viaje viajeselecionado = Viaje();
        if (listaViajeBolsa.isEmpty) {
          List<Map<String, Object?>> listaViajesBolsa = await AppDatabase.instance.Listar(tabla: "viaje");

          for (var i = 0; i < listaViajesBolsa.length; i++) {
            Viaje viaje = await ActualizarViajeEmbarqueBolsaBDLocal(listaViajesBolsa[i]);

            if (viaje.nroViaje == _usuario.viajeEmp) {
              await AppDatabase.instance.Update(
                  table: "viaje",
                  value: {
                    "seleccionado": "1",
                  },
                  where: "nroViaje = '${viaje.nroViaje}'");

              viajeselecionado = viaje;
            }
          }
        } else {
          viajeselecionado = Viaje.fromJsonMapVinculadoLocal(listaViajeBolsa[0]);
        }

        await Provider.of<ViajeProvider>(_navigator.context, listen: false).viajeActual(viaje: viajeselecionado);

        Navigator.pop(context, 'Cancel');
      } else {
        Navigator.pop(context, 'Cancel');
        return _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
      }
    } else {
      Navigator.pop(context, 'Cancel');
      return _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
    }
  }

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, title: titulo, desc: cuerpo, descTextStyle: TextStyle(fontSize: 15), autoHide: Duration(seconds: 2), dismissOnBackKeyPress: false, dismissOnTouchOutside: false);
  }
}
