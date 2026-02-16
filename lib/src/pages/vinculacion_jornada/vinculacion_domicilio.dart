import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:collection/collection.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/paradero.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VinculacionDomicilio extends StatelessWidget {
  const VinculacionDomicilio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Iniciar Viaje'),
        centerTitle: true,
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Log.insertarLogDomicilio(context: context, mensaje: "Regreso al inicio", rpta: "OK");
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: Icon(
            Icons.arrow_back_ios_new,
          ),
        ),
      ),
      body: domicilioBody(),
    );
  }
}

class domicilioBody extends StatefulWidget {
  const domicilioBody({super.key});

  @override
  State<domicilioBody> createState() => _domicilioBodyState();
}

class _domicilioBodyState extends State<domicilioBody> {
  late Usuario _usuario;
  List<ViajeDomicilio> listaViajes = [];

  int initStateBoton = 0;

  void _showDialogCargando(BuildContext context, String titulo) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return ModalCargando(titulo: titulo);
      },
    );
  }

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    ObtieneViajeDomicilioRemoteandLocal();

    super.initState();
  }

  ObtieneViajeDomicilioRemoteandLocal() async {
    if (await Permission.location.request().isGranted) {}
    List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");

    Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal cargando cargando...", rpta: "OK");
    _showDialogSincronizandoDatos(context, "Cargando...");

    if (_hayConexion()) //si hay conexion a internet
    {
      Log.insertarLogDomicilio(context: context, mensaje: "Si hay conexión a internet", rpta: "OK");
      Log.insertarLogDomicilio(context: context, mensaje: "Cantidad de viajes obtenidos de BDLocal ${listaViajeDomicilio.length}", rpta: "OK");

      List<Map<String, Object?>> listaViajeDomi = [...listaViajeDomicilio];
      if (listaViajeDomi.isNotEmpty) {
        for (var i = 0; i < listaViajeDomi.length; i++) {
          ViajeDomicilio viaje = await ActualizarViajeClicEmbarque(listaViajeDomi[i]);

          if (viaje.sentido == "I") {
            await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
          } else if (viaje.sentido == "R") {
            await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioRepartoDesdeHome(_usuario.tipoDoc, _usuario.numDoc, context, viaje);
          }
        }
      }

      var viajeServicio = new ViajeServicio();
      Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Obtener los viajes del conductor #${_usuario.numDoc} -> PA:obtener_viajes_domicilio_conductor", rpta: "OK");

      final viajes = await viajeServicio.obtenerViajesConductorVinculadoDomicilio(_usuario);

      Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Obtener los viajes del conductor #${_usuario.numDoc} -> PA:obtener_viajes_domicilio_conductor", rpta: "OK");
      var nrosViajes = viajes.map((objeto) => objeto.nroViaje.toString()).join(', ');
      Log.insertarLogDomicilio(context: context, mensaje: "Los viajes obtenidos del conductor son ${nrosViajes}", rpta: "OK");

      if (viajes.length > 0) {
        ViajeDomicilio? ViajeExisteReparto = viajes.firstWhereOrNull((element) => element.sentido == "R");

        if (ViajeExisteReparto != null) {
          await AppDatabase.instance.Eliminar(tabla: "posibles_pasajero_domicilio");

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Obtener posibles pasajeros del viaje #${ViajeExisteReparto.nroViaje} -> PA:listarPosiblesPasajeros", rpta: "OK");

          final ListasPosiblesPasajeros = await viajeServicio.obtenerPosiblesPasajeros(ViajeExisteReparto.nroViaje);

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Obtener posibles pasajeros del viaje #${ViajeExisteReparto.nroViaje} : ${ListasPosiblesPasajeros.length} pasajeros -> PA:listarPosiblesPasajeros", rpta: "OK");

          for (var i = 0; i < ListasPosiblesPasajeros.length; i++) {
            int status = await AppDatabase.instance.Guardar(
              tabla: "posibles_pasajero_domicilio",
              value: ListasPosiblesPasajeros[i].toJsonBDLocal(),
            );
          }
          Log.insertarLogDomicilio(context: context, mensaje: "Guardar posibles pasajeros BDLocal -> TBL:posibles_pasajero_domicilio", rpta: "OK");

          Provider.of<DomicilioProvider>(context, listen: false).asignarPosiblesPasajeros(ListasPosiblesPasajeros);
        }

        ViajeDomicilio viajePrimero = viajes.elementAt(0);
        viajePrimero.isActivo = true;
        setState(() {
          listaViajes = viajes;
        });

        if (viajes[0].rpta == "0") {
          await AppDatabase.instance.Eliminar(tabla: "pasajero_domicilio");
          await AppDatabase.instance.Eliminar(tabla: "viaje_domicilio");
          await AppDatabase.instance.Eliminar(tabla: "tripulante");
          await AppDatabase.instance.Eliminar(tabla: "parada");
          await AppDatabase.instance.Eliminar(tabla: "paradero");

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
        }
      } else {
        await AppDatabase.instance.Eliminar(tabla: "pasajero_domicilio");
        await AppDatabase.instance.Eliminar(tabla: "viaje_domicilio");
        await AppDatabase.instance.Eliminar(tabla: "tripulante");
        await AppDatabase.instance.Eliminar(tabla: "parada");
        await AppDatabase.instance.Eliminar(tabla: "paradero");

        Log.insertarLogDomicilio(context: context, mensaje: "Limpiamos las tablas (pasajero_domicilio,viaje_domicilio,tripulante,parada,paradero) BDLocal -> TBL:viaje_domicilio", rpta: "OK");
      }
    } else {
      Log.insertarLogDomicilio(context: context, mensaje: "No hay conexión a internet", rpta: "OK");
      Log.insertarLogDomicilio(context: context, mensaje: "Cantidad de viajes obtenidos de BDLocal ${listaViajeDomicilio.length}", rpta: "OK");
      obtenerDatosLocal(listaViajeDomicilio);
    }
    Log.insertarLogDomicilio(context: context, mensaje: "Oculta modal cargando cargando...", rpta: "OK");
    Navigator.pop(context);
  }

  obtenerDatosLocal(List<Map<String, Object?>> listaViajeDomicilio) async {
    List<ViajeDomicilio> listaViajesDomiclio = [];
    List<Map<String, Object?>> listaViajeDomi = [...listaViajeDomicilio];

    for (var i = 0; i < listaViajeDomi.length; i++) {
      ViajeDomicilio viaje = await ActualizarViajeClicEmbarque(listaViajeDomi[i]);

      if (viaje.seleccionado != "2") {
        listaViajesDomiclio.add(viaje);
      }
    }

    if (listaViajesDomiclio.isNotEmpty) {
      ViajeDomicilio viajePrimero = listaViajesDomiclio.elementAt(0);
      viajePrimero.isActivo = true;

      setState(() {
        listaViajes = listaViajesDomiclio;
      });
    }
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

  AwesomeDialog _mensaje(BuildContext context, String mensaje, DialogType dialogType) {
    return AwesomeDialog(
      context: context,
      dialogType: dialogType,
      //customHeader: null,
      animType: AnimType.topSlide,

      autoDismiss: true,
      autoHide: Duration(seconds: 3),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Text(
            mensaje,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  final TextEditingController _odometroController = TextEditingController();
  FocusNode _focusOdometro = new FocusNode();

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }
  //iniciarviaje-gps
  AwesomeDialog _showDialogIniciarViaje(BuildContext context, ViajeDomicilio viaje) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      //customHeader: null,
      animType: AnimType.topSlide,
      //showCloseIcon: true,

      body: Column(
        children: [
          // if (minutosTr < 30)
          Text(
            "¿Seguro que desea iniciar el viaje ?",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 15),

          Text(
            "Hora inicio: ${DateFormat("hh:mm a").format(DateTime.now())}",
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),

          // if (minutosTr > 30)
          TextFormField(
            textAlign: TextAlign.center,
            focusNode: _focusOdometro,
            autofocus: true,
            controller: _odometroController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Ingrese su kilometraje inicial",
              label: Text(
                "Kilometraje inicial",
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.mainBlueColor,
                ),
              ),
            ),
          ),
        ],
      ),
      reverseBtnOrder: true,
      buttonsTextStyle: TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        Log.insertarLogDomicilio(context: context, mensaje: "Inició Viaje: Muestra modal Cargando...", rpta: "OK");
        _showDialogSincronizandoDatos(context, "Cargando...");

        if (int.tryParse(_odometroController.text.trim()) == null) {
          Navigator.pop(context, 'Cancel');
          setState(() {
            _odometroController.text = "";
          });
          Log.insertarLogDomicilio(context: context, mensaje: "Error al iniciar: Ingrese un kilometraje valido.", rpta: "OK");
          _mostrarModalRespuest("ERROR AL INICIAR", "Ingrese un kilometraje valido.", false).show();
          return;
        }

        if (_odometroController.text.trim().contains('.') || _odometroController.text.trim().contains(',') || _odometroController.text.trim().contains('+')) {
          setState(() {
            _odometroController.text = "";
          });
          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Error al iniciar: El odomentro no debe contener comas(;), puntos(.) o cualquier otro caracter especial.", rpta: "OK");

          _mostrarModalRespuest("ERROR AL INICIAR", "El odomentro no debe contener comas(;), puntos(.) o cualquier otro caracter especial.", false).show();

          return;
        }

        if (_odometroController.text.trim() == "") {
          setState(() {
            _odometroController.text = "";
          });
          Navigator.pop(context, 'Cancel');
          Log.insertarLogDomicilio(context: context, mensaje: "Error al iniciar: Ingrese el kilometraje final.", rpta: "OK");

          _mostrarModalRespuest("ERROR AL INICIAR", "Ingrese el kilometraje final.", false).show();
          return;
        }

        if (int.parse(_odometroController.text.trim()) <= 0) {
          setState(() {
            _odometroController.text = "";
          });
          Navigator.pop(context, 'Cancel');

          Log.insertarLogDomicilio(context: context, mensaje: "Error al iniciar: EL kilometraje inicial no puede ser 0 o menor.", rpta: "OK");

          _mostrarModalRespuest("ERROR AL INICIAR", "EL kilometraje inicial no puede ser 0 o menor.", false).show();
          return;
        }

        ViajeDomicilio viajeRecojoExiste = ViajeDomicilio();

        List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");
        List<ViajeDomicilio> ListaViajesDomicilios = listaViajeDomicilio.map((e) => ViajeDomicilio.fromJsonMapBDLocal(e)).toList();

        for (var i = 0; i < ListaViajesDomicilios.length; i++) {
          if (ListaViajesDomicilios[i].sentido == 'I' && ListaViajesDomicilios[i].nroViaje != viaje.nroViaje && ListaViajesDomicilios[i].unidad == viaje.unidad && ListaViajesDomicilios[i].estadoViaje == "1" && ListaViajesDomicilios[i].seleccionado == "2") {
            viajeRecojoExiste = ListaViajesDomicilios[i];
          }
        }

        if (viajeRecojoExiste.nroViaje.trim() != "") {
          if (int.parse(_odometroController.text.trim()) < viajeRecojoExiste.odometroFinal) {
            setState(() {
              _odometroController.text = "";
            });
            Navigator.pop(context, 'Cancel');
            Log.insertarLogDomicilio(context: context, mensaje: "Tu kilometraje no puede ser menor al kilometra final del viaje anterior.", rpta: "OK");

            _mostrarModalRespuest("ERROR AL INICIAR", "Tu kilometraje no puede ser menor al kilometra final del viaje anterior.", false).show();
            return;
          }

          if (int.parse(_odometroController.text.trim()) <= viajeRecojoExiste.odometroInicial) {
            setState(() {
              _odometroController.text = "";
            });
            Navigator.pop(context, 'Cancel');

            Log.insertarLogDomicilio(context: context, mensaje: "EL kilometraje final no puede ser menor o igual al kilometraje inicial.", rpta: "OK");

            _mostrarModalRespuest("ERROR AL INICIAR", "EL kilometraje final no puede ser menor o igual al kilometraje inicial.", false).show();
            return;
          }
        }

        // if (await Permission.location.request().isGranted) {}
        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Inicia viaje el conductor #${viaje.nroViaje} -> PA:IniciarViaje", rpta: "OK");

        Response? res = await _embarquesSupScanerServicio.IniciarViaje(
          viaje.nroViaje.trim(),
          _usuario.numDoc.trim(),
          "1",
          _usuario.tipoDoc.trim(),
          _usuario.numDoc.trim(),
          _usuario.codOperacion.trim(),
          _odometroController.text.trim(),
          posicionActual,
        );

        bool requestSuccess = false;

        if (res != null) {
          final data = json.decode(res.body);

          if (data["rpta"] != '0') {
            requestSuccess = false;

            Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Inicia viaje el conductor #${viaje.nroViaje} -> PA:IniciarViaje", rpta: "ERROR->${data["Mensaje"]}");

            _mostrarModalRespuesta(DialogType.error, "Error al vincular", "", _usuario.viajeEmp).show();
            return;
          }

          if (data["rpta"] == "0") {
            Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Inicia viaje el conductor #${viaje.nroViaje} -> PA:IniciarViaje", rpta: "OK");
            requestSuccess = true;
          }
        }

        int statusv = await AppDatabase.instance.Update(
          table: "viaje_domicilio",
          value: {
            "odometroInicial": '${_odometroController.text.trim()}',
            "cordenadaInicial": '${posicionActual}',
            "seleccionado": "1",
            "estadoInicioViaje": requestSuccess ? '0' : '1',
          },
          where: "nroViaje = '${viaje.nroViaje}'",
        );

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia el viaje en BDLocal -> TBL:viaje_domicilio", rpta: "${statusv > 0 ? "OK" : "ERROR->${statusv}"}");

        int statusu = await AppDatabase.instance.Update(
          table: "usuario",
          value: {
            "vinculacionActiva": "1",
            "viajeEmp": '${viaje.nroViaje}',
            "unidadEmp": '${viaje.unidad.split('-')[0]}',
            "placaEmp": '${viaje.unidad.split('-')[1]}',
            "fechaEmp": '${DateFormat('d-M-y H:m').format(DateTime.now())}',
            "sesionSincronizada": requestSuccess ? '0' : '1',
          },
          where: "numDoc = '${_usuario.numDoc}'",
        );

        Log.insertarLogDomicilio(context: context, mensaje: "Vincula al usuario con el viaje en BDLocal -> TBL:usuario", rpta: "${statusu > 0 ? "OK" : "ERROR->${statusu}"}");

        Provider.of<UsuarioProvider>(context, listen: false).emparejar(
          viaje.nroViaje,
          '${viaje.unidad.split('-')[0]}',
          '${viaje.unidad.split('-')[1]}',
          '${DateFormat('d-M-y H:m').format(DateTime.now())}',
          "1",
        );

        Navigator.pop(context, 'Cancel');
        _mostrarModalRespuestaSuccessIniciViaje(DialogType.success, "Inicio de viaje correctamente", "", _usuario.viajeEmp).show();
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  AwesomeDialog _mostrarModalRespuestaSuccessIniciViaje(DialogType tipo, String titulo, String cuerpo, String nroViaje) {
    return AwesomeDialog(
      context: context,
      dialogType: tipo,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      autoHide: Duration(seconds: 2),
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      onDismissCallback: (type) async {
        Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
      },
    );
  }

  AwesomeDialog _mostrarModalRespuesta(DialogType tipo, String titulo, String cuerpo, String nroViaje) {
    return AwesomeDialog(
      context: context,
      dialogType: tipo,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      autoHide: Duration(seconds: 2),
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      onDismissCallback: (type) async {
        setState(() {});
      },
    );
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

  void _MostrarPasajeros(BuildContext context, ViajeDomicilio viaje) {
    List<Parada> _paradas = viaje.paradas;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            margin: EdgeInsets.only(top: 48),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            size: 45,
                            color: AppColors.mainBlueColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          "LISTA DE PASAJEROS  ${viaje.sentido == "I" ? "RECOJO" : "REPARTO"}",
                          style: TextStyle(
                            color: AppColors.mainBlueColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _paradas.map((e) {
                          return card(e, viaje) as Widget;
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  card(Parada parada, ViajeDomicilio viaje) {
    List<PasajeroDomicilio> _pasajeros = viaje.pasajeros;

    Color color = AppColors.blackColor;
    bool mostrarIcono = false;
    Widget icono = Icon(Icons.bus_alert);

    List<PasajeroDomicilio> _pasajeroParada = [];
    for (var i = 0; i < _pasajeros.length; i++) {
      if (_pasajeros[i].direccion == parada.direccion && _pasajeros[i].distrito == parada.distrito && _pasajeros[i].horaRecojo == parada.horaRecojo && _pasajeros[i].coordenadas == parada.coordenadas && parada.nroViaje.trim() == viaje.nroViaje.trim()) {
        _pasajeroParada.add(_pasajeros[i]);
      }
    }

    switch (parada.estado) {
      case "0":
        mostrarIcono = false;
        color = AppColors.mainBlueColor;
        icono = ImageIcon(
          AssetImage(parada.recojoTaxi == "0" ? 'assets/icons/route_alt.png' : "assets/icons/car_punto.png"),
          color: (parada.recojoTaxi == "0" ? AppColors.mainBlueColor : Colors.yellow.shade700),
          size: 50,
        );
        break;
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        //horizontalTitleGap: 10,
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
        leading: !mostrarIcono ? null : icono,
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: _pasajeroParada
                  .map((e) => Text(
                        '* ${e.nombres}',
                        style: TextStyle(
                          fontSize: 19,
                        ),
                      ))
                  .toList(),
            ),
            Text(
              "${parada.direccion} - ${parada.distrito.toUpperCase()}",
              style: TextStyle(
                fontSize: 17,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      displacement: 75,
      onRefresh: () {
        return Future.delayed(Duration(seconds: 1), () async {
          ObtieneViajeDomicilioRemoteandLocal();
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            children: listaViajes.map((viaje) {
              return Card(
                color: viaje.isActivo == true ? AppColors.mainBlueColor : Colors.white,
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.only(left: 20, right: 10, top: 15, bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${viaje.sentido == "I" ? "RECOJO" : "REPARTO"}",
                            style: TextStyle(
                              fontSize: viaje.isActivo == true ? 26 : 22,
                              color: viaje.isActivo == true ? Colors.white : AppColors.mainBlueColor,
                              fontWeight: viaje.isActivo == true ? FontWeight.bold : null,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "${viaje.unidad}",
                            style: TextStyle(
                              fontSize: viaje.isActivo == true ? 24 : 20,
                              color: viaje.isActivo == true ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "${viaje.horaSalida}",
                            style: TextStyle(
                              fontSize: viaje.isActivo == true ? 24 : 20,
                              color: viaje.isActivo == true ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "PASAJEROS: ${viaje.pasajeros.length}",
                            style: TextStyle(
                              fontSize: viaje.isActivo == true ? 24 : 20,
                              color: viaje.isActivo == true ? Colors.white : Colors.black,
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          MaterialButton(
                              color: viaje.isActivo == true ? Colors.white : AppColors.mainBlueColor,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(0),
                              minWidth: width * 0.1,
                              onPressed: () {
                                Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal de informacion de los pasajeros", rpta: "OK");
                                _MostrarPasajeros(context, viaje);
                              },
                              child: Stack(
                                children: [
                                  Image.asset(
                                    "assets/images/Iconos_Manifiesto.png",
                                    width: 65,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 25,
                                    right: 9,
                                    child: Image.asset(
                                      "assets/icons/person_check.png",
                                      width: 20,
                                      height: 22,
                                      fit: BoxFit.cover,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              )),
                          SizedBox(width: 4),
                          if (viaje.isActivo == true)
                            MaterialButton(
                              shape: CircleBorder(),
                              color: viaje.isActivo == true ? Colors.white : AppColors.mainBlueColor,
                              padding: EdgeInsets.all(0),
                              minWidth: width * 0.1,
                              onPressed: () {
                                Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal de iniciar viaje", rpta: "OK");
                                _showDialogIniciarViaje(context, viaje).show();
                              },
                              child: Image.asset(
                                "assets/images/Iconos_Vincular_check.png",
                                width: 65,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  AwesomeDialog _mostrarModalRespuest(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, title: titulo, desc: cuerpo, descTextStyle: TextStyle(fontSize: 15), autoHide: Duration(seconds: 2), dismissOnBackKeyPress: false, dismissOnTouchOutside: false);
  }
}

class ModalCargando extends StatelessWidget {
  const ModalCargando({
    super.key,
    required String titulo,
  }) : _titulo = titulo;

  final String _titulo;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: AlertDialog(
          title: Text(
            _titulo,
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
  }
}

class _inputNDocConductor extends StatelessWidget {
  const _inputNDocConductor({
    super.key,
    required TextEditingController numConductorController,
    required FocusNode focusNumCond,
    required Function() onEditingComplete,
    required Function() onPressed,
    required String label,
    required String hintText,
    required bool enabled,
  })  : _numConductorController = numConductorController,
        _focusNumCond = focusNumCond,
        _onEditingComplete = onEditingComplete,
        _onPressed = onPressed,
        _label = label,
        _hintText = hintText,
        _enabled = enabled;

  final TextEditingController _numConductorController;
  final FocusNode _focusNumCond;
  final Function()? _onEditingComplete;
  final void Function()? _onPressed;
  final String _label;
  final String _hintText;
  final bool _enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        enabled: _enabled,
        textAlign: TextAlign.center,
        controller: _numConductorController,
        focusNode: _focusNumCond,
        autofocus: true,
        decoration: InputDecoration(
            isCollapsed: true,
            hintText: _hintText,
            label: Text(
              _label,
              style: TextStyle(
                color: AppColors.mainBlueColor,
                fontSize: 22,
              ),
            ),
            suffix: IconButton(
              icon: Icon(Icons.qr_code_scanner_rounded),
              onPressed: _onPressed,
            )),
        onEditingComplete: _onEditingComplete);
  }
}
