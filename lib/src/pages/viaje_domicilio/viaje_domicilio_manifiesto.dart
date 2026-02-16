import 'dart:async';

import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/services/usuario_servicio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/warning_widget_internet.dart';
import '../../models/punto_embarque.dart';
import '../../models/usuario.dart';
import '../../providers/providers.dart';
import '../../utils/app_colors.dart';

class ViajeDomicilioManifiestoPage extends StatefulWidget {
  const ViajeDomicilioManifiestoPage({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioManifiestoPage> createState() => _ViajeDomicilioManifiestoPageState();
}

class _ViajeDomicilioManifiestoPageState extends State<ViajeDomicilioManifiestoPage> {
  late Timer _timer;
  List<PuntoEmbarque> pe = [];

  @override
  void initState() {
    _timer = new Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    ViajeDomicilio _viaje = Provider.of<DomicilioProvider>(context, listen: false).viaje;

    String sentidoViaje = _viaje.sentido;
    return WillPopScope(
      onWillPop: () async => false,
      child: RefreshIndicator(
        displacement: 75,
        onRefresh: () {
          return Future.delayed(Duration(seconds: 1), () async {
            /*await Provider.of<ViajeProvider>(context, listen: false)
                .sincronizarViajeNuevosPasajerosBolsa(
                    _usuario.tipoDoc, _usuario.numDoc, context);*/

            setState(() {});
          });
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'MANIFIESTO DE PASAJEROS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blackColor),
            ),
            leading: IconButton(
              onPressed: () async {
                Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.blackColor,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.whiteColor,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    children: [
                      // const SizedBox(
                      //   height: 60,
                      // ),
                      // const Center(
                      //   child: Text(
                      //     'MANIFIESTO DE PASAJEROS',
                      //     style: TextStyle(
                      //         fontSize: 23, fontWeight: FontWeight.bold),
                      //   ),
                      // ),
                      // const SizedBox(
                      //   height: 15,
                      // ),
                      _informacionViaje(_viaje, width, height, sentidoViaje),
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
          /*floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: !_puedeImprimir
                ? null
                : () async {
                    Navigator.pushNamed(context, 'imprimirPage');
                    //Navigator.pushNamed(context, 'imprimirPage2');
                  },
            backgroundColor:
                !_puedeImprimir ? AppColors.greyColor : AppColors.redColor,
            //foregroundColor: AppColors.lightGreenColor,
            child: Icon(Icons.print),
          ),*/
        ),
      ),
    );
  }

  _informacionViaje(ViajeDomicilio _viaje, double width, double height, String sentidoViaje) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //_filtrosManifiesto(width),

        /*_filaDatos("RUC", (_viaje.ruc).toUpperCase(), width),
        const SizedBox(
          height: 10,
        ),
        _filaDatos("Razón Social", (_viaje.razonSocial).toUpperCase(), width),
        const SizedBox(
          height: 10,
        ),
        _filaDatos("Teléfono", (_viaje.telefono).toUpperCase(), width),
        const SizedBox(
          height: 10,
        ),
        _filaDatos("Dirección", (_viaje.direccion).toUpperCase(), width),
        const SizedBox(
          height: 10,
        ),
        _filaDatos("Ruta",
            (_viaje.origen + " - " + _viaje.destino).toUpperCase(), width),
        const SizedBox(
          height: 10,
        ),
        _filaDatos("Fecha y Hora", _viaje.fechaSalida + " " + _viaje.horaSalida,
            width),
        const SizedBox(
          height: 10,
        ),
        _filaDatos("Unidad/Placa", _viaje.unidad, width),
        for (int i = 0; i < _viaje.tripulantes.length; i++)
          /*if (_viaje.tripulantes[i].tipoDoc != "" &&
              _viaje.tripulantes[i].numDoc != "")*/
          _columnaTripulacion(_viaje.tripulantes[i], width),
        const SizedBox(
          height: 20,
        ),*/
        _informacionManifiesto(_viaje, width),
        SizedBox(
          height: 10,
        ),
        _manifiestoDePasajerosLista(_viaje, width, sentidoViaje),
        //_manifiestoDePasajerosTabla(_viaje, width),
      ],
    );
  }

  Widget _informacionManifiesto(ViajeDomicilio _viaje, double width) {
    List<int> _datosTotales = _calcularDatosTotales(_viaje);

    return Container(
      padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
      child: Row(
        children: [
          Container(
            width: width * 0.2,
            height: 20,
            child: FittedBox(
                child: Text(
              "Total: " + _datosTotales[0].toString(),
              style: TextStyle(
                color: AppColors.mainBlueColor,
              ),
            )),
          ),
          SizedBox(
            width: width * 0.05,
          ),
          Container(
            width: width * 0.3,
            height: 20,
            child: FittedBox(
              child: Text(
                "Embarcados: " + _datosTotales[1].toString(),
                style: TextStyle(
                  color: AppColors.greenColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: width * 0.05,
          ),
          Container(
            width: width * 0.3,
            height: 20,
            child: FittedBox(
              child: Text(
                "No Embarcados: " + _datosTotales[2].toString(),
                style: TextStyle(
                  color: AppColors.redColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _calcularDatosTotales(ViajeDomicilio _viaje) {
    int totalPasajeros = 0;
    int totalEmbarcados = 0;
    int totalNoEmbarcados = 0;

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      totalPasajeros++;
      if (_viaje.pasajeros[i].embarcado == 1) {
        totalEmbarcados++;
      } else {
        totalNoEmbarcados++;
      }
    }

    List<int> _datosTotales = [totalPasajeros, totalEmbarcados, totalNoEmbarcados];
    return _datosTotales;
  }

  Widget _manifiestoDePasajerosLista(ViajeDomicilio _v, double width, String sentidoViaje) {
    /*Provider.of<PasajeroProvider>(context, listen: false)
        .agregarPasajeros(_v.pasajeros);*/
    List<PasajeroDomicilio> pasajeros = _v.pasajeros;
    //Provider.of<PasajeroProvider>(context, listen: false).pasajeros;
    //pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));

    return Container(
        width: width,
        padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [for (int i = 0; i < pasajeros.length; i++) _cardPasajero(pasajeros[i], sentidoViaje)],
        ));
  }

  _cardPasajero(PasajeroDomicilio pasajero, String sentidoViaje) {
    String horaProgramada = "Hora programada";
    String embarqueRecojo = "Embarcado a las";
    String desembarqueReparto = "Desembarcado a las";

    if (sentidoViaje == "I") {
      horaProgramada = "Recojo programado a las";
      embarqueRecojo = "Recogido a las";
    }
    if (sentidoViaje == "R") {
      horaProgramada = "Reparto programado a las";
      desembarqueReparto = "Repartido a las";
    }

    String nuevo = pasajero.asiento == "0" ? "" : " (Nuevo)";

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Container(
              alignment: Alignment.centerLeft,
              height: 30,
              child: FittedBox(
                child: Text(
                  pasajero.nombres + nuevo,
                ),
              ),
            ),
            subtitle: Column(
              children: [
                Row(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      height: 25,
                      child: FittedBox(
                        child: Text(
                          horaProgramada + " " + pasajero.horaRecojo,
                          style: TextStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      height: 25,
                      child: FittedBox(
                        child: Text(
                          pasajero.embarcado == 1
                              ? embarqueRecojo + " " + _obtenerHoraEmbarque(pasajero.fechaEmbarque)
                              : pasajero.embarcado == 0
                                  ? "No Embarcado"
                                  : "En Espera",
                          style: TextStyle(
                              color: pasajero.embarcado == 1
                                  ? AppColors.greenColor
                                  : pasajero.embarcado == 2
                                      ? AppColors.amberColor
                                      : AppColors.redColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (pasajero.embarcado == 1)
                      pasajero.fechaDesembarque == ""
                          ? Container(
                              alignment: Alignment.centerLeft,
                              height: 25,
                              child: FittedBox(
                                child: Text("Por Desembarcar", style: TextStyle(color: AppColors.amberColor, fontWeight: FontWeight.bold)),
                              ),
                            )
                          : Container(
                              alignment: Alignment.centerLeft,
                              height: 25,
                              child: FittedBox(
                                child: Text(
                                  desembarqueReparto +
                                      " " +
                                      _obtenerHoraEmbarque(
                                        pasajero.fechaDesembarque,
                                      ),
                                  style: TextStyle(color: AppColors.mainBlueColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerHoraEmbarque(String fechaEmbarque) {
    // Divide la fecha y hora usando el espacio como delimitador
    final fechaSplit = fechaEmbarque.split(" ");

    // Asegúrate de que haya una parte de la hora (en la posición 1)
    if (fechaSplit.length < 2) {
      return "Hora inválida";
    }

    // Divide la parte de la hora usando el separador ":"
    final hora = fechaSplit[1].split(":");

    // Asegúrate de que haya horas y minutos
    if (hora.length < 2) {
      return "Hora inválida";
    }

    // Añade ceros a la izquierda si es necesario
    if (hora[0].length == 1) {
      hora[0] = "0" + hora[0];
    }

    if (hora[1].length == 1) {
      hora[1] = "0" + hora[1];
    }

    // Combina la nueva hora
    final nuevaHora = hora[0] + ":" + hora[1];

    return nuevaHora;
  }

  // _obtenerHoraEmbarque(String fechaEmbarque) {
  //   final fechaSplit = fechaEmbarque.split("");

  //   final hora = fechaSplit[1].split(":");

  //   if (hora[0].length == 1) {
  //     hora[0] = "0" + hora[0];
  //   }

  //   if (hora[1].length == 1) {
  //     hora[1] = "0" + hora[1];
  //   }

  //   final nuevaHora = hora[0] + ":" + hora[1];

  //   return nuevaHora;
  // }
}
