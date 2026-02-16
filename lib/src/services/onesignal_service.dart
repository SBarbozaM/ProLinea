import 'package:embarques_tdp/src/components/webview_basica.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

import 'package:embarques_tdp/src/models/acciones_usuario.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';

class OneSignalService {
  void init(GlobalKey<NavigatorState> navigatorKey) {
    // OneSignal.shared.setAppId("53f63abd-f50c-4a54-95d3-dd149cbfd9f7");
    OneSignal.initialize("53f63abd-f50c-4a54-95d3-dd149cbfd9f7");

    // Solicita permisos de notificación al usuario
    // OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    //   print("Permiso de notificación aceptado: $accepted");
    // });
    OneSignal.Notifications.requestPermission(true);

    // OneSignal.shared.setNotificationWillShowInForegroundHandler((notification) {
    //   print('Notification received in foreground: ${notification.jsonRepresentation()}');
    //   notification.complete(notification.notification); // Muestra la notificación
    // });
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('Notification received in foreground: ${event.notification.jsonRepresentation()}');

      // Para mostrar la notificación tal cual:
      event.notification.display();

      // O, si quieres evitar que se muestre automáticamente y manejarlo tú mismo:
      // event.preventDefault();
      // ... tu lógica aquí ...
      // Luego, cuando quieras mostrarla:
      // event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) async {
      Map<String, dynamic> additionalData = event.notification.additionalData ?? {};
      
      // Map<String, dynamic> additionalData = result.notification.additionalData ?? {};

      //print('Notification opened: ${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}');

      String? page = additionalData['page'];
      bool hasActiveSession = await _checkActiveSession(navigatorKey.currentState?.overlay?.context);

      String? idsubauth = additionalData['idsubauth'];
      String? titulo = additionalData['titulo'];
      String? orden = additionalData['orden'];
      String? idauth = additionalData['idauth'];
      String? stitle = additionalData['stitle'];
      String? launchUrl = additionalData['app_url']; //result.notification.launchUrl;
      String? tituloWeb = additionalData['titulo_web']; //result.notification.launchUrl;

      final context = navigatorKey.currentState?.overlay?.context;

      if (hasActiveSession && context != null) {
        if (launchUrl != null && launchUrl.isNotEmpty) {
          // Si `launchUrl` está presente, abre la página `WebViewPage`
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WebViewBasicaPage(
                      url: launchUrl,
                      titulo: tituloWeb ?? "",
                      back: "inicio",
                    )),
          );
        } else if (page != null && page.isNotEmpty) {
          // Si no hay `launchUrl`, navega a la página interna
          final authIdModel = Provider.of<AuthIdModel>(context, listen: false);
          authIdModel.updateAuthData(idauth!, stitle!);

          final subauthIdModel = Provider.of<SubAuthIdModel>(context, listen: false);
          final subAuthAction = SubAuthActionModel(idsubauth!, titulo!, orden!);
          subauthIdModel.updateAuthAction(subAuthAction);

          Provider.of<NotificationProvider>(context, listen: false).setNotificationPage(page);

          navigatorKey.currentState?.pushNamedAndRemoveUntil(page, (Route<dynamic> route) => false);
        }
      } else {
        // Si no hay sesión activa, navega a la página de inicio de sesión
        navigatorKey.currentState?.pushNamedAndRemoveUntil('login', (Route<dynamic> route) => false);
      }
    });
  }

  Future<bool> _checkActiveSession(BuildContext? context) async {
    if (context == null) return false;

    List<Usuario> listausuario = await AppDatabase.instance.ObtenerUsuarioSesionActiva();

    if (listausuario.isNotEmpty) {
      Usuario usuarioAuth = listausuario[0];
      List<Map<String, Object?>> accioneslist = await AppDatabase.instance.Listar(tabla: "accionesUsuario");
      List<AccionesUsuario> _accionesUsuario = accioneslist.map((e) => AccionesUsuario.fromJson(e)).toList();
      List<String> accions = _accionesUsuario.map((acc) => acc.accion).toList();

      usuarioAuth.acciones = accions;

      await Provider.of<UsuarioProvider>(context, listen: false).usuarioActual(usuario: usuarioAuth);
      await Provider.of<UsuarioProvider>(context, listen: false).emparejar(
        listausuario[0].viajeEmp,
        listausuario[0].unidadEmp,
        listausuario[0].placaEmp,
        listausuario[0].fechaEmp,
        "${listausuario[0].vinculacionActiva}",
      );

      return true;
    } else {
      return false;
    }
  }
}
