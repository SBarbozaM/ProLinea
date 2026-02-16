import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:geolocator_platform_interface/src/enums/location_service.dart'
    as srv;
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

class ViajeDomicilioMapaPage extends StatefulWidget {
  const ViajeDomicilioMapaPage({Key? key}) : super(key: key);

  @override
  State<ViajeDomicilioMapaPage> createState() => _ViajeDomicilioMapaPageState();
}

class _ViajeDomicilioMapaPageState extends State<ViajeDomicilioMapaPage> {
  ViajeServicio servicio = new ViajeServicio();
  late Timer _timer;
  late Usuario _usuario;

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
    PermissionStatus locationPermission =
        await Permission.locationWhenInUse.request();

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
                ? GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition:
                        CameraPosition(target: LatLng(_lat, _lon), zoom: 13),
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
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: _gpsEnabled
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
            : null,
      ),
    );
  }

  getMarkers(ViajeDomicilio viaje) async {
    List<PasajeroDomicilio> pasajeros = viaje.pasajeros;

    Map<MarkerId, Marker> markers = {};
    for (int i = 0; i < pasajeros.length; i++) {
      if (pasajeros[i].coordenadas != "" &&
          pasajeros[i].coordenadas.trim() != "0, 0") {
        int width = 75, height = 75;
        Color color = AppColors.blackColor;
        /*bool puedeRegistrarLlegada = false;
        bool puedeEmbarcar = false;*/

        if (pasajeros[i].tocaRecojo && pasajeros[i].embarcado == 2) {
          if (pasajeros[i].fechaArriboUnidad == "") {
            color = AppColors.blueColor;
            //puedeRegistrarLlegada = true;
          } else {
            color = AppColors.darkTurquesa;
            //puedeEmbarcar = true;
          }
        } else if (!pasajeros[i].tocaRecojo && pasajeros[i].embarcado != 2)
          color = AppColors.greyColor;

        final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(pictureRecorder);
        final Paint paint = Paint()..color = color;

        canvas.drawOval(
            Rect.fromCircle(
                center: Offset(width * 0.5, height * 0.5),
                radius: min(width * 0.5, height * 0.5)),
            paint);
        TextPainter painter = TextPainter(textDirection: ui.TextDirection.ltr);
        painter.text = TextSpan(
            text: (i + 1).toString(),
            style: TextStyle(fontSize: 50.0, color: Colors.white));
        painter.layout();
        painter.paint(
            canvas,
            Offset((width * 0.5) - painter.width * 0.5,
                (height * 0.5) - painter.height * 0.5));

        final img = await pictureRecorder.endRecording().toImage(width, height);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);

        LatLng latlng = getPosition(pasajeros[i].coordenadas);

        final markerId = MarkerId(pasajeros[i].numDoc);
        Marker marker = new Marker(
            markerId: MarkerId(pasajeros[i].numDoc),
            position: latlng,
            anchor: Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title:
                  "[" + pasajeros[i].horaRecojo + "] " + pasajeros[i].nombres,
              snippet: pasajeros[i].direccion,
              onTap: () async {
                //await modalEmbarqueDesembarque(pasajeros[i]);
                if (pasajeros[i].embarcado == 2 &&
                    pasajeros[i].fechaArriboUnidad != "" &&
                    pasajeros[i].tocaRecojo)
                  _modalSubio(pasajeros[i], "0").show();

                if (pasajeros[i].embarcado == 2 &&
                    pasajeros[i].fechaArriboUnidad == "" &&
                    pasajeros[i].tocaRecojo)
                  _modalLlegoConductor(pasajeros[i]).show();
              },
            ),
            icon: BitmapDescriptor.fromBytes(data!.buffer.asUint8List()));
        markers[markerId] = marker;
      }
    }
    _markers = markers;

    bool actualizarMapa =
        await Provider.of<DomicilioProvider>(context, listen: false)
            .actualizarMapa;

    if (actualizarMapa) {
      setState(() async {
        await Provider.of<DomicilioProvider>(context, listen: false)
            .cambiarEstadoActualizarMapa(false);
      });
    }

    //_controller.actualizarMarkers(markers);
    //return _controller.markers;
  }

  getPolylines(ViajeDomicilio viaje) async {
    List<PasajeroDomicilio> pasajeros = viaje.pasajeros;

    PolylineId polylineId = PolylineId("ruta");

    _polylines = {};

    for (int i = 0; i < pasajeros.length; i++) {
      if (pasajeros[i].coordenadas != "" &&
          pasajeros[i].coordenadas.trim() != "0, 0") {
        LatLng latlng = getPosition(pasajeros[i].coordenadas);

        Polyline polyline;
        if (_polylines.containsKey(polylineId)) {
          final temp = _polylines[polylineId];
          polyline = temp!.copyWith(pointsParam: [...temp.points, latlng]);
        } else {
          polyline = Polyline(
              polylineId: polylineId,
              points: [latlng],
              width: 7,
              color: AppColors.blueColor,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              patterns: [PatternItem.dot, PatternItem.gap(10)]);
        }
        _polylines[polylineId] = polyline;
      }
    }
    //_controller.actualizarMarkers(markers);
    //return _controller.markers;
  }

  Future<void> cambiarEstadoEmbarque(
      PasajeroDomicilio pasajero, String estado) async {
    int nuevoEstado = 1;
    if (estado == "0") {
      nuevoEstado = 1;
    } else {
      if (estado == "1") {
        nuevoEstado = 0;
      }
    }

    ViajeDomicilio _viajeProvider =
        await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].tipoDoc == pasajero.tipoDoc &&
            _viajeProvider.pasajeros[i].numDoc == pasajero.numDoc &&
            _viajeProvider.pasajeros[i].embarcado != nuevoEstado) {
          String fechaHoraEmb =
              DateFormat.yMd().add_Hms().format(new DateTime.now());

          _viajeProvider.pasajeros[i].embarcado = nuevoEstado;
          _viajeProvider.pasajeros[i].fechaEmbarque = fechaHoraEmb;
          _viajeProvider.pasajeros[i].modificado = 0;

          String rpta = await servicio.cambiarEstadoEmbarquePasajeroDomicilio(
              _viajeProvider.pasajeros[i],
              _viajeProvider.codOperacion,
              _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

          switch (rpta) {
            case "0":
              _viajeProvider.pasajeros[i].modificado = 1;
              break;
            case "1":
              /* Eliminamos del provider y de la bd local */
              /*await AppDatabase.instance
                  .eliminarPasajero(_viajeProvider.pasajeros[i]);*/
              _viajeProvider.pasajeros.removeWhere((element) =>
                  element.numDoc == _viajeProvider.pasajeros[i].numDoc);
              _mostrarMensaje("El pasajero ya no se encuentra en la lista",
                  AppColors.redColor);
              break;
            case "2":
            case "9":
              datosPorSincronizar = true;
              _viajeProvider.pasajeros[i].modificado = 0;
              break;
            default:
          }

          _modalSubioRespuesta(
              estado,
              _viajeProvider
                  .pasajeros[i]); //Sin embarcar -> Embarcar automaticamente

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false)
              .actualizarPasajero(_viajeProvider.pasajeros[i]);
          await Provider.of<DomicilioProvider>(context, listen: false)
              .actualizarMarkerMostrar();
          //_cambiarMarkerMostrado();
          setState(() {});
          break;
        }
      }
    } else {
      _mostrarMensaje('No existen pasajeros', null);
    }
  }

  AwesomeDialog _modalSubio(PasajeroDomicilio pasajero, String estado) {
    String titulo = "¿SUBIÓ?";
    String cuerpo = pasajero.nombres;

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
        await cambiarEstadoEmbarque(pasajero, "0");
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () async {
        await cambiarEstadoEmbarque(pasajero, "1");
      },
    );
  }

  AwesomeDialog _modalLlegoConductor(PasajeroDomicilio pasajero) {
    String titulo = "PUNTO DE RECOJO";
    String cuerpo =
        "¿Ha llegado al punto de recojo del pasajero " + pasajero.nombres + "?";

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
        if (pasajero.embarcado == 2 && pasajero.fechaArriboUnidad == "")
          await registrarFechaArriboUnidad(pasajero);
      },
      btnCancelText: "No",
      btnCancelColor: AppColors.redColor,
      btnCancelOnPress: () {},
    );
  }

  Future<void> registrarFechaArriboUnidad(PasajeroDomicilio pasajero) async {
    ViajeDomicilio _viajeProvider =
        await Provider.of<DomicilioProvider>(context, listen: false).viaje;

    if (_viajeProvider.pasajeros.isNotEmpty) {
      PasajeroServicio servicio = new PasajeroServicio();
      for (int i = 0; i < _viajeProvider.pasajeros.length; i++) {
        if (_viajeProvider.pasajeros[i].tipoDoc == pasajero.tipoDoc &&
            _viajeProvider.pasajeros[i].numDoc == pasajero.numDoc &&
            _viajeProvider.pasajeros[i].embarcado == 2 &&
            _viajeProvider.pasajeros[i].fechaArriboUnidad == "") {
          String fechaHoraArribo =
              DateFormat.yMd().add_Hms().format(new DateTime.now());

          _viajeProvider.pasajeros[i].fechaArriboUnidad = fechaHoraArribo;
          _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;

          setState(() {});
          String rpta = await servicio.registrarFechaLlegadaUnidadDomicilio(
              _viajeProvider.pasajeros[i],
              _viajeProvider.codOperacion,
              _usuario.tipoDoc.trim() + _usuario.numDoc.trim());

          switch (rpta) {
            case "0":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              _mostrarModalLlegadaRegistrada(
                      'REGISTRADO', 'Hora de arribo registrada', true)
                  .show();

              break;
            case "1":
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 1;
              _mostrarModalLlegadaRegistrada(
                      'ERROR', 'Ya existe una hora de arribo registrada', false)
                  .show();
              break;
            case "2":
              break;
            case "3":
            case "9":
              _mostrarModalLlegadaRegistrada(
                      'REGISTRADO', 'Hora de arribo registrada', true)
                  .show();
              _viajeProvider.pasajeros[i].modificadoFechaArribo = 0;
              datosPorSincronizar = true;
              break;
            default:
          }

          //Actualizamos la variable provider de viaje
          await Provider.of<DomicilioProvider>(context, listen: false)
              .actualizarPasajero(_viajeProvider.pasajeros[i]);
          await Provider.of<DomicilioProvider>(context, listen: false)
              .actualizarMarkerMostrar();
          //_cambiarMarkerMostrado();
          setState(() {});
          break;
        }
      }
    } else {
      _mostrarMensaje('No existen pasajeros', null);
    }
  }

  _cambiarMarkerMostrado() async {
    PasajeroDomicilio pasajeroMostrar =
        await Provider.of<DomicilioProvider>(context, listen: false)
            .pasajeroMostrar;

    final GoogleMapController controller = await _controller.future;
    if (_initialPosition != null &&
        pasajeroMostrar.mostrarMarker &&
        _initialPositionSet) {
      controller.showMarkerInfoWindow(MarkerId(pasajeroMostrar.numDoc));

      final position = getPosition(pasajeroMostrar.coordenadas);
      CameraPosition cameraPosition = new CameraPosition(
        target: position,
        zoom: 18,
      );
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      _markerActual = pasajeroMostrar.numDoc;
      await Provider.of<DomicilioProvider>(context, listen: false)
          .cambiarEstadoMostrar(false);
    } else {
      if (pasajeroMostrar.numDoc == "" || pasajeroMostrar.tipoDoc == "") {
        controller.hideMarkerInfoWindow(MarkerId(_markerActual));
      }
    }
  }

  _irAlProximoPunto() async {
    PasajeroDomicilio pasajeroMostrar =
        await Provider.of<DomicilioProvider>(context, listen: false)
            .pasajeroMostrar;

    final GoogleMapController controller = await _controller.future;
    if (pasajeroMostrar.numDoc != "" &&
        _initialPosition != null &&
        _initialPositionSet) {
      controller.showMarkerInfoWindow(MarkerId(pasajeroMostrar.numDoc));
      _markerActual = pasajeroMostrar.numDoc;
      final position = getPosition(pasajeroMostrar.coordenadas);
      CameraPosition cameraPosition = new CameraPosition(
        target: position,
        zoom: 18,
      );
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    } else {
      if (pasajeroMostrar.numDoc == "") {
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

  AwesomeDialog _mostrarModalSubioRespuesta(
      String titulo, String cuerpo, bool success) {
    //_playSuccessSound();

    return AwesomeDialog(
        context: context,
        dialogType: success ? DialogType.success : DialogType.error,
        animType: AnimType.topSlide,
        showCloseIcon: true,
        title: titulo,
        desc: cuerpo,
        autoHide: Duration(seconds: 3));
  }

  getPosition(String coordendas) {
    final coords = coordendas.split(',');
    final latitud = double.parse(coords[0]);
    final longitud = double.parse(coords[1]);

    return new LatLng(latitud, longitud);
  }

  AwesomeDialog _mostrarModalLlegadaRegistrada(
      String titulo, String cuerpo, bool success) {
    //_playSuccessSound();

    return AwesomeDialog(
        context: context,
        dialogType: success ? DialogType.success : DialogType.error,
        animType: AnimType.topSlide,
        showCloseIcon: true,
        title: titulo,
        desc: cuerpo,
        autoHide: Duration(seconds: 3));
  }
}
