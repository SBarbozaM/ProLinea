import 'dart:io';

import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/usuario.dart';
import '../utils/app_data.dart';

import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../providers/connection_status_provider.dart';

import 'package:unique_identifier/unique_identifier.dart';

class GoogleServices {
  static Future<void> setEvent({required String nombreEvento, Usuario? usuario, String dataAdicional = ''}) async {
    String deviceId = await _getUniqueIdentifier();
    //Solo si está apuntando a producción
    if (Conexion.mood) {
      try {
        // Obtén la instancia de GSS e inicializa la analítica si es necesario
        var s1 = GSS.instance;
        if (s1.serviceAnalytics == null) {
          await s1.initialize(); // Asegura la inicialización de FirebaseAnalytics
        }

        String coordenadas = await _getCoordenadas();
        // Obtener la IP local
        String ipAddress = await _getLocalIpAddress();
        String idUsuario = '';
        String operacion = '';
        if (usuario != null) {
          idUsuario = usuario.tipoDoc + usuario.numDoc.trim();
          operacion = '${usuario.codOperacion.trim()} - ${usuario.nombreOperacion.trim()}';
        }
        var analytics = s1.serviceAnalytics;

        await analytics?.logEvent(
          name: nombreEvento,
          parameters: {'usuario': idUsuario, 'operacion': operacion, 'cuando': DateTime.now().toString(), 'coordenadas': coordenadas, 'ip_address': ipAddress, 'app_version': AppData.appVersion, 'device_id': deviceId, 'otros': dataAdicional},
        );
      } catch (e) {
        if (kDebugMode) {
          print("Error logging event: $e");
        }
      }
    }
  }

  static Future<String> _getUniqueIdentifier() async {
    String? deviceId;

    try {
      deviceId = await UniqueIdentifier.serial;
    } on PlatformException {
      deviceId = null;
    }

    return deviceId ?? "";
  }

  static Future<String> _getLocalIpAddress() async {
    try {
      // Obtén todas las interfaces de red disponibles
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            return addr.address; // Devuelve la primera dirección IPv4 encontrada
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error obtaining IP address: $e");
      }
    }
    return '';
  }

  static Future<String> _getCoordenadas() async {
    String posicionActual = '';
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!isLocationServiceEnabled || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return 'Sin permiso de ubicación';
      }
    }

    try {
      Position posicionActualGPS = await Geolocator.getCurrentPosition();
      posicionActual = "${posicionActualGPS.latitude},${posicionActualGPS.longitude}";
    } catch (e) {
      if (kDebugMode) {
        print("Error obtaining coordinates: $e");
      }
    }
    return posicionActual;
  }
}

class GSS {
  // Singleton
  static final GSS _singleton = GSS._internal();
  factory GSS() => _singleton;
  GSS._internal();

  static GSS get instance => _singleton;

  // FirebaseAnalytics
  FirebaseAnalytics? serviceAnalytics;
  late DateTime timeSession;

  // Inicialización de FirebaseAnalytics y tiempo de sesión
  Future<void> initialize() async {
    serviceAnalytics = FirebaseAnalytics.instance;
    timeSession = DateTime.now();
  }
}
