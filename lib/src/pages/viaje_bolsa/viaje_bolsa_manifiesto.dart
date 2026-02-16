import 'dart:async';

// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:diacritic/diacritic.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../components/warning_widget_internet.dart';
import '../../models/pasajero.dart';
import '../../models/punto_embarque.dart';
import '../../models/usuario.dart';
import '../../models/viaje.dart';
import '../../providers/impresoraProvider.dart';
import '../../providers/providers.dart';
import '../../services/pto_embarque_servicio.dart';
import '../../utils/app_colors.dart';

class ViajeBolsaManifiestoPage extends StatefulWidget {
  const ViajeBolsaManifiestoPage({Key? key}) : super(key: key);

  @override
  State<ViajeBolsaManifiestoPage> createState() => _ViajeBolsaManifiestoPageState();
}

class _ViajeBolsaManifiestoPageState extends State<ViajeBolsaManifiestoPage> {
  late Timer _timer;
  late Usuario _usuario;
  String _opcionSeleccionadaEmbarqueViaje = "";
  String _nombrepuntoDeEmbarque = "";
  List<PuntoEmbarque> pe = [];

  bool _puedeImprimir = false;

  // late BluetoothDevice? _impresoraActual;
  // BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  @override
  void initState() {
    // _impresoraActual = Provider.of<ImpresoraProvider>(context, listen: false).impresoraVinculada;
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _nombrepuntoDeEmbarque = Provider.of<ViajeProvider>(context, listen: false).nombrepuntoDeEmbarque;
    _timer = new Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {});
    });

    _opcionSeleccionadaEmbarqueViaje = Provider.of<ViajeProvider>(context, listen: false).puntoDeEmbarque;

    // _init();
    super.initState();

    ingreso("INGRESO A MANIFIESTO EMBARQUE");
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
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  _init() async {
    setState(() {
      _opcionSeleccionadaEmbarqueViaje = Provider.of<ViajeProvider>(context, listen: false).puntoDeEmbarque;
    });
    // pe =
    //     await Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque;
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Viaje _viaje = Provider.of<ViajeProvider>(context, listen: false).viaje;
    // _opcionSeleccionadaEmbarqueViaje =
    //     Provider.of<ViajeProvider>(context, listen: false)
    //         .opcSeleccionadaEmbarqueManifiesto;
    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(Duration(seconds: 1), () async {
            await Provider.of<ViajeProvider>(context, listen: false).sincronizarViajeNuevosPasajerosBolsa(_usuario.tipoDoc, _usuario.numDoc, _usuario.viajeEmp, context);

            setState(() {});
          });
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.blackColor,
              ),
            ),
            elevation: 0,
            centerTitle: true,
            backgroundColor: AppColors.whiteColor,
            title: Text(
              'MANIFIESTO DE PASAJEROS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    children: [
                      _informacionViaje(_viaje, width, height),
                      const SizedBox(
                        height: 15,
                      ),
                    ],
                  ),
                ),
              ),
              WarningWidgetInternet(),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          // floatingActionButton: FloatingActionButton(
          //   tooltip: _impresoraActual == null
          //       ? "No vinculada"
          //       : _impresoraActual?.name == ""
          //           ? "Sin nombre"
          //           : _impresoraActual?.name,
          //   onPressed: _impresoraActual == null
          //       ? null
          //       : !_puedeImprimir
          //           ? null
          //           : () async {
          //               if (_opcionSeleccionadaEmbarqueViaje == '-1') {
          //                 return;
          //               }

          //               ingreso("IMPRIMIR MANIFIESTO");
          //               _imprimirManifiesto(_viaje);
          //             },
          //   backgroundColor: _impresoraActual == null
          //       ? AppColors.greyColor
          //       : !_puedeImprimir
          //           ? AppColors.greyColor
          //           : AppColors.redColor,
          //   //foregroundColor: AppColors.lightGreenColor,
          //   child: _impresoraActual == null ? Icon(Icons.print_disabled) : Icon(Icons.print),
          // ),
        
        ),
      ),
    );
  }

  _informacionViaje(Viaje _viaje, double width, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _filtrosManifiesto(width),

        _informacionManifiesto(_viaje, width),
        SizedBox(
          height: 10,
        ),
        _manifiestoDePasajerosLista(_viaje, width),
        //_manifiestoDePasajerosTabla(_viaje, width),
      ],
    );
  }

  Widget _informacionManifiesto(Viaje _viaje, double width) {
    List<int> _datosTotales = _calcularDatosTotales(_viaje);

    return Column(
      children: [
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 28,
                child: FittedBox(
                  child: Text(
                    "Pto Emb: ",
                    style: TextStyle(fontSize: 16, color: AppColors.blackColor),
                  ),
                ),
              ),
              SizedBox(width: 20),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 32,
                      child: FittedBox(
                        child: Text(
                          "${Provider.of<ViajeProvider>(context, listen: false).nombrepuntoDeEmbarque}",
                          style: TextStyle(fontSize: 20, color: AppColors.mainBlueColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 20,
                    child: FittedBox(
                        child: Text(
                      "Capacidad: ${_viaje.cantAsientos}",
                      style: TextStyle(
                        color: AppColors.mainBlueColor,
                      ),
                    )),
                  ),
                  Container(
                    height: 20,
                    child: FittedBox(
                      child: Text(
                        "Embarcados: " + _datosTotales[0].toString(),
                        style: TextStyle(
                          color: AppColors.greenColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 20,
                    child: FittedBox(
                      child: Text(
                        "Ocupados: ${_datosTotales[3]}",
                        style: TextStyle(
                          color: AppColors.greyColor,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 20,
                    child: FittedBox(
                      child: Text(
                        "libres: ${_viaje.cantAsientos - _datosTotales[3]}",
                        style: TextStyle(
                          color: AppColors.amberColor,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  List<int> _calcularDatosTotales(Viaje _viaje) {
    int totalPasajeros = 0;
    int totalEmbarcados = 0;
    int totalOcupados = 0;
    int totalNoEmbarcados = 0;

    if (_opcionSeleccionadaEmbarqueViaje == '-1') {
      totalPasajeros = _viaje.pasajeros.length;
      for (int i = 0; i < _viaje.pasajeros.length; i++) {
        if (_viaje.pasajeros[i].embarcado == 1) {
          totalEmbarcados++;
        } else {
          totalNoEmbarcados++;
        }
      }
    } else {
      for (int i = 0; i < _viaje.pasajeros.length; i++) {
        if (_viaje.pasajeros[i].idEmbarqueReal == _opcionSeleccionadaEmbarqueViaje) {
          totalPasajeros++;
          if (_viaje.pasajeros[i].embarcado == 1) {
            totalEmbarcados++;
          } else {
            totalNoEmbarcados++;
          }
        }
      }

      for (var i = 0; i < _viaje.pasajeros.length; i++) {
        if (_viaje.pasajeros[i].embarcado == 1) {
          totalOcupados++;
        }
      }
    }

    List<int> _datosTotales = [totalPasajeros, totalEmbarcados, totalNoEmbarcados, totalOcupados];
    return _datosTotales;
  }

  Widget _manifiestoDePasajerosLista(Viaje _v, double width) {
    Provider.of<PasajeroProvider>(context, listen: false).agregarPasajeros(_v.pasajeros);
    List<Pasajero> pasajeros = Provider.of<PasajeroProvider>(context, listen: false).pasajeros;
    pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));

    setState(() {
      _opcionSeleccionadaEmbarqueViaje = Provider.of<ViajeProvider>(context, listen: false).puntoDeEmbarque;
    });

    return Container(
        width: width,
        padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (int i = 0; i < pasajeros.length; i++)
              // if (_opcionSeleccionadaEmbarqueViaje == '-1')
              //   _cardPasajero(pasajeros[i])
              // else
              if (pasajeros[i].idEmbarqueReal == _opcionSeleccionadaEmbarqueViaje && pasajeros[i].embarcado == 1) _cardPasajero(pasajeros[i])
          ],
        ));
  }

  _cardPasajero(Pasajero pasajero) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Container(
              alignment: Alignment.centerLeft,
              height: 20,
              child: FittedBox(
                child: Text(pasajero.nombres),
              ),
            ),
            subtitle: Column(
              children: [
                Row(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      height: 18,
                      child: FittedBox(
                        child: Text("${pasajero.tipoDoc} ${pasajero.numDoc}"),
                      ),
                    ),
                    Spacer(),
                    Container(
                      alignment: Alignment.centerLeft,
                      height: 18,
                      child: FittedBox(
                        child: Text(
                          "Dsb : " + pasajero.lugarDesembarque,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      height: 18,
                      child: FittedBox(
                        child: Text(
                          pasajero.embarcado == 1 ? "Embarcado: Sí" : "Embarcado: No",
                          style: TextStyle(color: pasajero.embarcado == 1 ? AppColors.greenColor : AppColors.redColor),
                        ),
                      ),
                    ),
                    Spacer(),
                    if (pasajero.asiento > 0)
                      Container(
                        alignment: Alignment.centerLeft,
                        height: 18,
                        child: FittedBox(
                          child: Text(
                            "Asiento : " + pasajero.asiento.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _filtrosManifiesto(double width) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: width * 0.3,
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: FittedBox(
                child: Text("EMBARQUE:"),
              ),
            ),
            Container(
              width: width * 0.7,
              padding: const EdgeInsets.only(left: 10, right: 25),
              child: _puntosEmbarqueViaje(),
            ),
          ],
        ),
        SizedBox(
          height: 15,
        ),
      ],
    );
  }

  Widget _puntosEmbarqueViaje() {
    List<DropdownMenuItem<String>> items = [];
    items = getOpcionesDropdownPuntosEmbViaje();

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
          value: _opcionSeleccionadaEmbarqueViaje,
          items: items,
          hint: const Text('---'),
          iconSize: 30,
          isDense: true, //PARA QUE OCUPE LO QUE EL TAMAÑO DE LETRA OCUPA
          //isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
          onChanged: (value) {
            setState(() {
              _opcionSeleccionadaEmbarqueViaje = value.toString();
              Provider.of<ViajeProvider>(context, listen: false).actualizarSeleccionadaEmbarqueManifiestor(_opcionSeleccionadaEmbarqueViaje);

              if (_opcionSeleccionadaEmbarqueViaje == "-1") {
                _puedeImprimir = false;
              } else {
                List<PuntoEmbarque> ptsEmbarque = Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque;

                for (int i = 0; i < ptsEmbarque.length; i++) {
                  if (ptsEmbarque[i].id == _opcionSeleccionadaEmbarqueViaje) {
                    if (ptsEmbarque[i].eliminado == 0) {
                      //0 abierto y/o no eliminado
                      _puedeImprimir = false;
                    } else {
                      _puedeImprimir = true;
                    }
                    break;
                  }
                }
              }
            });
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> getOpcionesDropdownPuntosEmbViaje() {
    List<DropdownMenuItem<String>> listaPuntosEmbarqueViaje = [];
    List<PuntoEmbarque> puntosEmbProvider = [];
    puntosEmbProvider = Provider.of<ViajeProvider>(context).puntosEmbarque;

    listaPuntosEmbarqueViaje.add(const DropdownMenuItem<String>(
      value: "-1",
      child: Text(
        "---",
      ),
    ));

    if (puntosEmbProvider.isNotEmpty) {
      for (int i = 0; i < puntosEmbProvider.length; i++) {
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

    return listaPuntosEmbarqueViaje;
  }

  int calcularAsientosDisponibles(Viaje viaje) {
    int cantPasajeros = viaje.pasajeros.length;
    return viaje.cantAsientos - cantPasajeros;
  }

  // _imprimirManifiesto(Viaje _viaje) {
  //   PuntoEmbarqueServicio servicio = new PuntoEmbarqueServicio();
  //   List<PuntoEmbarque> ptsEmbarque = Provider.of<ViajeProvider>(context, listen: false).puntosEmbarque;
  //   PuntoEmbarque _puntoEmbarque = new PuntoEmbarque(id: "0", nombre: "", nroViaje: _viaje.nroViaje, eliminado: 0);
  //   for (int i = 0; i < ptsEmbarque.length; i++) {
  //     if (ptsEmbarque[i].id == _opcionSeleccionadaEmbarqueViaje) {
  //       _puntoEmbarque = new PuntoEmbarque(id: ptsEmbarque[i].id, nombre: ptsEmbarque[i].nombre, nroViaje: _viaje.nroViaje, eliminado: ptsEmbarque[i].eliminado, fechaAccion: DateFormat.yMd().add_Hms().format(new DateTime.now()));

  //       break;
  //     }
  //   }
  //   servicio.cambiarEstadoImpresoPuntoEmbarque(_puntoEmbarque, _usuario, _viaje);
  //   _impresion(_viaje, _puntoEmbarque);
  // }

  // _impresion(Viaje _viaje, PuntoEmbarque _puntoEmbarque) async {
  //   String estadoEmbarque = _puntoEmbarque.eliminado == 0 ? "Abierto" : "Cerrado";
  //   String fechaHoraActual = DateFormat.yMd().add_Hms().format(new DateTime.now());

  //   /// DATOS DE LINEA ///
  //   bluetooth.printCustom(removeDiacritics("MANIFIESTO DE PASAJEROS"), 2, 1);
  //   bluetooth.printCustom(" ", 0, 0); //bluetooth.printNewLine();
  //   bluetooth.printCustom("RUC: " + removeDiacritics((_viaje.ruc ?? "")), 0, 0);
  //   bluetooth.printCustom("Razon Social: " + removeDiacritics((_viaje.razonSocial ?? "")), 0, 0);
  //   bluetooth.printCustom(
  //     "Direccion: " + removeDiacritics((_viaje.direccion?.toUpperCase() ?? "")),
  //     0,
  //     0,
  //   );
  //   bluetooth.printCustom("Telefono: " + (_viaje.telefono ?? ""), 0, 0);
  //   //bluetooth.printNewLine();

  //   /// INFORMACION DEL VIAJE ///

  //   bluetooth.printCustom("Ruta: " + removeDiacritics(_viaje.origen) + " - " + removeDiacritics(_viaje.destino), 1, 0);
  //   bluetooth.printCustom("Embarque en: " + removeDiacritics(_puntoEmbarque.nombre), 1, 0);
  //   bluetooth.printCustom("Estado : " + removeDiacritics(estadoEmbarque), 1, 0);

  //   bluetooth.printCustom(
  //       "Fecha: " +
  //           _viaje.fechaSalida +
  //           " "
  //               "Hora: " +
  //           _viaje.horaSalida,
  //       1,
  //       0);
  //   bluetooth.printCustom("Servicio: " + removeDiacritics(_viaje.servicio), 1, 0);
  //   /*bluetooth.printLeftRight("Fecha: " + _viaje.fechaSalida,
  //                     "Hora: " + _viaje.horaSalida, 0);*/

  //   bluetooth.printCustom("Unidad/Placa: " + _viaje.unidad, 1, 0);

  //   for (int i = 0; i < _viaje.tripulantes.length; i++) {
  //     bluetooth.printCustom(_viaje.tripulantes[i].tipo + " " + _viaje.tripulantes[i].orden + ": " + removeDiacritics(_viaje.tripulantes[i].tipoDoc + " " + _viaje.tripulantes[i].numDoc + " " + _viaje.tripulantes[i].nombres), 1, 0);
  //   }

  //   /// PASAJEROS ///
  //   bluetooth.printCustom("--------------------------------------------------------------------", 0, 0);
  //   bluetooth.printCustom("PASAJEROS", 2, 1);
  //   bluetooth.printCustom(" ", 0, 0); //bluetooth.printNewLine();
  //   bluetooth.printCustom("Pasajero" + "  /  " + "Desembarque", 1, 0);
  //   bluetooth.printCustom(" ", 0, 0); //bluetooth.printNewLine();
  //   for (int i = 0; i < _viaje.pasajeros.length; i++) {
  //     if (_viaje.pasajeros[i].idEmbarqueReal == _puntoEmbarque.id && _viaje.pasajeros[i].embarcado == 1) {
  //       bluetooth.printCustom((i + 1).toString() + ". " + (_viaje.pasajeros[i].asiento > 0 ? "${_viaje.pasajeros[i].asiento} " : "") + _viaje.pasajeros[i].tipoDoc + " " + _viaje.pasajeros[i].numDoc + " " + removeDiacritics(_viaje.pasajeros[i].nombres) + "  /  " + removeDiacritics(_viaje.pasajeros[i].lugarDesembarque) + (_viaje.pasajeros[i].asiento > 0 ? "  /  " + removeDiacritics(_viaje.pasajeros[i].asiento.toString()) : ''), 1, 0);

  //       bluetooth.printNewLine();
  //     }
  //   }

  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom("-------------------------        --------------------------", 1, 1);
  //   bluetooth.printCustom("Firma Conductor                   Firma Supervisor", 1, 1);

  //   bluetooth.printCustom(" ", 0, 0);

  //   bluetooth.printCustom("Fecha de impresion: " + fechaHoraActual, 1, 1);
  //   bluetooth.paperCut();
  // }

}
