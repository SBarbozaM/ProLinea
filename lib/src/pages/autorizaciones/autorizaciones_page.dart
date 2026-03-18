import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/pages/autorizaciones/sub_subAcciones_auth_page.dart';

import 'package:flutter/material.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../providers/connection_status_provider.dart';

enum StatusListaAuthUsuarios { initial, success, failure, progress }

class AutorizacionesPage extends StatefulWidget {
  final AccionId? AccionPadre;
  const AutorizacionesPage({super.key, this.AccionPadre});

  @override
  State<AutorizacionesPage> createState() => _AutorizacionesPageState();
}

class _AutorizacionesPageState extends State<AutorizacionesPage> {
  StatusListaAuthUsuarios status = StatusListaAuthUsuarios.initial;
  late Usuario _usuario;
  AuthUsuario autLisModel = AuthUsuario(
    rpta: "",
    mensaje: "",
    tipoDoc: "",
    numDoc: "",
    authAcciones: [],
  );

  @override
  void initState() {
    super.initState();
    // widget.idAccionPadre siempre disponible aquí
    _obtenerListAuths(
      Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc,
      Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc,
      widget.AccionPadre!.id, // 👈 directo, sin args, sin perder nada
    );
  }

  final List<String> imagePaths = [
    'assets/images/Icon_gastos.png',
    'assets/images/Icono_cortesia.png',
    'assets/images/Icon_salario.png',
    'assets/images/Icon_valecaja.png',
    'assets/images/Iconos_Dar_Auth.png',
    'assets/images/Iconos_Dar_Auth.png',
    'assets/images/Iconos_Dar_Auth.png',
    // Agrega más rutas de imágenes según sea necesario
  ];

  _obtenerListAuths(String tipoDoc, String numDoc, int? idAccionPadre) async {
    // AuthUsuarioServicio sListAuthUsuario = AuthUsuarioServicio();

    setState(() {
      status = StatusListaAuthUsuarios.progress;
    });
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    final accionesFiltradas = idAccionPadre != null ? _usuario.accionesId.where((accion) => accion.accionPredecesora == idAccionPadre).toList() : _usuario.accionesId;
    autLisModel.authAcciones = accionesFiltradas;

    if (autLisModel.authAcciones.isEmpty) {
      setState(() {
        status = StatusListaAuthUsuarios.failure;
      });
      return;
    }

    setState(() {
      status = StatusListaAuthUsuarios.success;
    });
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online') {
      return true;
    } else {
      return false;
    }
  }

  final List<Color> cardColors = [
    AppColors.greenColor,
    AppColors.blueColor,
    AppColors.darkTurquesa,
    Colors.green,
    // Agrega más colores según sea necesario
  ];

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Autorizaciones'),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (status == StatusListaAuthUsuarios.progress) {
            return Container(
              padding: const EdgeInsets.only(top: 10),
              alignment: Alignment.topCenter,
              child: const CircularProgressIndicator(
                color: AppColors.mainBlueColor,
              ),
            );
          }

          if (status == StatusListaAuthUsuarios.success) {
            return RefreshIndicator(
              onRefresh: () => _obtenerListAuths(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, widget.AccionPadre!.id),
              color: AppColors.mainBlueColor,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Número de columnas
                    childAspectRatio: 1, // Relación de aspecto para hacer los Card más cuadrados
                    crossAxisSpacing: 8, // Espaciado horizontal entre los elementos
                    mainAxisSpacing: 8, // Espaciado vertical entre los elementos
                  ),
                  itemCount: autLisModel.authAcciones.length,
                  itemBuilder: (context, index) {
                    final authAccion = autLisModel.authAcciones[index];
                    //final cardColor = cardColors[index % cardColors.length]; // Selección de color cíclica
                    return Card(
                      // color: AppColors.greyColor,
                      child: InkWell(
                        onTap: () {
                          if (authAccion.accion == "Documentos BackOffice") {
                            Navigator.of(context).pushNamed('irListaDocsBacko');
                            return;
                          }
                          // Donde navegas al hijo:
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SubAutorizacionesPage(
                                AccionPadre: authAccion, // 👈 se pasa directo
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6.0), // Espaciado dentro del Card
                          child: Stack(
                            children: [
                              // Contenedor principal centrado vertical y horizontalmente
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    authAccion.icono.isNotEmpty == true
                                        ? (authAccion.icono.startsWith('http')
                                            ? Image.network(
                                                authAccion.icono,
                                                height: 60,
                                                width: 60,
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, size: 60, color: AppColors.mainBlueColor),
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const SizedBox(
                                                    width: 60,
                                                    height: 60,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                'assets/images/${authAccion.icono}.png',
                                                height: 60,
                                              ))
                                        : Image.asset(
                                            'assets/images/default_icon.png',
                                            height: 60,
                                          ),
                                    const SizedBox(height: 8),
                                    Text(
                                      authAccion.accion,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                              // Row de notificaciones en la esquina superior derecha
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Visibility(
                                  visible: authAccion.pendientes != 0,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(authAccion.pendientes.toString()),
                                      const Icon(
                                        Icons.notification_important,
                                        size: 12,
                                        color: AppColors.amberColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          if (status == StatusListaAuthUsuarios.failure) {
            return RefreshIndicator(
              onRefresh: () => _obtenerListAuths(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, widget.AccionPadre!.id),
              color: AppColors.mainBlueColor,
              child: ListView(
                children: [
                  if (!_hayConexion())
                    Container(
                      padding: const EdgeInsets.all(16.0),
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
                      padding: const EdgeInsets.all(16.0), // Asegúrate de tener algo de padding para un mejor UX
                      child: Text(autLisModel.mensaje),
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
        backgroundColor: AppColors.mainBlueColor,
        tooltip: 'Regresar a Inicio',
        child: const Icon(Icons.home),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
