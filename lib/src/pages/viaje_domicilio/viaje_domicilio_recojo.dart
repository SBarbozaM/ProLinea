import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
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
import '../../utils/app_varios.dart';

class ViajeDomicilioRecojoPage extends StatefulWidget {
  const ViajeDomicilioRecojoPage({Key? key}) : super(key: key);
  @override
  State<ViajeDomicilioRecojoPage> createState() => _ViajeDomicilioRecojoPageState();
}

class _ViajeDomicilioRecojoPageState extends State<ViajeDomicilioRecojoPage> {
  bool _mostrarCarga = false;
  late Usuario _usuario;
  final player = AudioPlayer();
  static List<Widget> iconos = AppVarios.iconosEstados;
  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
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
                                _paradaActual.direccion,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 25, color: AppColors.mainBlueColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Center(
                              child: Text(
                                _paradaActual.distrito,
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
                          "Guardar",
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: _contarPasajerosMarcados(_viaje, _paradaActual) > 0
                            ? () async {
                                if (_contarPasajerosMarcados(_viaje, _paradaActual) > 0) {
                                  Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal de registrar pasajeros embarque: Seguro que desea registrar a los pasajeros marcados", rpta: "OK");

                                  _modalRegistrar(_viaje, _paradaActual).show();
                                } else {
                                  Log.insertarLogDomicilio(context: context, mensaje: "No se ha marcado ningún pasajero para registrar", rpta: "ERROR");

                                  _modalMensaje("Error", "Muestra modal mensaje de error : No se ha marcado ningún pasajero para registrar").show();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppColors.whiteColor,
                          backgroundColor: AppColors.mainBlueColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: Colors.green[900],
                          ),
                          Text(
                            "Pasajero recogido",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                          Text(
                            "Pasajero no recogido",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.replay,
                            color: AppColors.mainBlueColor,
                          ),
                          Text(
                            "Quitar seleccion",
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
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

  int _contarPasajerosMarcados(ViajeDomicilio _viaje, Parada _paradaActual) {
    int total = 0;
    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].direccion == _paradaActual.direccion && _viaje.pasajeros[i].distrito == _paradaActual.distrito && _viaje.pasajeros[i].horaRecojo == _paradaActual.horaRecojo && _viaje.pasajeros[i].coordenadas == _paradaActual.coordenadas) {
        if (_viaje.pasajeros[i].embarcadoAux != 2) {
          total++;
        }
      }
    }
    return total;
  }

  AwesomeDialog _modalRegistrar(ViajeDomicilio _viaje, Parada parada) {
    String titulo = "REGISTRAR";
    String cuerpo = "¿Seguro que desea registrar a los pasajeros marcados?";

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
        //Log.insertarLogDomicilio(context: context, mensaje: "Presiona SI", rpta: "OK");
        await _registrar(_viaje, parada);

        /// Log.insertarLogDomicilio(context: context, mensaje: "Presiona SI", rpta: "OK");
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
      // onDismissCallback: (type) {
      // if (type == DismissType.btnOk) {
      //  Log.insertarLogDomicilio(context: context, mensaje: "Regresa a la pantalla del listado de paradas de RECOJO", rpta: "OK");

      // new Timer(Duration(seconds: 2), () {
      //   Navigator.pop(context);
      // });
      //}

      // }
      // for (int i = 0; i < _viaje.pasajeros.length; i++) {
      //   if (_viaje.pasajeros[i].embarcado != 2) {
      //     Future.delayed(Duration.zero, () {
      //       Navigator.of(context).pushNamedAndRemoveUntil(
      //           'inicio', (Route<dynamic> route) => false);
      //     });
      //   }
      // }
      //  },
    );
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
  //registraviaje-gps
  _registrar(ViajeDomicilio _viaje, Parada _paradaActual) async {
    String posicionActual;
    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
    } catch (e) {
      posicionActual = "0, 0-Error no controlado";
    }

    PasajeroServicio servicio = new PasajeroServicio();
    String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

    // for (int i = 0; i < _viaje.pasajeros.length; i++) {
    //   if (_viaje.pasajeros[i].direccion == _paradaActual.direccion && _viaje.pasajeros[i].distrito == _paradaActual.distrito && _viaje.pasajeros[i].horaRecojo == _paradaActual.horaRecojo) {
    //     //&& _viaje.pasajeros[i].coordenadas == _paradaActual.coordenadas
    //     if (_viaje.pasajeros[i].embarcadoAux != 2) {
    //       _viaje.pasajeros[i].embarcadoAux = 2;
    //       _viaje.pasajeros[i].modificado = 0;
    //     }
    //   }
    // }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].direccion == _paradaActual.direccion && _viaje.pasajeros[i].distrito == _paradaActual.distrito && _viaje.pasajeros[i].horaRecojo == _paradaActual.horaRecojo) {
        //&& _viaje.pasajeros[i].coordenadas == _paradaActual.coordenadas
        if (_viaje.pasajeros[i].embarcadoAux != 2) {
          _viaje.pasajeros[i].embarcado = _viaje.pasajeros[i].embarcadoAux;
          //_viaje.pasajeros[i].fechaEmbarque = fechaHoraEmb;
          _viaje.pasajeros[i].modificado = 0;

          _viaje.pasajeros[i].embarcadoAux = 2;
          _viaje.pasajeros[i].idEmbarqueReal = "0";
          _viaje.pasajeros[i].coordenadasParadero = posicionActual;

          setState(() {
            _mostrarCarga = true;
          });

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Registrar pasajero embarcados RECOJO #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_v3", rpta: "OK");

          String rpta = await servicio.cambiarEstadoEmbarquePasajeroDomicilio_v2(_viaje.pasajeros[i], _viaje.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());
          try {
            Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Registrar pasajero embarcados RECOJO #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_v3", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");
          } catch (e) {
            print('Error $e');
          }

          switch (rpta) {
            case "0":
              _viaje.pasajeros[i].modificado = 1;
              break;
            case "1":
              /* Eliminamos del provider y de la bd local */
              /*await AppDatabase.instance
                  .eliminarPasajero(_viajeProvider.pasajeros[i]);*/
              _viaje.pasajeros.removeWhere((element) => element.numDoc == _viaje.pasajeros[i].numDoc);

              break;
            case "2":
            // _viaje.pasajeros[i].embarcadoAux = 2;
            // break;
            case "9":
              datosPorSincronizar = true;
              _viaje.pasajeros[i].modificado = 0;
              break;
            default:
          }

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viaje.pasajeros[i]);

          //UPDATE BD LOCAL
          int status = await AppDatabase.instance.Update(
            table: "pasajero_domicilio",
            value: _viaje.pasajeros[i].toJsonBDLocal(),
            where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

          await AppDatabase.instance.Update(
            table: "usuario",
            value: {
              "sesionSincronizada": _viaje.pasajeros[i].modificado == 0 ? '1' : '0',
            },
            where: "numDoc = '${_usuario.numDoc}'",
          );
          //setState(() {
          _mostrarCarga = false;
          // });
        }
      }
    }
    await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();

