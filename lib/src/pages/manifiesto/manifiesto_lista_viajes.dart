import 'package:embarques_tdp/src/components/drawer.dart';
import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:http/http.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../models/viaje.dart';
import '../../utils/app_colors.dart';

class ListaViajesPage extends StatefulWidget {
  const ListaViajesPage({super.key});

  @override
  State<ListaViajesPage> createState() => _ListaViajesPageState();
}

class _ListaViajesPageState extends State<ListaViajesPage> {
  bool _mostrarCarga = false;
  late Usuario _usuario;
  String _opcionSeleccionadaPuntoEmbarque = "-1";
  //List<Ruta> _rutas = [];
  List<PuntoEmbarque> _puntosEmbarque = [];
  DateTime _fechaSeleccionada = DateTime.now();
  List<Viaje> _viajesEncontrados = [];
  bool _impreso = false;

  @override
  initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    /*_rutas = Provider.of<RutasProvider>(context, listen: false).rutas;
    if (_rutas.isNotEmpty) {
      _opcionSeleccionadaRuta = _rutas.first.codRuta;
    }*/
    _puntosEmbarque = Provider.of<PuntoEmbarqueProvider>(context, listen: false).puntosEmbarque;
    if (_puntosEmbarque.isNotEmpty) {
      _opcionSeleccionadaPuntoEmbarque = _puntosEmbarque.first.nombre;
    }
    super.initState();
    ingreso("INGRESO A MANIFIESTO");
  }

  @override
  void dispose() {
    super.dispose();
  }

  ingreso(String Mensaje) async {
    var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    await AppDatabase.instance.NuevoRegistroBitacora(
      context,
      "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
      usuarioLogin.codOperacion,
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "Embarque ${usuarioLogin.perfil}: $Mensaje",
      "Exitoso",
    );
  }

  @override
  Widget build(BuildContext context) {
    _viajesEncontrados = Provider.of<ViajeProvider>(context, listen: false).GetListViaje;

    Intl.defaultLocale = 'es';
    initializeDateFormatting();
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(const Duration(seconds: 1), () async {
            if (_opcionSeleccionadaPuntoEmbarque == "-1") {
              // _mostrarMensaje(
              //     "Seleccione un punto de embarque", AppColors.redColor);

              await Provider.of<PuntoEmbarqueProvider>(context, listen: false).obtenerPuntosEmbarque(_usuario.codOperacion);

              ingreso("LISTO LOS PUNTOS DE EMBARQUE  - BAJAR LA PANTALLA");
            } else {
              String ptoEmbarqueSeleccionado = _opcionSeleccionadaPuntoEmbarque;
              String fechaSeleccionada = DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);
              ViajeServicio servicio = new ViajeServicio();
              setState(() {
                _mostrarCarga = true;
              });
              List<Viaje> viajesBusqueda = await servicio.obtenerViajesManifiesto(
                ptoEmbarqueSeleccionado,
                fechaSeleccionada,
                _usuario,
                _impreso == true ? '1' : '0',
              );

              ingreso("OBTENER VIAJES MANIFIESTO - BAJAR LA PANTALLA");

              ViajeProvider viajeP = Provider.of<ViajeProvider>(context, listen: false);
              viajeP.AsignarListaViaje(viajesBusqueda);

              setState(() {
                _viajesEncontrados = viajeP.GetListViaje;
                _mostrarCarga = false;
              });
            }
          });
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: const Text('Manifiestos'),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        _tituloSmallScreen(width),
                        const SizedBox(
                          height: 15,
                        ),
                        _filtrosSmallScreen(width),
                        const SizedBox(
                          height: 10,
                        ),
                        //LISTA DE PASAJEROS

                        Container(
                          //height: height * 0.55,
                          padding: const EdgeInsets.only(left: 5, right: 5),

                          //color: AppColors.lightGreenColor,
                          child: _viajesEncontrados.isEmpty
                              ? const Column(
                                  children: [
                                    Card(
                                      child: ListTile(
                                        title: Text(
                                          'No hay viajes para mostrar',
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: context.watch<ViajeProvider>().GetListViaje.map((e) {
                                  return _cardWidget(e);
                                }).toList()
                                  // _listaWidgetViajes()
                                  ),
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
    );
  }

  _tituloSmallScreen(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          width: width,
          child: const FittedBox(
            child: Text(
              'MANIFIESTOS DE PASAJEROS POR VIAJE',
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
              child: const FittedBox(
                child: Text("Pto Embarque:"),
              ),
            ),
            Expanded(
              child: Container(
                height: 25,
                //padding: const EdgeInsets.only(left: 10, right: 25),
                child: _dropdownPuntosEmbarque(width),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              width: width * 0.3,
              height: 25,
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: const FittedBox(
                child: Text("Fecha: "),
              ),
            ),
            Container(
              width: width * 0.7,
              height: 25,
              padding: const EdgeInsets.only(left: 0, right: 25),
              child: _datetimePicker(),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              width: width * 0.3,
              height: 25,
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: const FittedBox(
                child: Text("Estado: "),
              ),
            ),
            Container(
              width: width * 0.65,
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  value: _impreso == true ? '1' : '0',
                  items: [
                    DropdownMenuItem(
                      value: '1',
                      child: SizedBox(
                          width: width * 0.55,
                          height: 25,
                          child: const FittedBox(
                            child: Text(
                              "Impreso",
                            ),
                          )),
                    ),
                    DropdownMenuItem(
                      value: '0',
                      child: SizedBox(
                          width: width * 0.55,
                          height: 25,
                          child: const FittedBox(
                            child: Text(
                              "No Impreso",
                            ),
                          )),
                    ),
                  ],
                  iconSize: 25,
                  isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
                  //isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
                  onChanged: (value) {
                    if (value != '-1') {
                      setState(() {
                        _impreso = value == '1' ? true : false;
                      });
                      // Provider.of<ViajeProvider>(context, listen: false)
                      //     .ListarViajes(_impreso == true ? '1' : '0');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: width * 0.35,
              height: 35,
              child: TextButton(
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
                  if (_opcionSeleccionadaPuntoEmbarque == "-1") {
                    _mostrarMensaje("Seleccione un punto de embarque", AppColors.redColor);
                  } else {
                    String ptoEmbarqueSeleccionado = _opcionSeleccionadaPuntoEmbarque;
                    String fechaSeleccionada = DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);
                    ViajeServicio servicio = new ViajeServicio();
                    setState(() {
                      _mostrarCarga = true;
                    });
                    List<Viaje> viajesBusqueda = await servicio.obtenerViajesManifiesto(ptoEmbarqueSeleccionado, fechaSeleccionada, _usuario, _impreso == true ? '1' : '0');

                    ViajeProvider viajeP = Provider.of<ViajeProvider>(context, listen: false);

                    viajeP.AsignarListaViaje(viajesBusqueda);
                    setState(() {
                      _viajesEncontrados = viajeP.GetListViaje;
                      _mostrarCarga = false;
                    });
                  }
                },
                child: const Text(
                  "Buscar",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        // Container(
        //   padding: EdgeInsets.only(right: 25),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.end,
        //     children: [
        //       FlutterSwitch(
        //         height: 30,
        //         width: 70,
        //         padding: 1.5,
        //         toggleSize: 30,
        //         value: _impreso,
        //         valueFontSize: 25.0,
        //         activeColor: AppColors.greenColor,
        //         activeIcon: Icon(
        //           Icons.print,
        //           color: AppColors.greenColor,
        //         ),
        //         inactiveColor: AppColors.redColor,
        //         inactiveIcon: Icon(
        //           Icons.print_disabled,
        //           color: AppColors.redColor,
        //         ),
        //         onToggle: (val) async {
        //           setState(() {
        //             _impreso = val;
        //           });
        //         },
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    ).then((value) {
      setState(() {
        _fechaSeleccionada = value ?? DateTime.now();
      });
    });
  }

  Widget _datetimePicker() {
    return MaterialButton(
      onPressed: _showDatePicker,
      child: Padding(
          padding: const EdgeInsets.all(0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)),
              /*Spacer(),
              Icon(Icons.date_range)*/
            ],
          )),
    );
  }

  Widget _dropdownPuntosEmbarque(double width) {
    List<DropdownMenuItem<String>> items = [];
    items = getOpcionesDropdownPuntosEmbarque(width);

    return Container(
      //padding: const EdgeInsets.only(left: 10),.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      //LO COMENTADO ES PARA QUE CUANDO ABRA SELECTOR SE HAGA EN ANCHO COMPLETO
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          //key: _keyOrigenes,
          value: _opcionSeleccionadaPuntoEmbarque,
          items: items,
          hint: const Text('---'),
          iconSize: 25,
          isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
          //isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
          onChanged: (value) {
            if (value != '-1') {
              setState(() {
                _opcionSeleccionadaPuntoEmbarque = value.toString();
              });

              ingreso("SELECIÓN PUNTO DE EMBARQUE ${value.toString()}");
            }
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> getOpcionesDropdownPuntosEmbarque(double width) {
    List<DropdownMenuItem<String>> listaPuntosEmbarque = [];

    if (_puntosEmbarque.isEmpty) {
      listaPuntosEmbarque.add(const DropdownMenuItem<String>(
        value: "-1",
        child: Text(
          "---",
        ),
      ));
    } else {
      for (int i = 0; i < _puntosEmbarque.length; i++) {
        listaPuntosEmbarque.add(
          DropdownMenuItem(
            value: _puntosEmbarque[i].nombre,
            child: SizedBox(
                width: width * 0.55,
                height: 25,
                child: FittedBox(
                  child: Text(
                    _puntosEmbarque[i].nombre,
                  ),
                )
                /*style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.blueColor),*/
                ),
          ),
        );
      }
    }

    return listaPuntosEmbarque;
  }

  _mostrarMensaje(String mensaje, Color? color) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        mensaje,
        style: const TextStyle(color: AppColors.whiteColor),
        textAlign: TextAlign.center,
      ),
      duration: const Duration(seconds: 2),
      //behavior: SnackBarBehavior.floating,
      //margin: EdgeInsets.only(bottom: 50, right: 50, left: 50),
      backgroundColor: color,
    ));
  }

  Widget _cardWidget(Viaje viaje) {
    return Card(
      child: ListTile(
          //leading: FlutterLogo(size: 72.0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                height: 25,
                child: FittedBox(
                  child: Text(
                    "Unidad: ${viaje.unidad}",
                    //pasajero.apellidos + ", " + pasajero.nombres,
                    style: const TextStyle(color: AppColors.mainBlueColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  child: Text(
                    "Hora: ${viaje.horaSalida}",
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    child: FittedBox(
                      child: Text("${viaje.origen} - ${viaje.destino}"),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    child: FittedBox(
                      child: Text(
                        "Ocupados: ${viaje.totalEmbarcados}",
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    child: FittedBox(
                      child: Text(
                        "Servicio: ${viaje.servicio}",
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    child: FittedBox(
                      child: Text(
                        "Libres: ${viaje.cantDisponibles.toString()}",
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Text(
                      "Empresa: ${viaje.subOperacionNombre}",
                      overflow: TextOverflow.ellipsis, // Si el texto es demasiado largo, se mostrará con "..."
                      //style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    alignment: Alignment.centerRight,
                    height: 23,
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: FittedBox(
                      child: Text(
                        "Embarcados: ${viaje.cantEmbarcados.toString()}",
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    child: const FittedBox(
                      child: Text("Embarque: "),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    child: FittedBox(
                      child: Text(viaje.estadoEmbarque == 0 ? "Abierto" : "Cerrado",
                          style: TextStyle(
                            color: viaje.estadoEmbarque == 0 ? AppColors.greenColor : AppColors.redColor,
                          )),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 23,
                    child: FittedBox(
                      child: Text(
                        "No Embarcados: ${viaje.cantReservados.toString()}",
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          //trailing: Icon(Icons.more_vert),
          //isThreeLine: true,
          onTap: () async {
            setState(() {
              _mostrarCarga = true;
            });
            //OBTENER LOS PASAJEROS
            PasajeroServicio servicio = new PasajeroServicio();

            List<Pasajero> pasajeros = await servicio.obtener_manifiesto_viaje_x_puntoEmbarque(viaje.nroViaje, viaje.codOperacion, viaje.nombrePuntoEmbarqueActual);

            viaje.pasajeros = pasajeros;

            await Provider.of<ViajeProvider>(context, listen: false).viajeManifiestoActual(viaje: viaje);

            setState(() {
              _mostrarCarga = false;
            });
            ingreso("CLICK EN EL VIAJE ${viaje.nroViaje.toString()}");

            Navigator.pushNamed(context, 'manifiestoViaje', arguments: {"viaje", viaje});
          }),
    );
  }
}
