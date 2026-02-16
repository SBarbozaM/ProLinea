import 'dart:async';

import 'package:embarques_tdp/src/providers/path_provider.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import 'package:awesome_dialog/awesome_dialog.dart';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:diacritic/diacritic.dart';
// import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:embarques_tdp/src/pages/manifiesto/generar_pdf.dart';
import 'package:embarques_tdp/src/providers/impresoraProvider.dart';
import 'package:embarques_tdp/src/services/pto_embarque_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../models/pasajero.dart';
import '../../models/punto_embarque.dart';
import '../../models/usuario.dart';
import '../../models/viaje.dart';
import '../../providers/providers.dart';
import '../../utils/app_colors.dart';

import 'package:flutter_switch/flutter_switch.dart';

import 'package:permission_handler/permission_handler.dart';

class ManifiestoViajePage extends StatefulWidget {
  const ManifiestoViajePage({Key? key}) : super(key: key);

  @override
  State<ManifiestoViajePage> createState() => _ManifiestoViajePageState();
}

class _ManifiestoViajePageState extends State<ManifiestoViajePage> {
  late Usuario _usuario;
  late Viaje _viaje;
  // late BluetoothDevice? _impresoraActual;
  // BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<PuntoEmbarque> pe = [];

  bool _lock = false;
  bool _mostrarLoadiig = false;
  bool loading_pdf = false;