    //new Timer(Duration(seconds: 2), () {
    Navigator.pop(context);

    // });

    // _mostrarModalRespuesta("REGISTRADOS", "Pasajeros registrados", true)
    //     .show();

    // new Timer(Duration(seconds: 1), () {
    //   if (_verificarSalir(_viaje, _paradaActual)) {
    //   }
    // });
  }

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    if (success) _playSuccessSound();

    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, dismissOnBackKeyPress: false, dismissOnTouchOutside: false, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 2));
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
        if (_pasajeros[i].direccion == parada.direccion && _pasajeros[i].distrito == parada.distrito && _pasajeros[i].horaRecojo == parada.horaRecojo && _pasajeros[i].coordenadas == parada.coordenadas) lista.add(_cardWidget(_pasajeros[i]));
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
                  width: MediaQuery.of(context).size.width * 0.9,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ToggleButtons(
                        direction: Axis.horizontal, // vertical ? Axis.vertical : Axis.horizontal,
                        onPressed: (int index) {
                          setState(() {
                            // The button that is tapped is set to true, and the others to false.
                            for (int i = 0; i < pasajero.selectedStatus.length; i++) {
                              // print(index);
                              // print(i);

                              if (index == i) {
                                pasajero.selectedStatus[i] = true;
                              } else {
                                pasajero.selectedStatus[i] = false;
                              }
                            }

                            if (index == 0) {
                              pasajero.embarcadoAux = 1; //Embarcado
                              pasajero.fechaEmbarque = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
                            } else if (index == 1) {
                              pasajero.embarcadoAux = 0; //No embarcado
                              pasajero.fechaEmbarque = '';
                            } else if (index == 2) {
                              pasajero.embarcadoAux = 2; //En espera
                              pasajero.fechaEmbarque = '';
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

  _playSuccessSound() {
    player.play(AssetSource('sounds/success_sound.mp3'));
  }

  bool _verificarSalir(ViajeDomicilio viaje, Parada parada) {
    int porEmbarcar = 0;
    List<PasajeroDomicilio> _pasajeros = viaje.pasajeros;
    for (int i = 0; i < _pasajeros.length; i++) {
      if (_pasajeros[i].direccion == parada.direccion && _pasajeros[i].distrito == parada.distrito && _pasajeros[i].horaRecojo == parada.horaRecojo && _pasajeros[i].coordenadas == parada.coordenadas && _pasajeros[i].embarcado == 2) {
        porEmbarcar++;
      }
    }

    return porEmbarcar == 0 ? true : false;
  }
}
