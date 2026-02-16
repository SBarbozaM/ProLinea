import 'package:embarques_tdp/src/models/acciones_usuario.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:embarques_tdp/src/services/onesignal_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    validarSesion();

    super.initState();
  }

  validarSesion() async {
    Usuario usuarioAuth;
    List<String> accions = [];

    List<Usuario> listausuario = await AppDatabase.instance.ObtenerUsuarioSesionActiva();

    if (listausuario.length > 0) {
      usuarioAuth = listausuario[0];

      List<Map<String, Object?>> accioneslist = await AppDatabase.instance.Listar(tabla: "accionesUsuario");

      List<AccionesUsuario> _accionesUsuario = accioneslist.map((e) => AccionesUsuario.fromJson(e)).toList();
      for (var acc in _accionesUsuario) {
        accions.add(acc.accion);
      }
      usuarioAuth.acciones = accions;

      await Provider.of<UsuarioProvider>(context, listen: false).usuarioActual(usuario: usuarioAuth);
      await Provider.of<UsuarioProvider>(context, listen: false).emparejar(
        listausuario[0].viajeEmp,
        listausuario[0].unidadEmp,
        listausuario[0].placaEmp,
        listausuario[0].fechaEmp,
        "${listausuario[0].vinculacionActiva}",
      );
      await Future.delayed(Duration(seconds: 1));
      // Navigator.of(context).pushReplacementNamed('inicio');

      // Verifica si la aplicación se abrió desde una notificación
      final notificationPage = Provider.of<NotificationProvider>(context, listen: false).notificationPage;

      if (notificationPage != null && notificationPage.isNotEmpty) {
        Navigator.of(context).pushReplacementNamed(notificationPage);
      } else {
        Navigator.of(context).pushReplacementNamed('inicio');
      }
    } else {
      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).pushReplacementNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.mainBlueColor,
        ),
      ),
    );
  }
}
