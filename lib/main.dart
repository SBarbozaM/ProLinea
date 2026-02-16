import 'package:embarques_tdp/app.dart';
import 'package:embarques_tdp/src/Bloc/unidadScaner/embarques_sup_scaner_bloc.dart';
import 'package:embarques_tdp/src/Bloc/vincularInicio/vincular_inicio_bloc.dart';
import 'package:embarques_tdp/src/components/conexionInternet.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/pages/jornada/bloc/jornada/jornada_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/ayudante/ayudante_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/conductor1/conductor1_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/conductor2/conductor2_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/conductor3/conductor3_bloc.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/Bloc/unidad/unidad_bloc.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/controlador_provider.dart';
import 'package:embarques_tdp/src/providers/impresoraProvider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/checklist_mantenimiento_servico.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/services/google_services.dart';

// ...

final internetChecker = VerificarConexionInternet();
bool datosPorSincronizar = false;
bool _requireConsent = true;
//bool sincronizar = true;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GSS.instance.initialize();

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("53f63abd-f50c-4a54-95d3-dd149cbfd9f7");
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // OneSignal.shared.setNotificationWillShowInForegroundHandler((notification) {
  //   print('Notification received in foreground: ${notification.jsonRepresentation()}');
  //   notification.complete(notification.notification); // Muestra la notificación
  // });

  // OneSignal.shared.setNotificationOpenedHandler((opened) {
  //   print('Notification opened: ${opened.notification.jsonRepresentation()}');
  //   handleNotificationOpened(opened.notification);
  // });

  // OneSignal.shared.setNotificationWillShowInForegroundHandler((notification) {
  //   print('Notification received in foreground: ${notification.jsonRepresentation()}');
  //   notification.complete(notification.notification); // Muestra la notificación
  // });

  // OneSignal.shared.setNotificationOpenedHandler((opened) {
  //   print('Notification opened: ${opened.notification.jsonRepresentation()}');
  // });

  // OneSignal.shared.setNotificationOpenedHandler((opened) {
  //   print('Notification opened: ${opened.notification.jsonRepresentation()}');
  // });

  //await OneSignal.shared.setExternalUserId('DNI-00000000'); //.User.getOnesignalId();

  // String externalUserId = "DNI-00000000";

  //await OneSignal.User.getExternalId(externalUserId);
  //shared.setExternalUserId(externalUserId);

  // OneSignal.Notifications.addClickListener ((event) {
  //   print('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');

  //   print("Clicked notificavdvvtion: \n${event.result.jsonRepresentation()}");
  //   "Clicked notification: \n${event.result.jsonRepresentation()}";
  //   print("OneSignal Player ID: $playerId");
  // });

  //   OneSignalNotifications .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
  //   var link = result.notification.additionalData?['link'];
  //   if (link != null) {
  //     _handleLink(link);
  //   }
  // });

  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionStatusProvider()),
          ChangeNotifierProvider(create: (_) => TipoDocumentoProvider()),
          ChangeNotifierProvider(create: (_) => UsuarioProvider()),
          ChangeNotifierProvider(create: (_) => ViajeProvider()),
          ChangeNotifierProvider(create: (_) => PasajeroHabilitadoProvider()),
          ChangeNotifierProvider(create: (_) => PasajeroProvider()),
          ChangeNotifierProvider(create: (_) => PrereservaProvider()),
          ChangeNotifierProvider(create: (_) => RutasProvider()),
          ChangeNotifierProvider(create: (_) => DomicilioProvider()),
          // ChangeNotifierProvider(create: (_) => ImpresoraProvider()),
          /* NUEVO 05/05/23 */
          ChangeNotifierProvider(create: (_) => PuntoEmbarqueProvider()),
          /* NUEVO 05/05/23 */

          ChangeNotifierProvider(create: (_) => ControladorProvider()),

          /* NUEVO 21/06/24   Autorizaciones*/
          ChangeNotifierProvider(create: (_) => AuthIdModel()),
          ChangeNotifierProvider(create: (_) => SubAuthIdModel()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider(
              create: (context) => EmbarquesSupScanerServicio(),
            ),
            RepositoryProvider(
              create: (context) => ChecklistServicio(),
            ),
            RepositoryProvider(
              create: (context) => AppDatabase(),
            )
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => EmbarquesSupScanerBloc(
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => VincularInicioBloc(
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => UnidadBloc(
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => Conductor1Bloc(
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => Conductor2Bloc(
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => JornadaBloc(
                  appDatabase: RepositoryProvider.of<AppDatabase>(context),
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => Conductor3Bloc(
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => AyudanteBloc(
                  embarquesSupScanerServicio: RepositoryProvider.of<EmbarquesSupScanerServicio>(context),
                ),
              ),
              BlocProvider(
                create: (context) => ChecklistBloc(
                  sChecklist: RepositoryProvider.of<ChecklistServicio>(context),
                ),
              ),
            ],
            child: MyApp(),
          ),
        )),
  );
}

// void handleNotificationOpened(OSNotification notification) {
//   var data = notification.additionalData;
//   if (data != null) {
//     var link = data['link'];
//     if (link != null) {
//       navigatorKey.currentState?.pushNamed(link);
//     }
//   }
// }



///kfrijfr