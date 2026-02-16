import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../models/usuario.dart';
import '../../models/viaje_domicilio/viaje_domicilio.dart';
import '../../services/pasajero_servicio.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_database.dart';
import '../../utils/app_varios.dart';

class ViajeDomicilioRepartoPage extends StatefulWidget {
  const ViajeDomicilioRepartoPage({Key? key}) : super(key: key);
  @override
  State<ViajeDomicilioRepartoPage> createState() => _ViajeDomicilioRepartoPageState();
}

class _ViajeDomicilioRepartoPageState extends State<ViajeDomicilioRepartoPage> {
  bool _mostrarCarga = false;
  late Usuario _usuario;
  final player = AudioPlayer();
  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    //Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Parada _paradaActual = Provider.of<DomicilioProvider>(context, listen: false).paradaActual;
    ViajeDomicilio _viaje = Provider.of<DomicilioProvider>(context).viaje;

    return Scaffold(
      /*appBar: AppBar(
        title: const Text('Recojo'),
        backgroundColor: AppColors.mainBlueColor,
      ),*/
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
                /*physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),*/
                child: Column(
                  children: [
                    SizedBox(
                      height: 50,
                    ),
                    Padding(
                        padding: EdgeInsets.only(left: 15, right: 15),
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                _paradaActual.direccion.trim() != "" ? _paradaActual.direccion : "Dirección no registrada",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 25, color: AppColors.mainBlueColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Center(
                              child: Text(
                                _paradaActual.distrito.trim() != "" ? _paradaActual.distrito : "Distrito no registrado",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20, color: AppColors.greyColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )),
                    SizedBox(
                      height: 15,
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 25, right: 25),

                      //color: AppColors.lightGreenColor,
                      child: Column(children: _listaWidgetPasajeros(_viaje, _paradaActual)),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Center(
                      child: ElevatedButton(
                        child: Text(
                          "Desembarcar", // this is mi
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: _contarPasajerosMarcados(_viaje, _paradaActual) > 0
                            ? () {
                                if (_contarPasajerosMarcados(_viaje, _paradaActual) > 0) {
                                  Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal de desembarcar a los pasajaro", rpta: "OK");
                                  _modalDesembarcar(_viaje, _paradaActual).show();
                                } else {
                                  Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal No se ha marcado ningún pasajero para registrar", rpta: "OK");

                                  _modalMensaje("Error", "No se ha marcado ningún pasajero para registrar").show();
                                }
                              }
                            : null,
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
          ],
        ),
      ),
    );
  }

  int _contarPasajerosMarcados(ViajeDomicilio viaje, Parada parada) {
    int total = 0;

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].desEmb == true && viaje.pasajeros[i].embarcado == 1 && viaje.pasajeros[i].direccion == parada.direccion && viaje.pasajeros[i].distrito == parada.distrito && viaje.pasajeros[i].coordenadas == parada.coordenadas && viaje.pasajeros[i].horaRecojo == parada.horaRecojo) {
        //&& viaje.pasajeros[i].fechaDesembarque == ""
        total++;
      }
    }
    return total;
  }

  AwesomeDialog _modalDesembarcar(ViajeDomicilio viaje, Parada parada) {
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
        Log.insertarLogDomicilio(context: context, mensaje: "Presiona SI", rpta: "OK");
        await registrarDesembarque(viaje, parada);
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }
  //registradesembarque-gps
  Future<void> registrarDesembarque(ViajeDomicilio viaje, Parada parada) async {
    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    //String fechaHoraDesemb = DateFormat.yMd().add_Hms().format(new DateTime.now());
    if (viaje.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < viaje.pasajeros.length; i++) {
        if (viaje.pasajeros[i].embarcado == 1 && viaje.pasajeros[i].desEmb == true && viaje.pasajeros[i].direccion == parada.direccion && viaje.pasajeros[i].coordenadas == parada.coordenadas && viaje.pasajeros[i].distrito == parada.distrito && viaje.pasajeros[i].horaRecojo == parada.horaRecojo) {
          //&& viaje.pasajeros[i].fechaDesembarque == ""
          viaje.pasajeros[i].coordenadasParadero = posicionActual;
          // viaje.pasajeros[i].fechaDesembarque = fechaHoraDesemb;
          viaje.pasajeros[i].idDesembarqueReal = "0";
          viaje.pasajeros[i].modificadoAccion = 0; //0 <-- desembarque

          switch (viaje.pasajeros[i].nuevo) {
            case "0":
              setState(() {
                _mostrarCarga = true;
              });

              Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Registra desembarque pasajaro en la parada #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "OK");

              String rpta = await servicio.registrarDesembarquePasajeroDomicilio(viaje.pasajeros[i], viaje.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

              Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Registra desembarque pasajaro en la parada #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

              setState(() {
                _mostrarCarga = false;
              });

              viaje.pasajeros[i].desEmb = false;

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
                  viaje.pasajeros[i].pasjPorSinc = 1;
                  break;
                default:
              }
              break;
          }

          //Actualizamos la variable provider de viaje
          //await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(viaje.pasajeros[i]);
          //UPDATE PASAJERO BD LOCAL
          int status = await AppDatabase.instance.Update(
            table: "pasajero_domicilio",
            value: viaje.pasajeros[i].toJsonBDLocal(),
            where: "numDoc = '${viaje.pasajeros[i].numDoc}'  AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero desembarcado en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

          await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();
          setState(() {});
        }
      }
      await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasReparto(context);
      //_mostrarModalRespuesta("HECHO", "Pasajeros desembarcados", true).show();
      //if (_verificarSalir(viaje, parada)) {
      Log.insertarLogDomicilio(context: context, mensaje: "Regreso de la pantalla de reparto.", rpta: "OK");
      Navigator.pop(context);
      //}

      setState(() {});
    } else {
      Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal de no existen pasajeros", rpta: "OK");
      _mostrarModalRespuesta('ERROR', 'No existen pasajeros', false);
    }
  }

  AwesomeDialog _modalMensaje(String titulo, String mensaje) {
    return AwesomeDialog(
        context: context,
        dialogType: DialogType.noHeader,
        //customHeader: null,
        animType: AnimType.topSlide,
        //showCloseIcon: true,
        title: titulo,
        desc: mensaje,
        autoHide: Duration(seconds: 3));
  }

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(
        context: context,
        dialogType: success ? DialogType.success : DialogType.error,
        animType: AnimType.topSlide,
        //showCloseIcon: true,
        dismissOnBackKeyPress: false,
        dismissOnTouchOutside: false,
        title: titulo,
        desc: cuerpo,
        autoHide: Duration(seconds: 2));
  }

  List<Widget> _listaWidgetPasajeros(ViajeDomicilio viaje, Parada parada) {
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
        if (_pasajeros[i].direccion == parada.direccion && _pasajeros[i].coordenadas == parada.coordenadas && _pasajeros[i].distrito == parada.distrito && _pasajeros[i].horaRecojo == parada.horaRecojo && _pasajeros[i].embarcado == 1 && _pasajeros[i].estadoDesem == "" && _pasajeros[i].pasjPorSinc == 0) lista.add(_cardWidget(_pasajeros[i])); //&& _pasajeros[i].fechaDesembarque == ""
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
                if (pasajero.desEmb) {
                  pasajero.fechaDesembarque = DateFormat.yMd().add_Hms().format(DateTime.now());
                } else {
                  // Si no está seleccionado, vacía la fecha
                  pasajero.fechaDesembarque = "";
                }
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

  bool _verificarSalir(ViajeDomicilio viaje, Parada parada) {
    int porDesembarcar = 0;
    List<PasajeroDomicilio> _pasajeros = viaje.pasajeros;
    for (int i = 0; i < _pasajeros.length; i++) {
      if (_pasajeros[i].direccion == parada.direccion && _pasajeros[i].coordenadas == parada.coordenadas && _pasajeros[i].distrito == parada.distrito && _pasajeros[i].horaRecojo == parada.horaRecojo && _pasajeros[i].embarcado == 1 && _pasajeros[i].fechaDesembarque == "") {
        porDesembarcar++;
      }
    }

    return porDesembarcar == 0 ? true : true;
  }
}
