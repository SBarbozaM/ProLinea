import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:geolocator_platform_interface/src/enums/location_service.dart' as srv;
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../models/usuario.dart';
import '../../models/viaje_domicilio/pasajero_domicilio.dart';
import '../../providers/providers.dart';
import '../../services/pasajero_servicio.dart';
import '../../utils/app_colors.dart';

class ViajeDomicilioMapaRecojoPage extends StatefulWidget {
  const ViajeDomicilioMapaRecojoPage({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioMapaRecojoPage> createState() => _ViajeDomicilioMapaRecojoPageState();
}

class _ViajeDomicilioMapaRecojoPageState extends State<ViajeDomicilioMapaRecojoPage> {
  ViajeServicio servicio = new ViajeServicio();
  late Timer _timer;
  late Usuario _usuario;
  final player = AudioPlayer();

  bool _loading = true;
  bool _gpsEnabled = false;
  bool _initialPositionSet = false;
  StreamSubscription? _gpsSubscription, _positionSubscription;
  Position? _initialPosition;
  Map<MarkerId, Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};

  Completer<GoogleMapController> _controller = Completer();

  double _lat = 0;
  double _lon = 0;
  String _markerActual = "";
  @override
  void initState() {
    _init();
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    _timer = new Timer.periodic(Duration(seconds: 3), (timer) {
      /*SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
        SystemUiOverlay.bottom, //This line is used for showing the bottom bar
      ]);*/
      //setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    _gpsSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    PermissionStatus locationPermission = await Permission.locationWhenInUse.request();

    if (locationPermission == PermissionStatus.denied) {
      Navigator.popAndPushNamed(context, 'inicio');
    }

    if (locationPermission == PermissionStatus.permanentlyDenied) {
      Navigator.popAndPushNamed(context, 'inicio');
    }
    _gpsEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _loading = false;
    });

    _gpsSubscription = Geolocator.getServiceStatusStream().listen(
      (status) async {
        _gpsEnabled = status == srv.ServiceStatus.enabled;

        if (_gpsEnabled) {
          _initLocationUpdates();
        }
        setState(() {});
      },
    );
    _initLocationUpdates();
  }

  Future<void> turnOnGPS() => Geolocator.openLocationSettings();

  Future<void> _initLocationUpdates() async {
    bool initialized = false;
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream().listen(
      (position) async {
        //print(position);
        if (!initialized) {
          _setInitialPosition(position);
          initialized = true;
        }

        /*if (_mapController != null) {
          final zoom = await _mapController!.getZoomLevel();
          final cameraUpdate = CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude), zoom);
          _mapController!.animateCamera(cameraUpdate);
        }*/
      },
      onError: (e) {
        if (e is LocationServiceDisabledException) {
          setState(() {
            _gpsEnabled = false;
          });
        }
      },
    );
  }

  void _setInitialPosition(Position position) async {
    if (_gpsEnabled && _initialPosition == null) {
      _initialPosition = position;
      _lat = position.latitude;
      _lon = position.longitude;
      CameraPosition cameraPosition = new CameraPosition(
        target: LatLng(_lat, _lon),
        zoom: 14,
      );

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      setState(() {
        _initialPositionSet = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //double width = MediaQuery.of(context).size.width;
    //double height = MediaQuery.of(context).size.height;
    ViajeDomicilio _viaje = Provider.of<DomicilioProvider>(context).viaje;

    //LatLng(_initialPosition!.latitude, _initialPosition!.longitude);

    getMarkers(_viaje);
    getPolylines(_viaje);

    _cambiarMarkerMostrado();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: _loading
            ? Center(child: CircularProgressIndicator())
            : _gpsEnabled
                ? _esEmbarque(_viaje)
                    ? GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(target: LatLng(_lat, _lon), zoom: 13),
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        markers: _markers.values.toSet(),
                        polylines: _polylines.values.toSet(),
                        myLocationButtonEnabled: true,
                        myLocationEnabled: true,
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Recojo Terminado"),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Es necesario que el GPS esté activado"),
                        SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            turnOnGPS();
                          },
                          child: Text("Activar"),
                        ),
                      ],
                    ),
                  ),
        floatingActionButtonLocation: _esEmbarque(_viaje) ? FloatingActionButtonLocation.startFloat : null,
        floatingActionButton: _gpsEnabled
            ? _esEmbarque(_viaje)
                ? FloatingActionButton(
                    tooltip: "Pasajero",
                    onPressed: _gpsEnabled
                        ? () async {
                            await _irAlProximoPunto();
                          }
                        : null,
                    child: Icon(
                      Icons.not_listed_location,
                      size: 40,
                    ),
                    backgroundColor: AppColors.blueColor,
                  )
                : null
            : null,
      ),
    );
  }

  getMarkers(ViajeDomicilio viaje) async {
    List<Parada> paradas = viaje.paradas;

    Map<MarkerId, Marker> markers = {};
    for (int i = 0; i < paradas.length; i++) {
      if (paradas[i].coordenadas != "" && paradas[i].coordenadas.trim() != "0, 0") {
        int width = 75, height = 75;
        Color color = AppColors.blackColor;
        /*bool puedeRegistrarLlegada = false;
        bool puedeEmbarcar = false;*/

        switch (paradas[i].estado) {
          case 0:
            color = AppColors.blackColor;
            break;
          case 1:
            color = AppColors.mainBlueColor;

            break;
          case 2:
            color = AppColors.darkTurquesa;

            break;
          case 3:
            color = AppColors.greyColor;

            break;
          default:
        }

        final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(pictureRecorder);
        final Paint paint = Paint()..color = color;

        canvas.drawOval(Rect.fromCircle(center: Offset(width * 0.5, height * 0.5), radius: min(width * 0.5, height * 0.5)), paint);
        TextPainter painter = TextPainter(textDirection: ui.TextDirection.ltr);
        painter.text = TextSpan(text: (i + 1).toString(), style: TextStyle(fontSize: 50.0, color: Colors.white));
        painter.layout();
        painter.paint(canvas, Offset((width * 0.5) - painter.width * 0.5, (height * 0.5) - painter.height * 0.5));

        final img = await pictureRecorder.endRecording().toImage(width, height);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);

        LatLng latlng = getPosition(paradas[i].coordenadas);

        final markerId = MarkerId(paradas[i].orden);
        Marker marker = new Marker(
            markerId: MarkerId(paradas[i].orden),
            position: latlng,
            anchor: Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: "[" + paradas[i].horaRecojo + "] " + paradas[i].direccion,
              snippet: paradas[i].distrito,
              onTap: () async {
                if (paradas[i].estado == 1) {
                  Log.insertarLogDomicilio(context: context, mensaje: "Muestra modal llego al punto de reparto", rpta: "OK");
                  _modalLlegoConductor(paradas[i]).show();
                }
                if (paradas[i].estado == 2) {
                  Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla recojo de pasajeros", rpta: "OK");
                  await Provider.of<DomicilioProvider>(context, listen: false).actualizarParada(paradas[i]);

                  Navigator.pushNamed(context, 'recojo');
                }
              },
            ),
            icon: BitmapDescriptor.fromBytes(data!.buffer.asUint8List()));
        markers[markerId] = marker;
      }
    }
    _markers = markers;

    bool actualizarMapa = await Provider.of<DomicilioProvider>(context, listen: false).actualizarMapa;

    if (actualizarMapa) {
      setState(() async {
        await Provider.of<DomicilioProvider>(context, listen: false).cambiarEstadoActualizarMapa(false);
      });
    }

    //_controller.actualizarMarkers(markers);
    //return _controller.markers;
  }

  getPolylines(ViajeDomicilio viaje) async {
    List<Parada> paradas = viaje.paradas;

    PolylineId polylineId = PolylineId("ruta");

    _polylines = {};

    for (int i = 0; i < paradas.length; i++) {
      if (paradas[i].coordenadas != "" && paradas[i].coordenadas.trim() != "0, 0") {
        LatLng latlng = getPosition(paradas[i].coordenadas);

        Polyline polyline;
        if (_polylines.containsKey(polylineId)) {
          final temp = _polylines[polylineId];
          polyline = temp!.copyWith(pointsParam: [...temp.points, latlng]);
        } else {
          polyline = Polyline(polylineId: polylineId, points: [latlng], width: 7, color: AppColors.blueColor, startCap: Cap.roundCap, endCap: Cap.roundCap, patterns: [PatternItem.dot, PatternItem.gap(10)]);
        }
        _polylines[polylineId] = polyline;
      }
    }
    //_controller.actualizarMarkers(markers);
    //return _controller.markers;
  }
  //embarcarpasajero-nogps
  Future<void> cambiarEstadoEmbarque(PasajeroDomicilio pasajero, String estado) async {
    int nuevoEstado = 1;
    if (estado == "0") {
      nuevoEstado = 1;
    } else {
      if (estado == "1") {
        nuevoEstado = 0;
      }
    }

    ViajeDomicilio _viajeProvider = await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].tipoDoc == pasajero.tipoDoc && _viajeProvider.pasajeros[i].numDoc == pasajero.numDoc && _viajeProvider.pasajeros[i].embarcado != nuevoEstado) {
          String fechaHoraEmb = DateFormat.yMd().add_Hms().format(new DateTime.now());

          _viajeProvider.pasajeros[i].embarcado = nuevoEstado;
          _viajeProvider.pasajeros[i].fechaEmbarque = fechaHoraEmb;
          _viajeProvider.pasajeros[i].modificado = 0;

          String rpta = await servicio.cambiarEstadoEmbarquePasajeroDomicilio(_viajeProvider.pasajeros[i], _viajeProvider.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

          switch (rpta) {
            case "0":
              _viajeProvider.pasajeros[i].modificado = 1;
              break;
            case "1":
              /* Eliminamos del provider y de la bd local */
              /*await AppDatabase.instance
                  .eliminarPasajero(_viajeProvider.pasajeros[i]);*/
              _viajeProvider.pasajeros.removeWhere((element) => element.numDoc == _viajeProvider.pasajeros[i].numDoc);
              _mostrarMensaje("El pasajero ya no se encuentra en la lista", AppColors.redColor);
              break;
            case "2":
            case "9":
              datosPorSincronizar = true;
              _viajeProvider.pasajeros[i].modificado = 0;
              break;
            default:
          }

          _modalSubioRespuesta(estado, _viajeProvider.pasajeros[i]); //Sin embarcar -> Embarcar automaticamente

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viajeProvider.pasajeros[i]);
          //_cambiarMarkerMostrado();
          setState(() {});
          break;
        }
      }
    } else {
      _mostrarMensaje('No existen pasajeros', null);
    }
  }

  AwesomeDialog _modalLlegoConductor(Parada parada) {
    String titulo = "PUNTO DE RECOJO";
    String cuerpo = "¿Ha llegado a la dirección " + parada.direccion + "?";

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
        await registrarFechaArriboUnidad(parada);
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }
  //arribo-gps
  Future<void> registrarFechaArriboUnidad(Parada parada) async {
    ViajeDomicilio _viajeProvider = await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    String fechaHoraArribo = DateFormat.yMd().add_Hms().format(new DateTime.now());
    Position posicionActualGPS = await Geolocator.getCurrentPosition();
    String posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].direccion.toUpperCase().trim() == parada.direccion.toUpperCase().trim() && _viajeProvider.pasajeros[i].distrito.toUpperCase().trim() == parada.distrito.toUpperCase().trim() && _viajeProvider.pasajeros[i].horaRecojo.toUpperCase().trim() == parada.horaRecojo.toUpperCase().trim() && _viajeProvider.pasajeros[i].embarcado == 2) {
          _viajeProvider.pasajeros[i].fechaArriboUnidad = fechaHoraArribo;
          _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;

          if (_viajeProvider.pasajeros[i].coordenadas == "" || _viajeProvider.pasajeros[i].coordenadas.trim() == "0, 0") {
            _viajeProvider.pasajeros[i].coordenadas = posicionActual;
          }

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Registra llegada unidad recojo #${_viajeProvider.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "OK");

          String rpta = await servicio.registrarFechaLlegadaUnidadDomicilio(_viajeProvider.pasajeros[i], _viajeProvider.codOperacion, _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Registra llegada unidad recojo #${_viajeProvider.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

          switch (rpta) {
            case "0":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              break;
            case "1":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              break;
            case "2":
              break;
            case "3":
            case "9":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;
              datosPorSincronizar = true;
              break;
            default:
          }

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarPasajero(_viajeProvider.pasajeros[i]);
          await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();
        }
      }
      await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();
      Log.insertarLogDomicilio(context: context, mensaje: "RECOJO: Muestra modal hora de arribo registrada", rpta: "OK");
      _mostrarModalRespuesta('REGISTRADO', 'Hora de arribo registrada', true).show();
    } else {
      Log.insertarLogDomicilio(context: context, mensaje: "RECOJO: No existen pasajeros", rpta: "OK");
      _mostrarMensaje('No existen pasajeros', null);
    }
  }

  _cambiarMarkerMostrado() async {
    Parada paradaMostrar = await Provider.of<DomicilioProvider>(context, listen: false).paradaRecojoMostrar;

    final GoogleMapController controller = await _controller.future;
    if (_initialPosition != null && (paradaMostrar.estado == 1 || paradaMostrar.estado == 2) && paradaMostrar.coordenadas != "" && _initialPositionSet) {
      controller.showMarkerInfoWindow(MarkerId(paradaMostrar.orden));

      final position = getPosition(paradaMostrar.coordenadas);
      CameraPosition cameraPosition = new CameraPosition(
        target: position,
        zoom: 18,
      );
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      _markerActual = paradaMostrar.orden;
      await Provider.of<DomicilioProvider>(context, listen: false).cambiarEstadoMostrar(false);
    } else {
      if (paradaMostrar.direccion == "" || paradaMostrar.coordenadas == "") {
        controller.hideMarkerInfoWindow(MarkerId(_markerActual));
      }
    }
  }

  _irAlProximoPunto() async {
    Parada parada = await Provider.of<DomicilioProvider>(context, listen: false).paradaRecojoMostrar;

    final GoogleMapController controller = await _controller.future;
    if (parada.coordenadas != "" && parada.orden != "" && _initialPosition != null && _initialPositionSet) {
      controller.showMarkerInfoWindow(MarkerId(parada.orden));
      _markerActual = parada.orden;
      final position = getPosition(parada.coordenadas);
      CameraPosition cameraPosition = new CameraPosition(
        target: position,
        zoom: 18,
      );
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    } else {
      if (parada.orden == "") {
        Log.insertarLogDomicilio(context: context, mensaje: "RECOJO: Ya has recogido a todos los pasajeros", rpta: "OK");
        _mostrarMensaje("Ya has recogido a todos los pasajeros", null);
      }
    }
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

  _modalSubioRespuesta(String accion, PasajeroDomicilio pasajero) {
    String cuerpo = "";
    String titulo = "";
    bool success = false;
    switch (accion) {
      case "0":
        titulo = "Embarcado";
        cuerpo = pasajero.nombres;
        success = true;
        break;
      case "1":
        titulo = "No Embarcado";
        cuerpo = pasajero.nombres;
        success = false;
        break;
    }

    return _mostrarModalSubioRespuesta(titulo, cuerpo, success).show();
  }

  AwesomeDialog _mostrarModalSubioRespuesta(String titulo, String cuerpo, bool success) {
    //_playSuccessSound();

    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, showCloseIcon: true, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 3));
  }

  getPosition(String coordendas) {
    final coords = coordendas.split(',');
    final latitud = double.parse(coords[0]);
    final longitud = double.parse(coords[1]);

    return new LatLng(latitud, longitud);
  }

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    if (success) _playSuccessSound();

    return AwesomeDialog(context: context, dialogType: success ? DialogType.success : DialogType.error, animType: AnimType.topSlide, showCloseIcon: true, title: titulo, desc: cuerpo, autoHide: Duration(seconds: 3));
  }

  _playSuccessSound() {
    player.play(AssetSource('sounds/success_sound.mp3'));
  }

  bool _esEmbarque(ViajeDomicilio _viaje) {
    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].embarcado == 2) {
        return true;
      }
    }

    return false;
  }
}
