import 'dart:async';

import 'package:embarques_tdp/main.dart';
import 'package:embarques_tdp/src/models/jornada.dart';
import 'package:embarques_tdp/src/models/usuario.dart';

import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/routes/rutas.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:embarques_tdp/src/services/onesignal_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:intl/intl.dart';
// import 'package:platform_device_id/platform_device_id.dart';
import 'package:provider/provider.dart';
import 'package:unique_identifier/unique_identifier.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final OneSignalService oneSignalService = OneSignalService();
  String _debugLabelString = "";
  Future<void> getUniqueIdentifier() async {
    String? deviceId;

    try {
      deviceId = await UniqueIdentifier.serial;
    } on PlatformException {
      deviceId = null;
    }

    if (deviceId != null) {
      Provider.of<UsuarioProvider>(context, listen: false).asignarIdDispositivo(deviceId);
    }
  }

  late Timer _timer;
  late Timer _timer2 = Timer(Duration.zero, () {});

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    getUniqueIdentifier();
    periodic();

    _timer = new Timer.periodic(Duration(minutes: 20), (timer) {
      if (!_timer2.isActive) {
        _timer2 = new Timer.periodic(Duration(minutes: 20), (timer2) {
          if (_hayConexion()) {
            print(_timer2.tick);

            if (_timer2.tick == 1) {
              LogSincronizar();
            }
          } else {
            _timer2.cancel();
          }

          setState(() {});
        });
      }

      //actualizar los datos del viaje cada 10 segundos
    });

    super.initState();
    oneSignalService.init(navigatorKey);
    // checkForUpdate();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    _timer2.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  void checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      setState(() {
        if (info.updateAvailability != UpdateAvailability.updateAvailable) {
          update();
        }
      });
    });
  }

  void update() async {
    await InAppUpdate.startFlexibleUpdate();
    InAppUpdate.completeFlexibleUpdate().then((_) {}).catchError((e) {
      print(e.toString());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appLifecycleState) {
    super.didChangeAppLifecycleState(appLifecycleState);

    /// STATES : active , inactive , paused , unknown , detached

    if (appLifecycleState == AppLifecycleState.resumed) {
      print("Aplicacion resumed");
    }
    if (appLifecycleState == AppLifecycleState.inactive) {
      print("Aplicacion inactive");
    }
    if (appLifecycleState == AppLifecycleState.paused) {
      print("Aplicacion paused");
    }
    if (appLifecycleState == AppLifecycleState.detached) {
      print("Aplicacion detached");
    }
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  periodic() async {
    await Future.delayed(Duration(milliseconds: 50));
    IniciaSincronizacion();
    Timer.periodic(const Duration(minutes: 5), (timer) {
      IniciaSincronizacion();
    });
  }

  IniciaSincronizacion() async {
    if (_hayConexion()) {
      SincronizarJornadasBD();
    }
  }

  LogSincronizar() async {
    List<Usuario> listausuario = await AppDatabase.instance.ObtenerUsuarioLogSincronizar();

    if (listausuario.isNotEmpty) {
      await Log().initLogApp(context, listausuario[0]);
    }
  }

  SincronizarJornadasBD() async {
    EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();
    List<Jornada> ListaPendiente = [];

    AppDatabase _appDatabase = AppDatabase();
    List<Jornada> listJornadas = await _appDatabase.ListarJornadas();

    for (var jornada in listJornadas) {
      if (jornada.estadobdfin == "1" || jornada.estadobdinicio == "1") {
        ListaPendiente.add(jornada);
      }
    }

    for (var pendiente in ListaPendiente) {
      String fechaInicioBD = "";
      String fechaFinBD = "";
      if (pendiente.decoInicio.trim().length > 0) {
        final fechaInicio = DateTime.parse(pendiente.decoInicio);
        fechaInicioBD = DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaInicio);
      }

      if (pendiente.decoInicio.trim().length > 0) {
        final fechaFin = DateTime.parse(pendiente.decoFin);
        fechaFinBD = DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaFin);
      }
      print("actualizar");
      Response? resp = await _embarquesSupScanerServicio.RegistarTurno(
        pendiente.viajNroViaje,
        pendiente.dehoTurno,
        pendiente.viajDni,
        fechaInicioBD,
        fechaFinBD,
        pendiente.dehoCordenadasInicio,
        pendiente.dehoCordenadasFin,
      );

      if (resp != null && resp.body.split(",")[0] == "0") {
        await _appDatabase.UpdateJornada(
          {
            "EstadoBDInicio": "0", // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
            "EstadoBDFin": "0", // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
          },
          "ID=${pendiente.id}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [const Locale('en'), const Locale('es')],
      debugShowCheckedModeBanner: false,
      title: 'ProLinea',
      theme: ThemeData(
        useMaterial3: false,
      ),
      initialRoute: '/',
      routes: obtenerRutas(),
    );
  }
}
