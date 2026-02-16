import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/jornada.dart';
import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/pages/jornada/bloc/jornada/jornada_bloc.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class VinculacionBolsa extends StatelessWidget {
  const VinculacionBolsa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Iniciar Viaje Bolsa'),
        centerTitle: true,
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
  List<Viaje> listaViajes = [];

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

  bool odometroObtenido = false;

  @override
  void initState() {
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    ObtieneViajeDomicilioRemoteandLocal();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  ObtieneViajeDomicilioRemoteandLocal() async {
    List<Map<String, Object?>> listaViajeBolsa = await AppDatabase.instance.Listar(tabla: "viaje");
    _showDialogSincronizandoDatos(context, "Cargando...");

    if (_hayConexion()) //si hay conexion a internet
    {
      var viajeServicio = new ViajeServicio();

      final viajes = await viajeServicio.obtenerViajesProgramdosBolsa(_usuario);

      if (viajes.length > 0) {
        Viaje viajePrimero = viajes.elementAt(0);
        viajePrimero.isActivo = true;

        for (var viaje in viajes) {
          List<Tripulante> listTripulante = [];

          for (var tripulante in viaje.tripulantes) {
            if (tripulante.numDoc != "") {
              listTripulante.add(tripulante);
            }
          }

          viaje.tripulantes = listTripulante;
        }

        setState(() {
          listaViajes = viajes;
        });

        if (viajes[0].rpta == "0") {
          await AppDatabase.instance.Eliminar(tabla: "viaje");
          await AppDatabase.instance.Eliminar(tabla: "punto_embarque");
          await AppDatabase.instance.Eliminar(tabla: "pasajero");
          await AppDatabase.instance.Eliminar(tabla: "tripulante");

          for (var i = 0; i < viajes.length; i++) {
            viajes[i].fechaConsultada = DateTime.now().toString();
            await AppDatabase.instance.Guardar(tabla: "viaje", value: viajes[i].toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA EL VIAJE EN BD LOCAL

            final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
              viajes[i].nroViaje,
              viajes[i].codOperacion,
            );

            for (var puntoEmabarque in puntosEmabarque) {
              puntoEmabarque.nroViaje = viajes[i].nroViaje;
              await AppDatabase.instance.Guardar(tabla: "punto_embarque", value: puntoEmabarque.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PUNTOS DE EMBARQUE DEL VIAJE EN BD LOCAL
            }

            var servicio = new PasajeroServicio();
            // final listadoPrereservas = await servicio.obtener_prereservas(viajes[i].nroViaje, _usuario.tipoDoc, _usuario.numDoc, viajes[i].subOperacionId);

            // for (var prereserva in listadoPrereservas) {
            //   await AppDatabase.instance.Guardar(tabla: "pasajero", value: prereserva.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PRERESERVA DEL VIAJE EN BD LOCAL
            // }

            for (var pasajero in viajes[i].pasajeros) {
              await AppDatabase.instance.Guardar(tabla: "pasajero", value: pasajero.toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA PASAJEROS DEL VIAJE EN BD LOCAL
            }

            for (var j = 0; j < viajes[i].tripulantes.length; j++) {
              if (viajes[i].tripulantes[j].numDoc != "") {
                viajes[i].tripulantes[j].orden = "${j + 1}";
                await AppDatabase.instance.Guardar(tabla: "tripulante", value: viajes[i].tripulantes[j].toMapDatabase()); //17/07/2023  -- JOHN SAMUEL : GUARDA LA TRIPULANTES DEL VIAJE EN BD LOCAL
              }
            }
          }
        }
      } else {
        await AppDatabase.instance.Eliminar(tabla: "viaje");
        await AppDatabase.instance.Eliminar(tabla: "punto_embarque");
        await AppDatabase.instance.Eliminar(tabla: "pasajero");
        await AppDatabase.instance.Eliminar(tabla: "tripulante");
      }
    } else {
      obtenerDatosLocal(listaViajeBolsa);
    }
    Navigator.pop(context);
  }

  obtenerDatosLocal(List<Map<String, Object?>> listaViajeBolsa) async {
    List<Viaje> listaViajesBolsa = [];
    List<Map<String, Object?>> listaViajeBols = [...listaViajeBolsa];

    for (var i = 0; i < listaViajeBols.length; i++) {
      Viaje viaje = await ActualizarViajeEmbarqueBolsaBDLocal(listaViajeBols[i]);

      if (viaje.seleccionado != "2") {
        listaViajesBolsa.add(viaje);
      }
    }
    Viaje viajePrimero = listaViajesBolsa.elementAt(0);
    viajePrimero.isActivo = true;

    setState(() {
      listaViajes = listaViajesBolsa;
    });
  }

  Future<Viaje> ActualizarViajeEmbarqueBolsaBDLocal(Map<String, dynamic> json) async {
    Viaje viaje;
    viaje = Viaje.fromJsonMapVinculadoLocal(json);

    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero", where: "nroViaje = '${viaje.nroViaje}'");
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
  AwesomeDialog _showDialogIniciarViaje(BuildContext context, Viaje viaje) {
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
            "Hora Inicio: ${DateFormat("hh:mm a").format(DateTime.now())}",
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
        _showDialogSincronizandoDatos(context, "Cargando...");

        if (int.tryParse(_odometroController.text.trim()) == null) {
          Navigator.pop(context, 'Cancel');
          setState(() {
            _odometroController.text = "";
          });

          _mostrarModalRespuest("ERROR AL INICIAR", "Ingrese un kilometraje valido.", false).show();
          return;
        }

        if (_odometroController.text.trim().contains('.') || _odometroController.text.trim().contains(',') || _odometroController.text.trim().contains('+')) {
          setState(() {
            _odometroController.text = "";
          });
          Navigator.pop(context, 'Cancel');

          _mostrarModalRespuest("ERROR AL INICIAR", "El odomentro no debe contener comas(;), puntos(.) o cualquier otro caracter especial.", false).show();

          return;
        }

        if (_odometroController.text.trim() == "") {
          setState(() {
            _odometroController.text = "";
          });
          Navigator.pop(context, 'Cancel');
          _mostrarModalRespuest("ERROR AL INICIAR", "Ingrese el kilometraje final.", false).show();

          return;
        }

        if (int.parse(_odometroController.text.trim()) <= 0) {
          setState(() {
            _odometroController.text = "";
          });
          Navigator.pop(context, 'Cancel');

          _mostrarModalRespuest("ERROR AL INICIAR", "EL kilometraje inicial no puede ser 0 o menor.", false).show();
          return;
        }

        Viaje viajeRecojoExiste = Viaje();

        // List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");
        // List<ViajeDomicilio> ListaViajesDomicilios = listaViajeDomicilio.map((e) => ViajeDomicilio.fromJsonMapBDLocal(e)).toList();

        // for (var i = 0; i < ListaViajesDomicilios.length; i++) {
        //   if (ListaViajesDomicilios[i].sentido == 'I' && ListaViajesDomicilios[i].nroViaje != viaje.nroViaje && ListaViajesDomicilios[i].unidad == viaje.unidad && ListaViajesDomicilios[i].estadoViaje == "1" && ListaViajesDomicilios[i].seleccionado == "2") {
        //     viajeRecojoExiste = ListaViajesDomicilios[i];
        //   }
        // }

        if (viajeRecojoExiste.nroViaje.trim() != "") {
          if (int.parse(_odometroController.text.trim()) < viajeRecojoExiste.odometroFinal) {
            setState(() {
              _odometroController.text = "";
            });
            Navigator.pop(context, 'Cancel');
            _mostrarModalRespuest("ERROR AL INICIAR", "Tu kilometraje no puede ser menor al kilometra final del viaje anterior.", false).show();
            return;
          }

          if (int.parse(_odometroController.text.trim()) <= viajeRecojoExiste.odometroInicial) {
            setState(() {
              _odometroController.text = "";
            });
            Navigator.pop(context, 'Cancel');
            _mostrarModalRespuest("ERROR AL INICIAR", "EL kilometraje final no puede ser menor o igual al kilometraje inicial.", false).show();
            return;
          }
        }

        if (await Permission.location.request().isGranted) {}

        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();
        bool requestSuccess = false;

        for (var i = 0; i < viaje.tripulantes.length; i++) {
          Response? res = await _embarquesSupScanerServicio.vincularInicioJornada_v2(
            viaje.nroViaje.trim(),
            viaje.tripulantes[i].numDoc.trim(),
            viaje.tripulantes[i].orden,
            _usuario.tipoDoc.trim(),
            _usuario.numDoc.trim(),
            _usuario.codOperacion.trim(),
            _odometroController.text.trim(),
            posicionActual,
            odometroObtenido ? 'SIGPS' : 'NOGPS',
          );

          if (res != null) {
            final data = json.decode(res.body);

            if (data["rpta"] == "0") {
              requestSuccess = true;
            }

            if (data["rpta"] != '0') {
              print(viaje.tripulantes[i]);

              requestSuccess = false;
              Navigator.pop(context);
              _mostrarModalRespuesta(DialogType.error, "Error al vincular", "${viaje.tripulantes[i].nombres} ${data["mensaje"]}", _usuario.viajeEmp, viaje).show();
              setState(() {
                _odometroController.text = "";
              });
              return;
            }
          }
        }

        for (var i = 0; i < viaje.tripulantes.length; i++) {
          context.read<JornadaBloc>().add(
                AddTripulante(
                  viaje.nroViaje.trim(),
                  viaje.tripulantes[i].tipoDoc.trim(),
                  viaje.tripulantes[i].numDoc.trim(),
                  viaje.tripulantes[i].nombres.trim(),
                ),
              );
        }

        await AppDatabase.instance.Update(
          table: "viaje",
          value: {
            "odometroInicial": '${_odometroController.text.trim()}',
            "seleccionado": "1",
            "estadoInicioViaje": requestSuccess ? '0' : '1',
            "cordenadaInicial": "${posicionActual}",
          },
          where: "nroViaje = '${viaje.nroViaje}'",
        );

        await AppDatabase.instance.Update(
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

        Provider.of<UsuarioProvider>(context, listen: false).emparejar(
          viaje.nroViaje,
          '${viaje.unidad.split('-')[0]}',
          '${viaje.unidad.split('-')[1]}',
          '${DateFormat('d-M-y H:m').format(DateTime.now())}',
          "1",
        );

        Navigator.pop(context, 'Cancel');
        Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viaje);
        _mostrarModalRespuestaSuccessIniciViaje(DialogType.success, "Inicio de viaje correctamente", "", _usuario.viajeEmp).show();
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  Future<Map<String, dynamic>> ObtenerOdometroViaje(String codUnidad) async {
    final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();
    Response? res = await _embarquesSupScanerServicio.ObtenerOdometroViaje(codUnidad.trim());

    String rpta = "0";
    String mensaje = "0";

    if (res != null) {
      final data = json.decode(res.body);
      if (data["rpta"] == "0") {
        setState(() {
          odometroObtenido = true;
        });
        rpta = "0";
        mensaje = data["mensaje"];
      } else {
        setState(() {
          odometroObtenido = false;
        });
        rpta = "1";
        mensaje = data["mensaje"];
      }
    } else {
      setState(() {
        odometroObtenido = false;
      });
      rpta = "1";
      mensaje = "Error en la consulta";
    }

    return {"rpta": rpta, "mensaje": mensaje};
  }

  AwesomeDialog _showDialogIniciarViajeSinOdomentro(BuildContext context, Viaje viaje, String odometro) {
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
            "Hora Inicio: ${DateFormat("hh:mm a").format(DateTime.now())}",
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),

          Text(
            "Km. Inicial: $odometro",
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
        ],
      ),
      reverseBtnOrder: true,
      buttonsTextStyle: TextStyle(fontSize: 30),
      btnOkText: "Sí",
      btnOkColor: AppColors.greenColor,
      btnOkOnPress: () async {
        _showDialogSincronizandoDatos(context, "Cargando...");

        final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();
        bool requestSuccess = false;

        if (await Permission.location.request().isGranted) {}

        String posicionActual;
        try {
          Position posicionActualGPS = await Geolocator.getCurrentPosition();
          posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
        } catch (e) {
          posicionActual = "0, 0-Error no controlado";
        }

        for (var i = 0; i < viaje.tripulantes.length; i++) {
          Response? res = await _embarquesSupScanerServicio.vincularInicioJornada_v2(
            viaje.nroViaje.trim(),
            viaje.tripulantes[i].numDoc.trim(),
            viaje.tripulantes[i].orden,
            _usuario.tipoDoc.trim(),
            _usuario.numDoc.trim(),
            _usuario.codOperacion.trim(),
            odometro,
            posicionActual,
            odometroObtenido ? 'SIGPS' : 'NOGPS',
          );

          if (res != null) {
            final data = json.decode(res.body);

            if (data["rpta"] == "0") {
              requestSuccess = true;
            }

            if (data["rpta"] != '0') {
              print(viaje.tripulantes[i]);

              requestSuccess = false;
              Navigator.pop(context);
              _mostrarModalRespuesta(DialogType.error, "Error al vincular", "${viaje.tripulantes[i].nombres} ${data["mensaje"]}", _usuario.viajeEmp, viaje).show();
              setState(() {
                _odometroController.text = "";
              });
              return;
            }
          }
        }

        for (var i = 0; i < viaje.tripulantes.length; i++) {
          context.read<JornadaBloc>().add(
                AddTripulante(
                  viaje.nroViaje.trim(),
                  viaje.tripulantes[i].tipoDoc.trim(),
                  viaje.tripulantes[i].numDoc.trim(),
                  viaje.tripulantes[i].nombres.trim(),
                ),
              );
        }

        await AppDatabase.instance.Update(
          table: "viaje",
          value: {
            "odometroInicial": '${odometro}',
            "seleccionado": "1",
            "estadoInicioViaje": requestSuccess ? '0' : '1',
            "cordenadaInicial": "${posicionActual}",
          },
          where: "nroViaje = '${viaje.nroViaje}'",
        );

        await AppDatabase.instance.Update(
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

        Provider.of<UsuarioProvider>(context, listen: false).emparejar(
          viaje.nroViaje,
          '${viaje.unidad.split('-')[0]}',
          '${viaje.unidad.split('-')[1]}',
          '${DateFormat('d-M-y H:m').format(DateTime.now())}',
          "1",
        );

        Navigator.pop(context, 'Cancel');
        Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viaje);
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

  AwesomeDialog _mostrarModalRespuesta(DialogType tipo, String titulo, String cuerpo, String nroViaje, Viaje viaje) {
    return AwesomeDialog(
      context: context,
      dialogType: tipo,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      autoHide: Duration(seconds: 3),
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

  void _MostrarPasajeros(BuildContext context, Viaje viaje) {
    List<Tripulante> _tripulantes = viaje.tripulantes;

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
                          "LISTA DE TRIPULANTES",
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
                        children: _tripulantes.map((e) {
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

  card(Tripulante tripulante, Viaje viaje) {
    Color color = AppColors.blackColor;
    bool mostrarIcono = false;
    Widget icono = Icon(Icons.bus_alert);

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
            "cojo",
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
            Text(
              "${tripulante.nombres}",
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
                          // Text(
                          //   "${viaje.sentido == "I" ? "RECOJO" : "REPARTO"}",
                          //   style: TextStyle(
                          //     fontSize: viaje.isActivo == true ? 28 : 23,
                          //     color: viaje.isActivo == true ? Colors.white : AppColors.mainBlueColor,
                          //     fontWeight: viaje.isActivo == true ? FontWeight.bold : null,
                          //   ),
                          // ),
                          SizedBox(height: 2),
                          Text(
                            "${viaje.unidad}",
                            style: TextStyle(
                              fontSize: viaje.isActivo == true ? 26 : 21,
                              color: viaje.isActivo == true ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "${viaje.horaSalida}",
                            style: TextStyle(
                              fontSize: viaje.isActivo == true ? 26 : 21,
                              color: viaje.isActivo == true ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "PASAJEROS: ${viaje.pasajeros.length}",
                            style: TextStyle(
                              fontSize: viaje.isActivo == true ? 26 : 21,
                              color: viaje.isActivo == true ? Colors.white : Colors.black,
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          // MaterialButton(
                          //     color: viaje.isActivo == true ? Colors.white : AppColors.mainBlueColor,
                          //     shape: CircleBorder(),
                          //     padding: EdgeInsets.all(0),
                          //     minWidth: width * 0.1,
                          //     onPressed: () {
                          //       _MostrarPasajeros(context, viaje);
                          //     },
                          //     child: Stack(
                          //       children: [
                          //         Image.asset(
                          //           "assets/images/Iconos_Manifiesto.png",
                          //           width: 70,
                          //           height: 75,
                          //           fit: BoxFit.cover,
                          //         ),
                          //         Positioned(
                          //           bottom: 25,
                          //           right: 9,
                          //           child: Image.asset(
                          //             "assets/icons/person_check.png",
                          //             width: 22,
                          //             height: 24,
                          //             fit: BoxFit.cover,
                          //             color: Colors.amber,
                          //           ),
                          //         ),
                          //       ],
                          //     )),
                          SizedBox(width: 4),
                          if (viaje.isActivo == true)
                            MaterialButton(
                              shape: CircleBorder(),
                              color: viaje.isActivo == true ? Colors.white : AppColors.mainBlueColor,
                              padding: EdgeInsets.all(0),
                              minWidth: width * 0.1,
                              onPressed: () async {
                                var codUnidad = viaje.unidad.split("-")[0];
                                _showDialogSincronizandoDatos(context, "Cargando...");
                                Map<String, dynamic> odometroDato = await ObtenerOdometroViaje(codUnidad);

                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }

                                if (odometroDato["rpta"] == "0") {
                                  _showDialogIniciarViajeSinOdomentro(context, viaje, odometroDato["mensaje"]).show();
                                } else {
                                  _showDialogIniciarViaje(context, viaje).show();
                                }
                              },
                              child: Image.asset(
                                "assets/images/Iconos_Vincular_check.png",
                                width: 70,
                                height: 75,
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
