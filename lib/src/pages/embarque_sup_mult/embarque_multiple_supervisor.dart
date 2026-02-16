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

class EmbarquesMultiplePage_Supervisor extends StatefulWidget {
  const EmbarquesMultiplePage_Supervisor({Key? key}) : super(key: key);

  @override
  State<EmbarquesMultiplePage_Supervisor> createState() => _EmbarquesMultiplePage_SupervisorState();
}

class _EmbarquesMultiplePage_SupervisorState extends State<EmbarquesMultiplePage_Supervisor> {
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

  /* NUEVAS VARIABLES */
  List<PuntoEmbarque> pe = [];
  PuntoEmbarque peActual = PuntoEmbarque(id: "0", nombre: "", nroViaje: "0", eliminado: 0);
  List<Pasajero> pasajerosTodos = [];
  List<Viaje> viajesMultiples = [];
  /* FIN NUEVAS VARIABLES */

  final player = AudioPlayer();

  late NavigatorState _navigator;
  bool _cambioDependencia = false;

  bool _mostarLoadin = false;

  bool estadoPECerrado = true;

  List listaPasajerosEPunto = [];

  bool CodigoExternoOdni = true;

  @override
  void initState() {
    _focusNumDoc.onKey = (node, event) {
      if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
        _validarInputDni();
      }
      return KeyEventResult.ignored;
    };

    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    ObtenerPuntosEmbarque();
    // _timer = new Timer.periodic(Duration(seconds: 3), (timer) {
    //   if (!_timer2.isActive) {
    //     _timer2 = new Timer.periodic(Duration(seconds: 5), (timer2) {
    //       if (_hayConexion()) {
    //         print(_timer2.tick);

    //         if (_timer2.tick == 1) {
    //           SincronizarViajeBolsa();
    //         }
    //       } else {
    //         _timer2.cancel();
    //       }

    //       setState(() {});
    //     });
    //   }