  @override
  void initState() {
    // _impresoraActual = Provider.of<ImpresoraProvider>(context, listen: false).impresoraVinculada;
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    _viaje = Provider.of<ViajeProvider>(context, listen: false).viajeManifiesto;
    _lock = _viaje.estadoEmbarque == 0 ? true : false;
    //_init();
    super.initState();

    ingreso("INGRESO A MANIFIESTO VIAJE");
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
      "${usuarioLogin.codOperacion}",
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "Embarque ${usuarioLogin.perfil}: ${Mensaje}",
      "Exitoso",
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return RefreshIndicator(
      displacement: 75,
      onRefresh: () {
        return Future.delayed(Duration(seconds: 0), () async {});
      },
      child: Scaffold(
        // appBar: AppBar(
        //   leading: IconButton(
        //       onPressed: () {
        //         Navigator.pop(context);
        //       },
        //       icon: Icon(
        //         Icons.arrow_back_ios,
        //         color: AppColors.blackColor,
        //       )),
        //   elevation: 0,
        //   backgroundColor: AppColors.whiteColor,
        //   title: Text(
        //     'MANIFIESTO DE PASAJEROS',
        //     style: TextStyle(
        //       fontSize: 18,
        //       fontWeight: FontWeight.bold,
        //       color: AppColors.blackColor,
        //     ),
        //   ),
        // ),
        body: ModalProgressHUD(
          opacity: 0.0,
          color: AppColors.whiteColor,
          progressIndicator: const CircularProgressIndicator(
            color: AppColors.mainBlueColor,
          ),
          inAsyncCall: _mostrarLoadiig,
          child: SafeArea(
            child: CustomScrollView(
                scrollDirection: Axis.vertical,
                /*physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),*/
                slivers: [
                  SliverAppBar(
                    leading: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.blackColor,
                        )),
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                    title: Text('MANIFIESTO DE PASAJEROS'),
                    floating: true,
                    elevation: 0,
                    pinned: true,
                    backgroundColor: AppColors.whiteColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Column(children: [
                        SizedBox(
                          height: 50,
                        ),
                        _filtrosManifiesto(width),
                        _datosViaje(width, 15),
                        SizedBox(
                          height: 10,
                        ),
                        _informacionManifiesto(_viaje, width),
                      ]),
                    ),
                    // Make the initial height of the SliverAppBar larger than normal.
                    expandedHeight: 235,
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      width: width,
                      child: SingleChildScrollView(
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
                  )
                ]),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FloatingActionButton(
                heroTag: "btn1",
                mini: true,
                onPressed: loading_pdf
                    ? () {}
                    : () async {
                        setState(() {
                          loading_pdf = true;
                        });

                        final uint8List = await generateDocument(_viaje, _usuario);

                        // Sacamos el version del android
                        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

                        if (androidInfo.version.sdkInt >= 33) {
                          if (await Permission.videos.request().isGranted && await Permission.photos.request().isGranted) {
                            //migrado 29/08/2025 a :
                            // await FileSaver.instance.saveFile(
                            //   name: "${DateTime.now().microsecond}_${_viaje.origen}-${_viaje.destino}_${_viaje.unidad}",
                            //   bytes: uint8List,
                            //   fileExtension: "pdf",
                            //   mimeType: MimeType.pdf,
                            // );
                            await savePdfToDownloads(context, uint8List, "${DateTime.now().microsecond}_${_viaje.origen}-${_viaje.destino}_${_viaje.unidad}");

                            await Future.delayed(Duration(milliseconds: 50));
                            setState(() {
                              loading_pdf = false;
                            });

                            ingreso("DESCARGAR MANIFIESTO EN SDK ${androidInfo.version.sdkInt}");
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "❌ Permiso de almacenamiento denegado",
                                  style: TextStyle(color: AppColors.whiteColor),
                                ),
                                backgroundColor: AppColors.redColor,
                                duration: Duration(seconds: 1),
                              ),
                            );
                            setState(() {
                              loading_pdf = false;
                            });
                          }
                        } else {
                          if (await Permission.storage.request().isGranted) {
                            // DocumentFileSavePlus().saveFile(uint8List, "${DateTime.now().microsecond} _ ${_viaje.origen}-${_viaje.destino} ${_viaje.unidad}.pdf", "appliation/pdf");
                            //migrado 29/08/2025 a :
                            try {
                              // final result = await FileSaver.instance.saveFile(
                              //   name: "${DateTime.now().microsecond}_${_viaje.origen}-${_viaje.destino}_${_viaje.unidad}",
                              //   bytes: uint8List,
                              //   fileExtension: "pdf",
                              //   mimeType: MimeType.pdf,
                              // );
                              // print("Archivo guardado efn: $result");
                              await savePdfToDownloads(
                                context,
                                uint8List,
                                "${DateTime.now().microsecond}_${_viaje.origen}-${_viaje.destino}_${_viaje.unidad}",
                              );

                              await Future.delayed(Duration(milliseconds: 50));
                              setState(() {
                                loading_pdf = false;
                              });
                              ingreso("DESCARGAR MANIFIESTO EN SDK < 13");
                            } catch (e, stacktrace) {
                              print("Error al guardar PDF: $e");
                              print(stacktrace);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al guardar PDF: $e',
                                    style: TextStyle(color: AppColors.whiteColor),
                                  ),
                                  backgroundColor: AppColors.redColor,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "❌ Permiso de almacenamiento denegado",
                                  style: TextStyle(color: AppColors.whiteColor),
                                ),
                                backgroundColor: AppColors.redColor,
                                duration: Duration(seconds: 1),
                              ),
                            );
                            setState(() {
                              loading_pdf = false;
                            });
                          }
                        }

                        // if (await Permission.storage.request().isDenied) {
                        //   print("object");
                        // }
                      },
                backgroundColor: AppColors.redColor,
                child: loading_pdf
                    ? Container(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.file_download),
              ),
              // FloatingActionButton(
              //   heroTag: "btn2",
              //   mini: true,
              //   tooltip: 
              //   _impresoraActual == null
              //       ? "No vinculada"
              //       : _impresoraActual?.name == ""
              //           ? "Sin nombre"
              //           : _impresoraActual?.name,
              //   onPressed: _impresoraActual == null
              //       ? null
              //       : 
              //       () async {
              //           if (_viaje.estadoEmbarque == 0) {
              //             ingreso("MODAL IMPRIMIR MANIFIESTO SIN CERRAR EL PUNTO DE EMBARQUE");
              //             _modalDeseaCerrarPtoEmbarque().show();
              //           } else {
              //             ingreso("IMPRIMIR MANIFIESTO CERRADO PUNTO DE EMBARQUE");
              //             // _imprimirManifiesto();
              //           }
              //         },
              //   // backgroundColor: _impresoraActual == null ? AppColors.greyColor : AppColors.redColor,

              //   //foregroundColor: AppColors.lightGreenColor,
              //   // child: _impresoraActual == null ? Icon(Icons.print_disabled) : Icon(Icons.print),
              // ),
            
            ],
          ),
        ),
      ),
    );
  }

  _informacionViaje(Viaje _viaje, double width, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _manifiestoDePasajerosLista(_viaje, width),
        //_manifiestoDePasajerosTabla(_viaje, width),
      ],
    );
  }

  Widget _datosViaje(double width, double tLetra) {
    return Container(
      width: width * 0.9,
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.start,
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ruta: " + _viaje.origen + " - " + _viaje.destino,
            style: TextStyle(fontSize: tLetra),
          ),
          Text(
            "Unidad: " + _viaje.unidad,
            style: TextStyle(fontSize: tLetra),
          ),
          FittedBox(
            child: Text(
              "Salida - Servicio: ${_viaje.fechaSalida} ${_viaje.horaSalida} - ${_viaje.servicio}",
              style: TextStyle(fontSize: tLetra),
            ),
          ),
          FittedBox(
            child: Text(
              "Empresa: ${_viaje.subOperacionNombre}",
              style: TextStyle(fontSize: tLetra),
            ),
          )
        ],
      ),
    );
  }

  Widget _informacionManifiesto(Viaje _viaje, double width) {
    List<int> _datosTotales = _calcularDatosTotales(_viaje);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
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
                "Embarcados: ${_viaje.cantEmbarcados}",
                style: TextStyle(
                  color: AppColors.greenColor,
                ),
              ),
            ),
          ),
          Container(
            height: 20,
            child: FittedBox(
              child: Text(
                "Libres: ${_viaje.cantAsientos - int.parse(_viaje.totalEmbarcados)}",
                style: TextStyle(
                  color: AppColors.amberColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _calcularDatosTotales(Viaje _viaje) {
    int totalPasajeros = 0;
    int totalEmbarcados = 0;
    int totalNoEmbarcados = 0;

    totalPasajeros = _viaje.pasajeros.length;
    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].embarcado == 1) {
        totalEmbarcados++;
      } else {
        totalNoEmbarcados++;
      }
    }

    List<int> _datosTotales = [totalPasajeros, totalEmbarcados, totalNoEmbarcados];
    return _datosTotales;
  }

  Widget _manifiestoDePasajerosLista(Viaje _v, double width) {
    Provider.of<PasajeroProvider>(context, listen: false).agregarPasajeros(_v.pasajeros);
    List<Pasajero> pasajeros = Provider.of<PasajeroProvider>(context, listen: false).pasajeros;
    pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));

    return Container(
        width: width,
        padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [for (int i = 0; i < pasajeros.length; i++) _cardPasajero(pasajeros[i])],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: width * 0.7,
              padding: const EdgeInsets.only(left: 25, right: 10),
              child: FittedBox(
                child: Text("Embarque en " + _viaje.nombrePuntoEmbarqueActual),
              ),
            ),
            FlutterSwitch(
              height: 25,
              width: 60,
              padding: 1,
              toggleSize: 25,
              value: _lock,
              valueFontSize: 25.0,
              activeColor: AppColors.greenColor,
              activeIcon: Icon(
                Icons.lock_open,
                color: AppColors.greenColor,
              ),
              inactiveColor: AppColors.redColor,
              inactiveIcon: Icon(
                Icons.lock,
                color: AppColors.redColor,
              ),
              onToggle: (val) async {
                ViajeProvider viajeProvider = Provider.of<ViajeProvider>(context, listen: false);
                viajeProvider.cambiarEstado(_viaje.nroViaje, val == true ? 0 : 1);

                ingreso("${val == true ? "ABIERTO" : "CERRADO "} DE EMBARQUE");

                setState(() {
                  _lock = val;
                  _viaje.estadoEmbarque = val == true ? 0 : 1;
                  _mostrarLoadiig = true;
                });

                await Future.delayed(Duration(seconds: 1));

                ViajeServicio servicio = new ViajeServicio();

                PuntoEmbarque _puntoEmbarque = new PuntoEmbarque(id: "0", nombre: _viaje.nombrePuntoEmbarqueActual, nroViaje: _viaje.nroViaje, eliminado: _viaje.estadoEmbarque, fechaAccion: DateFormat.yMd().add_Hms().format(new DateTime.now()));

                await servicio.cambiarEstadoPuntoEmbarque(_puntoEmbarque, _usuario, _viaje);

                setState(() {
                  _mostrarLoadiig = false;
                });
              },
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }

  int calcularAsientosDisponibles(Viaje viaje) {
    int cantPasajeros = viaje.pasajeros.length;
    return viaje.cantAsientos - cantPasajeros;
  }

  AwesomeDialog _modalDeseaCerrarPtoEmbarque() {
    String titulo = "Antes de imprimir";
    String cuerpo = " ¿Desea cerrar el punto de embarque " + _viaje.nombrePuntoEmbarqueActual + "?";

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
        setState(() {
          _lock = !_lock;
          _viaje.estadoEmbarque = _lock == true ? 0 : 1;
          _mostrarLoadiig = true;
        });

        ViajeServicio servicio = new ViajeServicio();

        PuntoEmbarque _puntoEmbarque = new PuntoEmbarque(id: "0", nombre: _viaje.nombrePuntoEmbarqueActual, nroViaje: _viaje.nroViaje, eliminado: _viaje.estadoEmbarque, fechaAccion: DateFormat.yMd().add_Hms().format(new DateTime.now()));

        await servicio.cambiarEstadoPuntoEmbarque(_puntoEmbarque, _usuario, _viaje);

        setState(() {
          _mostrarLoadiig = false;
        });
        ingreso("IMPRIMIR MANIFIESTO CERRANDO PUNTO DE EMBARQUE");
        // _imprimirManifiesto();
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {
        ingreso("IMPRIMIR MANIFIESTO SIN CERRAR PUNTO DE EMBARQUE");
        // _imprimirManifiesto();
      },
    );
  }

  // _imprimirManifiesto() {
  //   PuntoEmbarqueServicio servicio = new PuntoEmbarqueServicio();
  //   PuntoEmbarque _puntoEmbarque = new PuntoEmbarque(id: "0", nombre: _viaje.nombrePuntoEmbarqueActual, nroViaje: _viaje.nroViaje, eliminado: _viaje.estadoEmbarque, impreso: '1', fechaAccion: DateFormat.yMd().add_Hms().format(new DateTime.now()));

  //   servicio.cambiarEstadoImpresoPuntoEmbarque(_puntoEmbarque, _usuario, _viaje);

  //   _impresion();
  //   // Provider.of<ViajeProvider>(context, listen: false)
  //   //     .cambiarEstadoImpreso(_viaje.nroViaje);
  // }

  // _impresion() async {
  //   ingreso("MANIFIESTO IMPRESO");

  //   String estadoEmbarque = _viaje.estadoEmbarque == 0 ? "Abierto" : "Cerrado";
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
  //   bluetooth.printCustom("Embarque en: " + removeDiacritics(_viaje.nombrePuntoEmbarqueActual), 1, 0);
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
  //   bluetooth.printCustom("Empresa: " + removeDiacritics(_viaje.subOperacionNombre), 1, 0);
  //   /*bluetooth.printLeftRight("Fecha: " + _viaje.fechaSalida,
  //                     "Hora: " + _viaje.horaSalida, 0);*/

  //   bluetooth.printCustom("Unidad/Placa: " + _viaje.unidad, 1, 0);
  //   if (_viaje.tripulantes[0].numDoc != "") bluetooth.printCustom("Conductor 1: DNI ${_viaje.tripulantes[0].numDoc} ${_viaje.tripulantes[0].nombres}", 1, 0);
  //   if (_viaje.tripulantes[1].numDoc != "") bluetooth.printCustom("Conductor 2: DNI ${_viaje.tripulantes[1].numDoc} ${_viaje.tripulantes[1].nombres}", 1, 0);
  //   if (_viaje.tripulantes[2].numDoc != "") bluetooth.printCustom("Conductor 3: DNI ${_viaje.tripulantes[2].numDoc} ${_viaje.tripulantes[2].nombres}", 1, 0);
  //   if (_viaje.tripulantes[3].numDoc != "") bluetooth.printCustom("Asistente 1: DNI ${_viaje.tripulantes[3].numDoc} ${_viaje.tripulantes[3].nombres}", 1, 0);
  //   if (_viaje.tripulantes[4].numDoc != "") bluetooth.printCustom("Asistente 2: DNI ${_viaje.tripulantes[4].numDoc} ${_viaje.tripulantes[4].nombres}", 1, 0);
  //   bluetooth.printCustom("Responsable: ${_usuario.apellidoPat} ${_usuario.apellidoMat} ${_usuario.nombres}", 1, 0);

  //   // for (int i = 0; i < _viaje.tripulantes.length; i++) {
  //   //   bluetooth.printCustom(
  //   //       _viaje.tripulantes[i].tipo +
  //   //           " " +
  //   //           _viaje.tripulantes[i].orden +
  //   //           ": " +
  //   //           removeDiacritics(_viaje.tripulantes[i].tipoDoc +
  //   //               " " +
  //   //               _viaje.tripulantes[i].numDoc +
  //   //               " " +
  //   //               _viaje.tripulantes[i].nombres),
  //   //       1,
  //   //       0);
  //   // }

  //   /// PASAJEROS ///
  //   bluetooth.printCustom("--------------------------------------------------------------------", 0, 0);
  //   bluetooth.printCustom("PASAJEROS", 2, 1);
  //   bluetooth.printCustom(" ", 0, 0); //bluetooth.printNewLine();
  //   bluetooth.printCustom("Pasajero" + "  /  " + "Desembarque", 1, 0);
  //   bluetooth.printCustom(" ", 0, 0); //bluetooth.printNewLine();
  //   for (int i = 0; i < _viaje.pasajeros.length; i++) {
  //     bluetooth.printCustom((i + 1).toString() + ". " + (_viaje.pasajeros[i].asiento > 0 ? "${_viaje.pasajeros[i].asiento} " : "") + _viaje.pasajeros[i].tipoDoc + " " + _viaje.pasajeros[i].numDoc + " " + removeDiacritics(_viaje.pasajeros[i].nombres) + "  /  " + removeDiacritics(_viaje.pasajeros[i].lugarDesembarque), 1, 0);

  //     bluetooth.printNewLine();
  //   }

  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.printCustom("-------------------------        --------------------------", 1, 1);
  //   bluetooth.printCustom("Firma Conductor                   Firma Supervisor", 1, 1);

  //   bluetooth.printCustom(" ", 0, 0);

  //   bluetooth.printCustom("Fecha de impresion: " + fechaHoraActual, 1, 1);
  //   bluetooth.printCustom(" ", 0, 0);
  //   bluetooth.paperCut();
  // }

}
