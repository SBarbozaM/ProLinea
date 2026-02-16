import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GeoManager {
  static final GeoManager _instance = GeoManager._internal();
  factory GeoManager() => _instance;
  GeoManager._internal();

  StreamSubscription<Position>? _subscription;
  Position? _ultimaPosicion;

  /// Inicia la escucha de ubicación y actualiza la posición local.
  Future<void> iniciar({
    required Function(Position pos) onActualizar,
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 2,
  }) async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return; // no hay permisos
      }
    }

    _subscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter, // cada X metros
      ),
    ).listen((pos) {
      _ultimaPosicion = pos;
      onActualizar(pos);
    });

    // Si quieres obtener una posición inicial rápida:
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        _ultimaPosicion = pos;
        onActualizar(pos);
      }
    } catch (_) {}
  }

  /// Devuelve la última posición válida conocida.
  Position? get posicionActual => _ultimaPosicion;

  /// Detiene la escucha del GPS.
  Future<void> detener() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