    //   //actualizar los datos del viaje cada 10 segundos
    // });
    super.initState();
    ingreso("INGRESO A EMBARQUE PASAJEROS");
    _showDialog();
  }

  /* NUEVOO */

  ObtenerPuntosEmbarque() async {
    List<Map<String, Object?>> listaPuntosEmbarque = await AppDatabase.instance.Listar(tabla: "punto_embarque", where: "nroViaje = '0'");
    List<PuntoEmbarque> _puntosEmbarque = listaPuntosEmbarque.map((e) => PuntoEmbarque.fromJsonMapBDLocal(e)).toList();

    setState(() {
      pe = _puntosEmbarque;
    });
  }

  /* FIN NUEVO  */

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
    viaje = Viaje.fromJsonMapVinculadoLocal(json);

    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero");
    List<Pasajero> _pasajeros = listaPasajeros.map((e) => Pasajero.fromJsonMapDBLocal(e)).toList();

    List<Map<String, Object?>> listaPuntosEmbarque = await AppDatabase.instance.Listar(tabla: "punto_embarque", where: "nroViaje = '${viaje.nroViaje}'");
    List<PuntoEmbarque> _puntosEmbarque = listaPuntosEmbarque.map((e) => PuntoEmbarque.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaTripulantes = await AppDatabase.instance.Listar(tabla: "tripulante", where: "nroViaje = '${viaje.nroViaje}'");

    List<Tripulante> _tripulantes = listaTripulantes.map((e) => Tripulante.fromJsonMap(e)).toList();

    viaje.pasajeros = _pasajeros;
    viaje.puntosEmbarque = _puntosEmbarque;
    viaje.tripulantes = _tripulantes;

    return viaje;
  }

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

  @override
  void didChangeDependencies() {
    _navigator = Navigator.of(context);
    setState(() {
      _cambioDependencia = true;
    });
    super.didChangeDependencies();
  }

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
  }

  @override
  void dispose() {
    _timer.cancel();
    _timer2.cancel();
    _focusNumDoc.dispose();
    _numDocController.dispose();
    super.dispose();
  }

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
          if (_hayConexion()) //si hay conexion a internet
          {
            setState(() {
              _mostarLoadin = true;
            });

            ingreso("BAJAR LA PANTALLA, ACTUALIZAR PRERESERVAS");

            return Future.delayed(Duration(seconds: 1), () async {
              // final embarquesBlocSuccess = context.read<EmbarquesSupScanerBloc>().state as EmbarquesSupScanerSuccess;
              // final vincularBlocSuccess = context.read<VincularInicioBloc>().state as VincularInicioSuccess;
              // ActualizarBajarPantalla(
              //   vincularBlocSuccess.tDocConducto1,
              //   vincularBlocSuccess.nDocConducto1,
              //   _usuario.codOperacion,
              //   embarquesBlocSuccess.numViaje,
              // );
              // _init();
              ActualizarBajarPantalla_Multiple();
              setState(() {
                _mostarLoadin = false;
                // _opcionSeleccionadaEmbarqueViaje = "-1";
              });
            });
          } else {
            return _mostrarModalRespuesta("Error", "No tiene conexión a internet", false).show();
          }
        },
        child: Scaffold(
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
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                              ),
                            ),
                            titleTextStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteColor,
                            ),
                            title: const Text('EMBARQUE DE PASAJEROS'),
                            floating: false,
                            elevation: 0,
                            pinned: true,
                            backgroundColor: AppColors.mainBlueColor,
                            expandedHeight: 10,
                            flexibleSpace: const FlexibleSpaceBar(
                              background: Column(
                                children: [
                                  // const SizedBox(
                                  //   height: 45,
                                  // ),
                                  // _informacionViaje(_viaje, width),
                                ],
                              ),
                            ),
                          ),
                          SliverSubHeader(
                            colorContainer: AppColors.mainBlueColor,
                            minHeight: 50, //87,
                            maxHeight: 50, //87,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.3,
                                      height: 28,
                                      child: const FittedBox(
                                        child: Text(
                                          "Pto Emb: ",
                                          style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.5,
                                      height: 32,
                                      child: FittedBox(
                                        child: Text(
                                          peActual.nombre,
                                          style: TextStyle(fontSize: 20, color: AppColors.turquesaLinea),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // if (viajesMultiples.isNotEmpty)
                                //   Column(
                                //     children: viajesMultiples.map((viaje) {
                                //       return Row(
                                //         mainAxisAlignment: MainAxisAlignment.center,
                                //         children: [
                                //           Row(
                                //             children: [
                                //               const Text(
                                //                 "Capac: ",
                                //                 style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                                //               ),
                                //               Text(
                                //                 viaje.cantAsientos.toString(),
                                //                 style: const TextStyle(
                                //                   fontSize: 18,
                                //                   color: AppColors.lightBlue,
                                //                   fontWeight: FontWeight.bold,
                                //                 ),
                                //               ),
                                //             ],
                                //           ),
                                //           SizedBox(width: width * 0.1),
                                //           Row(
                                //             children: [
                                //               const Text(
                                //                 "Embarcados: ",
                                //                 style: TextStyle(fontSize: 16, color: AppColors.whiteColor),
                                //               ),
                                //               Text(
                                //                 calcularCantidadEmbarcados(viaje).toString(),
                                //                 style: TextStyle(
                                //                   fontSize: 18,
                                //                   color: calcularCantidadEmbarcados(viaje) > 0 ? AppColors.lightGreenColor : AppColors.lightRedColor,
                                //                   fontWeight: FontWeight.bold,
                                //                 ),
                                //               ),
                                //             ],
                                //           ),
                                //         ],
                                //       );
                                //     }).toList(),
                                //   )
                              ],
                            ),
                          ),
                          SliverSubHeader(
                            minHeight: 70,
                            maxHeight: 70,
                            colorContainer: AppColors.whiteColor,
                            child: Column(
                              children: [
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
                // if (estadoPECerrado)
                //   Container(
                //     child: _botonCerrarPuntoEmbarque(width, _viaje),
                //   ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
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
      ],
    );
  }

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
                height: 30,
                width: width * 0.2,
                child: FittedBox(
                  child: const Icon(Icons.double_arrow, color: AppColors.whiteColor),
                ),
              ),
              Column(
                children: [
                  SizedBox(
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
            value: _opcionSeleccionadaEmbarqueViaje,
            items: items,
            hint: const Text('Seleccione'),
            iconSize: 30,
            isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
            isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
            onChanged: (value) async {
              if (value != '-1') {
                ingreso("SELECCIONO PUNTO DE EMBARQUE ${value}");
                //String nombre = Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque.firstWhereOrNull((element) => element.id == value)!.nombre;
                //Provider.of<ViajeProvider>(context, listen: false).AsignarPuntoEmbarque(value!, nombre);
                Navigator.pop(context);
                setState(() {
                  _mostrarCarga = true;
                });

                var viajeServicio = ViajeServicio();

                final rptaDatosEmb = await viajeServicio.obtenerDatosDeEmbarqueMultiple(_usuario, value.toString());
                final pasEmbarcados = (rptaDatosEmb["item3"] as List).map((e) => Pasajero.fromJsonMap(e)).toList();
                final pasNoEmbarcados = (rptaDatosEmb["item4"] as List).map((e) => Pasajero.fromJsonMap(e)).toList();

                if (rptaDatosEmb["item1"].toString() == "0") {
                  setState(() {
                    _mostrarCarga = false;
                    pasajerosTodos = pasEmbarcados + pasNoEmbarcados;
                    viajesMultiples = (rptaDatosEmb["item5"] as List).map((e) => Viaje.fromJsonMap(e)).toList();
                    _opcionSeleccionadaEmbarqueViaje = value.toString();
                    peActual = pe.firstWhereOrNull((element) => element.id == value)!;
                  });
                } else {
                  setState(() {
                    _mostrarCarga = false;
                    _mostrarMensaje("Sin resultados", AppColors.redColor);
                  });
                }

                _focusNumDoc.requestFocus();
              }
            },
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> getOpcionesDropdownPuntosEmbViaje() {
    List<DropdownMenuItem<String>> listaPuntosEmbarqueViaje = [];
    List<PuntoEmbarque> puntosEmbProvider = [];

    puntosEmbProvider = pe;

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

          Log.ingreso(context, "SUPERVISOR: PUNTO EMBARQUE ${p.nombre} CERRADO /  ${DateTime.now()} / ${responseSuccess ? "SINCRONIZADO" : "NO SINCRONIZADO"} ");

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

  _playSuccessSound() {
    player.play(AssetSource('sounds/success_sound.mp3'));
  }

  _playErrorSound() {
    player.play(AssetSource('sounds/error_sound2.mp3'));
  }

  _playBeepSound() {
    player.play(AssetSource('sounds/beep_sound.mp3'));
  }

  List<Widget> _listaWidgetPasajeros2() {
    List<Widget> lista = [];
    List<Widget> listaEmbarcados = [];

    Viaje _viajeProv = Provider.of<ViajeProvider>(context, listen: false).viaje;
    List<Pasajero> _pasajeros = pasajerosTodos; //_viajeProv.pasajeros;

    if (_pasajeros.isEmpty) {
      listaEmbarcados = [];
      lista.add(
        const Card(
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
          const Card(
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
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                height: 20,
                width: MediaQuery.of(context).size.width,
                child: FittedBox(
                  child: Text(
                    "Viaje: ${pasajero.apellidos}",
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                height: 20,
                width: MediaQuery.of(context).size.width * 0.4,
                child: FittedBox(
                  child: Text(
                    "Desembarque: ${pasajero.lugarDesembarque}",
                  ),
                ),
              ),
            ],
          ),
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

  Future<dynamic> _ModalRevertirEmbarque(Pasajero pasajero) {
    double _width = MediaQuery.of(context).size.width;
    String titulo = "";
    String cuerpo = "";
    late Widget icono;

    titulo = "REVERTIR EMBARQUE";
    cuerpo = "¿Seguro que desea REVERTIR el embarque del pasajero " + pasajero.nombres + "?";
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

  Future<void> EmbarcarPasajero(Pasajero pasajero) async {
    //Viaje _viajeProvider = await Provider.of<ViajeProvider>(context, listen: false).viaje;

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
    // pasajero.asiento = 0;
    pasajero.estado = 'A';
    final nuevoNroViaje = pasajero.nroViaje;
    setState(() {
      _mostrarCarga = true;
    });

    bool responseSuccess = false;
    bool errorValidacion = false;

    PasajeroServicio servicio = new PasajeroServicio();
    Response? resp = await servicio.cambiarEstadoPrereservaV5(pasajero, _usuario.codOperacion, nuevoNroViaje, _usuario.tipoDoc + _usuario.numDoc, pasajero.nroViaje);

    setState(() {
      _mostrarCarga = false;
    });

    if (resp != null) {
      final decodeData = json.decode(resp.body);

      if (decodeData["rpta"] == "0") {
        responseSuccess = true;
        _modalAutomatico('0', pasajero);
      }
      if (decodeData["rpta"] != "0" && decodeData["rpta"] != "500") {
        responseSuccess = false;
        errorValidacion = true;
        Log.ingreso(context, "SUPERVISOR: ${pasajero.numDoc} EMBARCADO /  ${DateTime.now()} / ${decodeData["mensaje"]} ");
        return _mostrarModalRespuesta("Error", decodeData["mensaje"], false).show();
      }
    } else {
      responseSuccess = false;
      return _mostrarModalRespuesta("Error", "Inténtelo otra vez", false).show();
    }

    // if (!errorValidacion) {
    //   Log.ingreso(context, "SUPERVISOR: ${pasajero.numDoc} EMBARCADO /  ${DateTime.now()} / ${responseSuccess ? "SINCRONIZADO" : "NO SINCRONIZADO"} ");

    //   //UPDATE LOCAL
    //   await AppDatabase.instance.Update(
    //     table: "pasajero",
    //     value: {
    //       "estado": "A",
    //       "idEmbarqueReal": _opcionSeleccionadaEmbarqueViaje,
    //       "embarcado": 1,
    //       "nroViaje": "${pasajero.nroViaje}",
    //       "sincronizar": responseSuccess ? "0" : "1",
    //       "embarcadoPor": CodigoExternoOdni ? "COD" : 'NDI',
    //       "coordenadas": "${pasajero.coordenadas}",
    //       "fechaEmbarque": "${pasajero.fechaEmbarque}",
    //     },
    //     where: "numDoc ='${pasajero.numDoc}' AND idRuta='${pasajero.idRuta}'",
    //   );

    //   await AppDatabase.instance.Update(
    //     table: "usuario",
    //     value: {
    //       "sesionSincronizada": responseSuccess ? "0" : "1",
    //     },
    //     where: "numDoc ='${_usuario.numDoc}'",
    //   );

    //   //ACTUALIZAMOS EL PROVIDER
    //   await Provider.of<ViajeProvider>(context, listen: false).embarcarPasajero(pasajero);
    //   setState(() {
    //     _mostrarCarga = false;
    //   });

    //   // Navigator.pop(context);
    //   _modalAutomatico('0', pasajero);
    // }
  }

  Future<void> RevertirPasajero(Pasajero pasajero) async {
    //Viaje _viajeProvider = await Provider.of<ViajeProvider>(context, listen: false).viaje;
    pasajero.embarcado = 0;
    pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
    pasajero.fechaEmbarque = DateFormat.yMd().add_Hms().format(new DateTime.now());

    // pasajero.asiento = 0;
    pasajero.estado = 'P';
    pasajero.idRuta = pasajero.idRuta;

    final nuevoNroViaje = pasajero.nroViaje;

    setState(() {
      _mostrarCarga = true;
    });

    bool responseSuccess = false;
    PasajeroServicio servicio = new PasajeroServicio();
    Response? resp = await servicio.cambiarEstadoPrereservaV5(pasajero, _usuario.codOperacion, nuevoNroViaje, _usuario.tipoDoc + _usuario.numDoc, pasajero.nroViaje);

    setState(() {
      _mostrarCarga = false;
    });

    if (resp != null) {
      final decodeData = json.decode(resp.body);
      if (decodeData["rpta"] == "0") {
        responseSuccess = true;
        return _modalAutomatico('1', pasajero);
      } else {
        responseSuccess = false;
        setState(() {
          _mostrarCarga = false;
        });
        return _mostrarModalRespuesta("Error", decodeData["mensaje"], false).show();
      }
    } else {
      responseSuccess = false;
      return _mostrarModalRespuesta("Error", "Ha ocurrido un error", false).show();
    }

    // Log.ingreso(context, "SUPERVISOR: ${pasajero.numDoc} REVERTIDO /  ${DateTime.now()} / ${responseSuccess ? "SINCRONIZADO" : "NO SINCRONIZADO"} ");

    // //UPDATE LOCAL
    // await AppDatabase.instance.Update(
    //   table: "pasajero",
    //   value: {
    //     "estado": "P",
    //     "idEmbarqueReal": '0',
    //     "embarcado": 0,
    //     "nroViaje": "0",
    //     "sincronizar": responseSuccess ? "0" : "1",
    //     "fechaDesembarque": "${pasajero.fechaDesembarque}",
    //   },
    //   where: "numDoc ='${pasajero.numDoc}' AND idRuta='${pasajero.idRuta}'",
    // );

    // await AppDatabase.instance.Update(
    //   table: "usuario",
    //   value: {
    //     "sesionSincronizada": responseSuccess ? "0" : "1",
    //   },
    //   where: "numDoc ='${_usuario.numDoc}'",
    // );

    // //ACTUALIZAMOS EL PROVIDER
    // await Provider.of<ViajeProvider>(context, listen: false).desembarcarPasajero(pasajero);
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
                if (_hayConexion()) {
                  _validarInputDni();
                } else {
                  _numDocController.text = "";

                  _mostrarMensaje("No tiene conexión a Internet", null);
                }
              },
              decoration: InputDecoration(
                label: Text(
                  CodigoExternoOdni ? "Tarjeta de embarque" : "Nro. Doc. de Identidad",
                  style: const TextStyle(
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

      if (numDocBuscar != "") {
        _numDocController.text = "";
        _focusNumDoc.requestFocus();

        Log.ingreso(context, "SUPERVISOR: DNI  $numDocBuscar /  ${DateTime.now()}");

        int tamCadena = numDocBuscar.length;

        String ultimoCaracter = numDocBuscar[tamCadena - 1];

        RegExp isLetterRegExp = RegExp(r'[a-z]', caseSensitive: false);
        bool isLetter(String letter) => isLetterRegExp.hasMatch(letter);

        final viaje = Provider.of<ViajeProvider>(context, listen: false).viaje;

        if (_usuario.codOperacion == 'O175') {
          if (isLetter(ultimoCaracter)) {
            numDocBuscar = numDocBuscar.substring(0, tamCadena - 1);
          }
        }

        if (viaje.caracterSplit.trim() != "" && viaje.indexLectura.trim() != "") {
          final caracter = numDocBuscar.indexOf(viaje.caracterSplit);
          if (caracter != -1) {
            numDocBuscar = numDocBuscar.trim().split(viaje.caracterSplit)[int.parse(viaje.indexLectura)];
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

        Log.ingreso(context, "SUPERVISOR: DNI  LIMPIO ${numDocBuscar} /  ${DateTime.now()}");

        //Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
        bool encontrado = false;

        Pasajero pasajero = Pasajero();

        if (pasajerosTodos.isNotEmpty) {
          if (!CodigoExternoOdni) {
            var pasajeroEncontrado = pasajerosTodos.firstWhereOrNull((element) => element.numeroDoc == numDocBuscar);
            if (pasajeroEncontrado != null) {
              pasajero = pasajeroEncontrado;
              numDocBuscar = pasajeroEncontrado.numDoc;
              encontrado = true;
            } else {
              encontrado = false;
            }
          } else {
            for (int i = 0; i < pasajerosTodos.length; i++) {
              if (pasajerosTodos[i].numDoc.trim() == numDocBuscar) {
                pasajero = pasajerosTodos[i];
                encontrado = true;
                break;
              }
            }
          }

          if (encontrado == false) {
            Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} NO ENCONTRADO /  ${DateTime.now()}");
            _ModalPasajeroNoEncontrado(numDocBuscar); //JS: 18/7/23 Pasajeros no encontrado
            return;
          }

          if (encontrado) {
            switch (pasajero.embarcado) {
              case 0:
                if (pasajero.idEmbarque != _opcionSeleccionadaEmbarqueViaje) {
                  Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} NO PUNTO DE EMBARQUE /  ${DateTime.now()}");
                  return await _mostrarModalPasajeroNoPuntoEmbarque(pasajero); //JS: 18/7/23 No es su lugar de embarque
                }
                // if (viajeActual.codRuta != pasajero.idRuta) {
                //   Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} NO RUTA /  ${DateTime.now()}");
                //   return await _mostrarModalPasajeroNoRuta(pasajero);
                // }
                // if (viajeActual.servicio != pasajero.servicio) {
                //   Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} NO SERVICIO /  ${DateTime.now()}");
                //   return await _mostrarModalPasajeroNoServicio(pasajero);
                // }
                // String fechaHoraSalidaViaje = (viajeActual.fechaSalida + " " + viajeActual.horaSalida);
                // if (fechaHoraSalidaViaje != pasajero.fechaViaje) {
                //   Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} NO FECHA O HORA /  ${DateTime.now()}");
                //   return await _mostrarModalPasajeroNoFecha(pasajero);
                // }
                if (pasajero.idEmbarque == _opcionSeleccionadaEmbarqueViaje) {
                  Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} ENCONTRADO /  ${DateTime.now()}");
                  return await EmbarcarPasajero(pasajero); // JS: 18/07/23 PASAJERO EMBARCADO
                }
                break;
              case 1:
                Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} YA EMBARCADO /  ${DateTime.now()}");
                return _mostrarModalAutomaticoYaEmbarcado(pasajero); //Ya embarcado
              default:
            }
          }
        } else {
          Log.ingreso(context, "SUPERVISOR: ${numDocBuscar} NO HAY PASAJEROS POR EMBARCAR /  ${DateTime.now()}");
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

    bool puedeCerrarModal = false;

    return showDialog(
        barrierDismissible: puedeCerrarModal,
        context: context,
        builder: (context) {
          /*Timer modalTimer =*/ new Timer(Duration(seconds: 4), () {
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
                        Text.rich(
                          TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                            const TextSpan(
                              text: "Viaje : ",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: pasajero.apellidos.toString(),
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
                return Future.value(puedeCerrarModal);
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

  // Future _mostrarModalPasajeroNoRuta(Pasajero pasajero) {
  //   final _width = MediaQuery.of(context).size.width;
  //   final titulo = "RECHAZADO";
  //   final cuerpo = "El pasajero " + pasajero.nombres + " tiene una reserva para un viaje de otra ruta: ${pasajero.ruta}";
  //   final icono = Icon(
  //     Icons.no_transfer,
  //     color: AppColors.blueDarkColor,
  //     size: _width * 0.1,
  //   );
  //   final color = AppColors.blueDarkColor;
  //   _playErrorSound();
  //   return showDialog(
  //       barrierDismissible: false,
  //       context: context,
  //       builder: (context) {
  //         return WillPopScope(
  //             child: AlertDialog(
  //               title: Row(
  //                 children: [
  //                   icono,
  //                   const SizedBox(
  //                     width: 10,
  //                   ),
  //                   SizedBox(
  //                     width: _width * 0.5,
  //                     child: FittedBox(
  //                       child: Text(
  //                         titulo,
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(color: color),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               content: SingleChildScrollView(
  //                 child: Container(
  //                   width: double.infinity,
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.start,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         cuerpo,
  //                         textAlign: TextAlign.start,
  //                         style: TextStyle(fontSize: null),
  //                       ),
  //                       if (pasajero.asiento > 0)
  //                         Text.rich(
  //                           TextSpan(style: TextStyle(color: AppColors.blackColor), children: <TextSpan>[
  //                             TextSpan(
  //                               text: "Asiento : ",
  //                               style: TextStyle(
  //                                 fontSize: 18,
  //                               ),
  //                             ),
  //                             TextSpan(
  //                               text: pasajero.asiento.toString(),
  //                               style: TextStyle(
  //                                 fontSize: 18,
  //                                 color: color,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                           ]),
  //                         ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               actions: [
  //                 TextButton(
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                   },
  //                   child: Text(
  //                     "Cancelar",
  //                     style: TextStyle(fontSize: 18, color: AppColors.redColor),
  //                   ),
  //                 ),
  //                 TextButton(
  //                   onPressed: () async {
  //                     Log.ingreso(context, "SUPERVISOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
  //                     Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
  //                     String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());
  //                     // pasajero.nroViaje = viajeActual.nroViaje;
  //                     pasajero.estado = 'A';
  //                     pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
  //                     pasajero.fechaEmbarque = fechaHoraEmb;
  //                     // pasajero.asiento = 0;
  //                     pasajero.embarcado = 1;
  //                     Navigator.pop(context);
  //                     await EmbarcarPasajero(pasajero);
  //                     // _modalAutomatico('0', pasajero);
  //                   },
  //                   child: Text(
  //                     "Embarcar de todo modos",
  //                     style: TextStyle(fontSize: 18, color: AppColors.blueColor),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             onWillPop: () {
  //               return Future.value(true);
  //             });
  //       });
  // }

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
                      Log.ingreso(context, "SUPERVISOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
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
                      Log.ingreso(context, "SUPERVISOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
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
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cuerpo,
                          textAlign: TextAlign.start,
                          style: const TextStyle(fontSize: null),
                        ),
                        if (pasajero.asiento > 0)
                          Text.rich(
                            TextSpan(style: const TextStyle(color: AppColors.blackColor), children: <TextSpan>[
                              const TextSpan(
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
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(fontSize: 18, color: AppColors.redColor),
                    ),
                  ),
                  // TextButton(
                  //   onPressed: () async {
                  //     Log.ingreso(context, "SUPERVISOR: ${pasajero.numDoc} EMBARCAR DE TODOS MODOS /  ${DateTime.now()} ");
                  //     Viaje viajeActual = Provider.of<ViajeProvider>(context, listen: false).viaje;
                  //     String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());
                  //     // pasajero.nroViaje = viajeActual.nroViaje;
                  //     pasajero.estado = 'A';
                  //     pasajero.idEmbarqueReal = _opcionSeleccionadaEmbarqueViaje;
                  //     pasajero.fechaEmbarque = fechaHoraEmb;
                  //     // pasajero.asiento = 0;
                  //     pasajero.embarcado = 1;
                  //     Navigator.pop(context);
                  //     await EmbarcarPasajero(pasajero);
                  //   },
                  //   child: const Text(
                  //     "Embarcar de todo modos",
                  //     style: TextStyle(fontSize: 18, color: AppColors.blueColor),
                  //   ),
                  // ),
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

  ActualizarBajarPantalla_Multiple() async {
    _showDialogSincronizandoDatos(context, "SINCRONIZANDO DATOS");

    var viajeServicio = ViajeServicio();

    final rptaDatosEmb = await viajeServicio.obtenerDatosDeEmbarqueMultiple(_usuario, _opcionSeleccionadaEmbarqueViaje);
    final pasEmbarcados = (rptaDatosEmb["item3"] as List).map((e) => Pasajero.fromJsonMap(e)).toList();
    final pasNoEmbarcados = (rptaDatosEmb["item4"] as List).map((e) => Pasajero.fromJsonMap(e)).toList();

    viajesMultiples = (rptaDatosEmb["item5"] as List).map((e) => Viaje.fromJsonMap(e)).toList();

    Navigator.pop(context, 'Cancel');

    if (rptaDatosEmb["item1"].toString() == "0") {
      setState(() {
        pasajerosTodos = pasEmbarcados + pasNoEmbarcados;
        viajesMultiples = (rptaDatosEmb["item5"] as List).map((e) => Viaje.fromJsonMap(e)).toList();
      });
    } else {
      return _mostrarModalRespuesta("Error", "No se pudo sincronizar", false).show();
    }
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
        // await AppDatabase.instance.Eliminar(tabla: "pasajero"); #JS:24112023
        await AppDatabase.instance.Eliminar(tabla: "tripulante");

        Viaje viajeExist = Viaje.fromJsonMapVinculadoLocal(listaViajesBolsa.firstWhere((element) => element["nroViaje"] == viajes.nroViaje));

        viajes.fechaConsultada = DateTime.now().toString();
        await AppDatabase.instance.Guardar(tabla: "viaje", value: viajes.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA EL VIAJE EN BD LOCAL

        final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
          viajes.nroViaje,
          viajes.codOperacion,
        );

        for (var puntoEmabarque in puntosEmabarque) {
          puntoEmabarque.nroViaje = viajes.nroViaje;
          await AppDatabase.instance.Guardar(tabla: "punto_embarque", value: puntoEmabarque.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PUNTOS DE EMBARQUE DEL VIAJE EN BD LOCAL
        }

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

        for (var prereserva in listadoPrereservas) {
          //await AppDatabase.instance.Guardar(tabla: "pasajero", value: prereserva.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PRERESERVA DEL VIAJE EN BD LOCAL
          List<Map<String, Object?>> exist = await AppDatabase.instance.Listar(tabla: "pasajero", where: "tipoDoc='${prereserva.tipoDoc}' AND numDoc= '${prereserva.numDoc}'");

          if (exist.length > 0) {
            await AppDatabase.instance.Update(table: "pasajero", value: prereserva.toMapDatabase(), where: "tipoDoc='${prereserva.tipoDoc}' AND numDoc= '${prereserva.numDoc}'"); //#JS:24112023
          } else {
            await AppDatabase.instance.Guardar(tabla: "pasajero", value: prereserva.toMapDatabase());
          }
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
    return AwesomeDialog(
        context: context,
        dialogType: success ? DialogType.success : DialogType.error,
        animType: AnimType.topSlide,
        title: titulo,
        desc: cuerpo,
        descTextStyle: TextStyle(fontSize: 15),
        autoHide: Duration(seconds: 2),
        dismissOnBackKeyPress: false,
        dismissOnTouchOutside: false);
  }
}
