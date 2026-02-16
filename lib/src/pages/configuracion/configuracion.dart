import 'package:embarques_tdp/src/components/configuracion_tile.dart';
import 'package:embarques_tdp/src/components/drawer.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../../utils/app_colors.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({Key? key}) : super(key: key);
  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  bool _mostrarCarga = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ingreso();
  }

  ingreso() async {
    var usuarioLogin =
        Provider.of<UsuarioProvider>(context, listen: false).usuario;
    await AppDatabase.instance.NuevoRegistroBitacora(
      context,
      "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
      "${usuarioLogin.codOperacion}",
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "Embarque ${usuarioLogin.perfil}: INGRESO A CONFIGURAR",
      "Exitoso",
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración'),
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  'inicio', (Route<dynamic> route) => false);
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
            ),
          ),
        ),
        body: ModalProgressHUD(
          opacity: 0.0,
          color: AppColors.whiteColor,
          progressIndicator: const CircularProgressIndicator(
            color: AppColors.mainBlueColor,
          ),
          inAsyncCall: _mostrarCarga,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  SettingsTile(
                    color: AppColors.amberColor,
                    icon: Icons.print,
                    title: "Impresora",
                    onTap: () {
                      Navigator.pushNamed(context, 'configImpresora');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
