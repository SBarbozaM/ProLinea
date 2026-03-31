import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/subAuth_model.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/services/list_sub_acciones_service.dart';

import 'package:flutter/material.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';

import 'package:provider/provider.dart';
import '../../providers/connection_status_provider.dart';
import '../../providers/providers.dart';

enum statusListaSubAccionesAuth { initial, success, failure, progress }

class SubAutorizacionesPage extends StatefulWidget {
  final AccionId? AccionPadre;
  const SubAutorizacionesPage({super.key, this.AccionPadre});

  @override
  State<SubAutorizacionesPage> createState() => _SubAutorizacionesPageState();
}

class _SubAutorizacionesPageState extends State<SubAutorizacionesPage> {
  //late AuthUsuarioServicio _authUsuarioServicio;
  statusListaSubAccionesAuth status = statusListaSubAccionesAuth.initial;
  late Usuario _usuario;
  SubAuthUsuarioModel subAutLisModel = SubAuthUsuarioModel(
    rpta: "",
    mensaje: "",
    tipoDoc: "",
    numDoc: "",
    idAuth: 0,
    authSubAcciones: [],
  );

  @override
  void initState() {
    super.initState();

    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final authIdModel = Provider.of<AuthIdModel>(context, listen: false);

    _obtenerListAuths(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, authIdModel.authId, widget.AccionPadre!.id);
  }

  _obtenerListAuths(String tipoDoc, String numDoc, String idAhut, int? idAccionPadre) async {
    SubAutorizacionesServicio sListSubAuthUsuario = SubAutorizacionesServicio();

    setState(() {
      status = statusListaSubAccionesAuth.progress;
    });
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    final accionesFiltradas = idAccionPadre != null ? _usuario.accionesId.where((accion) => accion.accionPredecesora == idAccionPadre).toList() : _usuario.accionesId;
    subAutLisModel.authSubAcciones = accionesFiltradas;

    // subAutLisModel = await sListSubAuthUsuario.listarsubAuthsUsuario(tipoDoc, numDoc, idAhut);
    if (subAutLisModel.authSubAcciones.isEmpty) {
      setState(() {
        status = statusListaSubAccionesAuth.failure;
      });
      return;
    }

    setState(() {
      status = statusListaSubAccionesAuth.success;
    });
    // if (subAutLisModel.rpta != "0") {
    //   setState(() {
    //     status = statusListaSubAccionesAuth.failure;
    //   });
    //   return;
    // }

    // if (subAutLisModel.rpta == "0") {
    //   setState(() {
    //     status = statusListaSubAccionesAuth.success;
    //   });
    //   return;
    // }
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  final List<String> imagePaths = [
    'assets/images/Icon_pendiente.png',
    'assets/images/Icono_aprobado.png',
    'assets/images/Icon_rechazados.png',
    'assets/images/Icono_registrados.png',
    'assets/images/Iconos_Dar_Auth.png',
    'assets/images/Iconos_Dar_Auth.png',
    'assets/images/Iconos_Dar_Auth.png',
    // Agrega más rutas de imágenes según sea necesario
  ];

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final authIdModel = Provider.of<AuthIdModel>(context, listen: false);
    //  final authUsuarioProvider = Provider.of<AuthUsuarioProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text('${widget.AccionPadre!.accion}'),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (status == statusListaSubAccionesAuth.progress) {
            return Container(
              padding: const EdgeInsets.only(top: 10),
              alignment: Alignment.topCenter,
              child: const CircularProgressIndicator(
                color: AppColors.mainBlueColor,
              ),
            );
          }

          if (status == statusListaSubAccionesAuth.success) {
            return RefreshIndicator(
              onRefresh: () => _obtenerListAuths(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, authIdModel.authId, widget.AccionPadre!.id),
              color: AppColors.mainBlueColor,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: subAutLisModel.authSubAcciones.length,
                  itemBuilder: (context, index) {
                    final subAuthAccion = subAutLisModel.authSubAcciones[index];
                    final imagePath = imagePaths[index % imagePaths.length];
                    return Card(
                      child: ListTile(
                        leading: Image.asset(
                          subAuthAccion.icono?.isNotEmpty == true ? 'assets/images/${subAuthAccion.icono}.png' : 'assets/images/default_icon.png',
                          height: 35, // Ajusta el tamaño de la imagen según sea necesario
                        ),
                        title: Text(subAuthAccion.accion),
                        trailing: const Icon(Icons.arrow_forward_ios_outlined, color: AppColors.mainBlueColor),
                        onTap: () {
                          final subauthIdModel = Provider.of<SubAuthIdModel>(context, listen: false);
                          final subAuthAction = SubAuthActionModel(subAuthAccion.id.toString(), subAuthAccion.accion, subAuthAccion.orden);
                          subauthIdModel.updateAuthAction(subAuthAction);
                          Navigator.of(context).pushNamed(
                            'irListaDocsAuth',
                          );
                        },
                      ),
                    );
                  },
                  //  separatorBuilder: (context, index) => const Divider(),
                ),
              ),
            );
          }

          if (status == statusListaSubAccionesAuth.failure) {
            return RefreshIndicator(
              onRefresh: () => _obtenerListAuths(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, authIdModel.authId, widget.AccionPadre!.id),
              color: AppColors.mainBlueColor,
              child: ListView(
                children: [
                  if (!_hayConexion())
                    Container(
                      padding: EdgeInsets.all(16.0),
                      color: Colors.yellow[100], // Color de fondo amarillo claro
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange), // Icono de advertencia
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Revisa tu conexión a internet", // Mensaje de error
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_hayConexion())
                    Container(
                      padding: EdgeInsets.all(16.0), // Asegúrate de tener algo de padding para un mejor UX
                      child: Text(subAutLisModel.mensaje),
                    ),
                ],
              ),
            );
          }

          return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
        },
        child: Icon(Icons.home),
        backgroundColor: AppColors.mainBlueColor,
        tooltip: 'Regresar a Inicio',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
