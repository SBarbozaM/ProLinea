import 'package:embarques_tdp/src/components/drawer.dart';
import 'package:embarques_tdp/src/models/ruta.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

class FinalizarViaje extends StatefulWidget {
  const FinalizarViaje({super.key});

  @override
  State<FinalizarViaje> createState() => _FinalizarViajeState();
}

class _FinalizarViajeState extends State<FinalizarViaje> {
  bool _mostrarCarga = false;
  late Usuario _usuario;
  String _opcionSeleccionadaRuta = "-1";
  List<Ruta> _rutas = [];
  DateTime _fechaSeleccionada = DateTime.now();
  List<Viaje> _viajesEncontrados = [];

  @override
  initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    _rutas = Provider.of<RutasProvider>(context, listen: false).rutas;
    if (_rutas.isNotEmpty) {
      _opcionSeleccionadaRuta = _rutas.first.codRuta;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(Duration(seconds: 2), () async {
            await Provider.of<RutasProvider>(context, listen: false).obtenerRutas(_usuario.codOperacion);
          });
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Finalizar Viajes'),
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
                        padding: EdgeInsets.only(left: 0, right: 0),

                        //color: AppColors.lightGreenColor,
                        child: _viajesEncontrados.isEmpty
                            ? Card(
                                child: ListTile(
                                  title: Text('No hay viajes para mostrar'),
                                ),
                              )
                            : Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: ExpansionPanelList(
                                  expandedHeaderPadding: EdgeInsets.all(10),
                                  expansionCallback: (int index, bool isExpanded) async {
                                    setState(() {
                                      _viajesEncontrados[index].isExpanded = !isExpanded;
                                    });
                                  },
                                  children: _viajesEncontrados.map<ExpansionPanel>((Viaje viaje) {
                                    return ExpansionPanel(
                                      // hasIcon: false,
                                      headerBuilder: (BuildContext context, bool isExpanded) {
                                        return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                viaje.isExpanded = !isExpanded;
                                              });
                                            },
                                            child: CardViaje(viaje: viaje));
                                      },
                                      body: Container(
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                      Expanded(child: _datetimePickerViajeFinalizado(viaje)),
                                                      Expanded(child: _timePickerViajeFinalizado(viaje)),
                                                    ]),
                                                  ),
                                                  TextButonFinalizarViaje(context, viaje)
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      isExpanded: viaje.isExpanded,
                                    );
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

  _tituloSmallScreen(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: width * 0.9,
          child: FittedBox(
            child: Text(
              'LISTA DE VIAJES NO FINALIZADOS',
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
        SizedBox(
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
                  if (_opcionSeleccionadaRuta == "-1") {
                    _mostrarMensaje("Seleccione una ruta", AppColors.redColor);
                  } else {
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
                  }
                },
                child: Text(
                  "Buscar",
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: Locale('es'),
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
          padding: EdgeInsets.all(0),
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

  // AwesomeDialog _modalFinalizarViaje(Viaje viaje) {
  //   final _width = MediaQuery.of(context).size.width;
  //   return AwesomeDialog(
  //     context: context,
  //     //customHeader: null,
  //     animType: AnimType.topSlide,
  //     body:
  //   );
  // }

  Widget _datetimePickerViajeFinalizado(Viaje viaje) {
    return MaterialButton(
      onPressed: () {
        showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          locale: Locale('es'),
        ).then((value) {
          print(value);
          setState(() {
            if (value != null) {
              viaje.FechaLlegada = "${value.day}/${value.month}/${value.year}";
            }
          });
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 10),
            child: Text(
              "Fecha",
              style: TextStyle(fontSize: 12, color: AppColors.blueColor),
            ),
          ),
          Container(
              decoration: BoxDecoration(color: AppColors.lightgreyColor.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(viaje.FechaLlegada),
                  /*Spacer(),
                  Icon(Icons.date_range)*/
                ],
              )),
        ],
      ),
    );
  }

  Widget _timePickerViajeFinalizado(Viaje viaje) {
    return MaterialButton(
      onPressed: () {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        ).then((value) {
          setState(() {
            if (value != null) {
              viaje.HoraLLegada = "${value.hour}:${value.minute}";
            }
          });
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 10),
            child: Text(
              "Hora",
              style: TextStyle(fontSize: 12, color: AppColors.blueColor),
            ),
          ),
          Container(
              decoration: BoxDecoration(color: AppColors.lightgreyColor.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(viaje.HoraLLegada),
                  /*Spacer(),
                  Icon(Icons.date_range)*/
                ],
              )),
        ],
      ),
    );
  }

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
