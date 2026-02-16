import 'dart:core';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/tipo_documento.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/parada.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/paradero.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/pasajero_domicilio.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/datos_app_servicio.dart';
import 'package:embarques_tdp/src/services/viaje_servicio.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:embarques_tdp/src/utils/responsive_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:shared_preferences/shared_preferences.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:platform/platform.dart';

import '../models/datos_app.dart';
import '../models/usuario.dart';
import '../services/google_services.dart';
import '../services/usuario_servicio.dart';
import '../utils/app_data.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _mostrarCarga = false;
  final _numDocController = TextEditingController();
  final _contraseniaController = TextEditingController();
  Usuario usuarioLog = Usuario(
    tipoDoc: "",
    numDoc: "",
    rpta: "",
    clave: "",
    usuarioId: "0",
    apellidoPat: "",
    apellidoMat: "",
    nombres: "",
    perfil: "",
    codOperacion: "",
    nombreOperacion: "",
    equipo: "",
  );
  final _formKey = GlobalKey<FormState>(); //PARA VALIDAR FORMULARIO
  bool _aumentarPaddingTopInputsU = false;
  bool _aumentarPaddingTopInputsC = false;
  int _noMostrarContra = 1;
  //bool _guardarDatosPref = false;
  String _opcSeleccionadaTipoDoc = "-1";
  final String _tipoDocGuardado = "-1";

  List<TipoDocumento> tiposDocumento = [];

  @override
  void initState() {
    _opcSeleccionadaTipoDoc = "-1";
    //_cargarPreferencias();
    _init();

    _testBackground();
    //obtenerTiposDocumentos();

    super.initState();
  }

  @override
  void dispose() {
    // Limpia el controlador cuando el widget se elimine del árbol de widgets
    _numDocController.dispose();
    _contraseniaController.dispose();

    //_focusUsuario.dispose();
    //_focusContrasenia.dispose();
    super.dispose();
  }

  _init() async {
    _opcSeleccionadaTipoDoc = "-1";
    await Provider.of<TipoDocumentoProvider>(context, listen: false).obtenerTiposDocumento();
    setState(() {
      tiposDocumento = Provider.of<TipoDocumentoProvider>(context, listen: false).tiposDocumento;
      if (tiposDocumento.isNotEmpty) {
        if (_tipoDocGuardado != "-1" && _tipoDocGuardado != "") {
          _opcSeleccionadaTipoDoc = _tipoDocGuardado;
        } else {
          _opcSeleccionadaTipoDoc = tiposDocumento.first.codigo;
        }
      }
    });
  }

  /*void _cargarPreferencias() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('usuario').toString() != "" &&
        prefs.getString('usuario') != null) {
      ///VALIDAR EL TEMA DEL USUARIO CUADNO YA SEA MODIFICADO DESPUES DE CARGAR
      ///USUARIO GUARDADO YA QUE AL CAMBIAR RECIAN LLAMARIA A INIT DE NUEVO
      _numDocController.text = prefs.getString('usuario').toString();
    }
    if (prefs.getString('password').toString() != "" &&
        prefs.getString('password') != null) {
      _contraseniaController.text = prefs.getString('password').toString();
    }
    if (prefs.getBool('check') != null) {
      _guardarDatosPref = prefs.getBool('check')!;
    }
    if (prefs.getString('tipoDoc').toString() != "" &&
        prefs.getString('tipoDoc') != null) {
      _tipoDocGuardado = prefs.getString('tipoDoc').toString();
    }
    setState(() {});
  }*/

  /*void obtenerTiposDocumentos() async {
    var serv = new TipoDocumentoServicio();
    tiposDocumento = await serv.obtenerTiposDocumento();
  }*/

  @override
  Widget build(BuildContext context) {
    bool check = false;
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.backColor,
        body: ModalProgressHUD(
          inAsyncCall: _mostrarCarga,
          child: SizedBox(
            height: height,
            width: width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    height: height,
                    margin: EdgeInsets.symmetric(horizontal: ResponsiveWidget.isSmallScreen(context) ? height * 0.032 : height * 0.12),
                    color: AppColors.backColor,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: height * 0.1,
                                ),
                                Center(
                                  child: Image(
                                    image: const AssetImage("assets/images/proLineaLogo.png"),
                                    height: height * 0.2,
                                    width: width * 0.9,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: width * 0.1, right: width * 0.1),
                                  width: width * 0.9,
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Versión ${AppData.appVersion}",
                                        style: TextStyle(fontSize: 18, color: AppColors.blackColor),
                                      ),
                                      const FittedBox(
                                        child: Text(
                                          AppData.appFechaCompilacion,
                                          style: TextStyle(color: AppColors.blackColor, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _tipoDocumentoDropdown(),
                                const SizedBox(height: 12.0),
                                _labels("NÚMERO DE DOCUMENTO"),
                                const SizedBox(height: 12.0),
                                _inputNumeroDoc(width, context),
                                const SizedBox(height: 18.0),
                                _labels("CONTRASEÑA"),
                                const SizedBox(height: 12.0),
                                _inputContrasenia(width),
                                SizedBox(height: height * 0.03),
                                /*Container(
                                margin: const EdgeInsets.symmetric(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CheckboxListTile(
                                      value: _guardarDatosPref,
                                      title: const Text(
                                        'Recordar mis datos',
                                      ),
                                      onChanged: ((value) {
                                        setState(() {
                                          _guardarDatosPref = value!;
                                        });
                                      }),
                                      secondary: const Icon(Icons.safety_check),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: height * 0.03),*/
                                Center(
                                  child: _botonIngresar(check),
                                ),
                                SizedBox(height: height * 0.03),
                                Center(
                                  child: Material(
                                    child: InkWell(
                                      child: const Text(
                                        "Salir",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      onTap: () {
                                        exit(0);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                Provider.of<UsuarioProvider>(context, listen: false).idDispositivo.toString(),
                                style: const TextStyle(color: AppColors.blackColor, fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // const FittedBox(
                            //   child: Text(
                            //     AppData.appFechaCompilacion,
                            //     style: TextStyle(color: AppColors.blackColor, fontSize: 18),
                            //   ),
                            // ),
                            const SizedBox(height: 5),
                            if (Conexion.mood == false)
                              const Center(
                                child: Text(
                                  "Desarrollo",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 35,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validarLogin() async {
    setState(() {
      _mostrarCarga = true;
    });
    var usuarioServicio = UsuarioServicio();

    await _cerrarSesionPendiente(usuarioServicio);
    // ignore: use_build_context_synchronously
    String idDispositivo = Provider.of<UsuarioProvider>(context, listen: false).idDispositivo.toString();

    Usuario usuarioLog = await usuarioServicio.iniciarSesion(
      _opcSeleccionadaTipoDoc,
      _numDocController.text,
      _contraseniaController.text,
      AppData.appVersion,
      idDispositivo,
      AppData.appFechaCompilacion,
    );

    Usuario usuarioTemporal = Usuario.empty();

    usuarioTemporal.tipoDoc = _opcSeleccionadaTipoDoc;
    usuarioTemporal.numDoc = _numDocController.text;

    setState(() {
      _mostrarCarga = false;
    });
    String sistemaOperativo = _detectarSistemaOperativo();

    switch (usuarioLog.rpta) {
      case '0':
        try {
          await GoogleServices.setEvent(
            nombreEvento: 'login_exitoso',
            usuario: usuarioLog,
            dataAdicional: '',
          );

          _cambiarPagina(usuarioLog);

          String externalUserId = '${usuarioLog.tipoDoc}-${usuarioLog.numDoc}';
          await OneSignal.login(externalUserId);

          await usuarioServicio.insertNoriUser(usuarioLog.tipoDoc, usuarioLog.numDoc, '', sistemaOperativo, idDispositivo, '', '11');
        } catch (e) {
          if (kDebugMode) {
            print('Error al insertar usuario: $e');
          }
        }

        break;
      case '4':
        //APP DESACTUALIZADA
        await GoogleServices.setEvent(
          nombreEvento: 'login_fail',
          usuario: usuarioTemporal,
          dataAdicional: 'App Desactualizada',
        );

        setState(() {
          _mostrarCarga = true;
        });

        DatosAppServicio datosAppServicio = DatosAppServicio();
        DatosApp datosApp = await datosAppServicio.obtenerDatosApp(numDoc: usuarioLog.numDoc, tipoDoc: usuarioLog.tipoDoc);

        setState(() {
          _mostrarCarga = false;
        });

        _modalAppDesactualizada(datosApp).show();
        break;
      case '9':
        await GoogleServices.setEvent(
          nombreEvento: 'login_fail',
          usuario: usuarioTemporal,
          dataAdicional: 'Sin internet',
        );
        _mensajeError('Revise su conexión a internet').show();
        break;
      default:
        await GoogleServices.setEvent(
          nombreEvento: 'login_fail',
          usuario: usuarioTemporal,
          dataAdicional: usuarioLog.mensaje,
        );
        _mensajeError(usuarioLog.mensaje).show();
    }
  }

  String _detectarSistemaOperativo() {
    const LocalPlatform platform = LocalPlatform();
    if (platform.isAndroid) {
      return 'A';
    } else if (platform.isIOS) {
      return 'I';
    } else {
      return 'Unknown';
    }
  }

  AwesomeDialog _mensajeError(String mensaje) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      //customHeader: null,
      animType: AnimType.topSlide,
      showCloseIcon: true,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            mensaje,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _cambiarPagina(Usuario usuarioLog) async {
    setState(() {
      _mostrarCarga = true;
    });

    Provider.of<UsuarioProvider>(context, listen: false).usuarioActual(usuario: usuarioLog);

    ///VERIFICAMOS SI EL USUARIO ANTERIOR LE FALTA SINCRONIZAR SU INFORMACION
    List<Usuario> usuarioListaSincronizar = await AppDatabase.instance.ObtenerUltimoUsuarioSincronziar();

    if (usuarioListaSincronizar.isNotEmpty) {
      await sincronizarViaje(usuarioListaSincronizar[0]);
    }

    ///

    List<Usuario> listausuario = await AppDatabase.instance.ObtenerUsuarioLogSincronizar();

    if (listausuario.isNotEmpty) {
      // ignore: use_build_context_synchronously
      await Log().initDebug(context, usuarioLog, listausuario[0]);
    }

    await AppDatabase.instance.NuevoRegistroBitacora(
      // ignore: use_build_context_synchronously
      context,
      "${usuarioLog.tipoDoc}-${usuarioLog.numDoc}",
      usuarioLog.codOperacion,
      DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
      "Inicio Sesion",
      "Exitoso",
    );

    usuarioLog.sesionActiva = "1";
    usuarioLog.logSincronizado = "1";
    usuarioLog.sesionSincronizada = "0";

    await AppDatabase.instance.insertarUsuario(usuarioLog);
    await AppDatabase.instance.Eliminar(tabla: "accionesUsuario");
    for (var accion in usuarioLog.acciones) {
      await AppDatabase.instance.Guardar(tabla: 'accionesUsuario', value: {"accion": accion});
    }
    /*if (_guardarDatosPref) {
      _guardarUsuario(
          _numDocController.text, _contraseniaController.text, true);
    } else {
      _guardarUsuario('', '', false);
    }*/

    // ignore: use_build_context_synchronously
    await Provider.of<RutasProvider>(context, listen: false).obtenerRutas(usuarioLog.codOperacion);

    // ignore: use_build_context_synchronously
    await Provider.of<RutasProvider>(context, listen: false).obtenerRutasSupervisor(usuarioLog.codOperacion);

    // ignore: use_build_context_synchronously
    await Provider.of<PuntoEmbarqueProvider>(context, listen: false).obtenerPuntosEmbarque(usuarioLog.codOperacion); /* NUEVO 05/05/23 */

    usuarioInit(usuarioLog);

    setState(() {
      _mostrarCarga = false;
    });

    // ignore: use_build_context_synchronously
    Navigator.pushNamedAndRemoveUntil(context, 'inicio', (route) => false);
  }

  usuarioInit(Usuario usuarioAuth) async {
    var usuarioServicio = UsuarioServicio();
    DatosVinculacion vinculacion = await usuarioServicio.obtenerDatosVinculacion(usuarioAuth.tipoDoc, usuarioAuth.numDoc, usuarioAuth.codOperacion);
    if (vinculacion.rpta == "0" || vinculacion.rpta == "1") {
      // ignore: use_build_context_synchronously
      await Provider.of<UsuarioProvider>(context, listen: false).emparejar(
        vinculacion.viajeEmp,
        vinculacion.unidadEmp,
        vinculacion.placaEmp,
        vinculacion.fechaEmp,
        vinculacion.placaEmp == "" ? "0" : "1",
      );
    }

    // if (vinculacion.viajeEmp != "" && usuarioAuth.domicilio == "1") {
    //   List<Map<String, Object?>> listaViajeDomicilio =
    //       await AppDatabase.instance.Listar(tabla: "viaje_domicilio");
    // }
  }

  Widget _botonIngresar(bool check /*BuildContext context*/) {
    return Material(
      /*PARA BOTÓN DE LOGUEAR */
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final SharedPreferences pref = await SharedPreferences.getInstance();
          await pref.remove("usuarioVinculado");

          if (_formKey.currentState!.validate()) {
            _aumentarPaddingTopInputsU = false;
            _aumentarPaddingTopInputsC = false;
            if (_opcSeleccionadaTipoDoc != '-1') {
              _validarLogin();
            } else {
              if (_opcSeleccionadaTipoDoc == '-1') {
                _mensajeError("Escoja un tipo de documento").show();
              }
            }
            //});
          } else {
            if (_numDocController.text == '') {
              _aumentarPaddingTopInputsU = true;
            } else {
              _aumentarPaddingTopInputsU = false;
            }

            if (_contraseniaController.text == '') {
              _aumentarPaddingTopInputsC = true;
            } else {
              _aumentarPaddingTopInputsC = false;
            }
          }
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 70.0, vertical: 18.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: AppColors.mainBlueColor,
          ),
          child: const Text(
            'INGRESAR',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.whiteColor,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tipoDocumentoDropdown() {
    List<DropdownMenuItem<String>> items = [];
    items = getOpcionesDropdown();
    /*_origenesProvider();*/

    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            //LO COMENTADO ES PARA QUE CUANDO ABRA SELECTOR SE HAGA EN ANCHO COMPLETO
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                //key: _keyOrigenes,
                dropdownColor: AppColors.whiteColor,
                value: _opcSeleccionadaTipoDoc,
                items: items,
                hint: const Text('TIPO DE DOCUMENTO'),
                //isDense: true, //PARA QUE OCUPE LO QUE EL TAAÑO DE LETRA OCUPA
                isExpanded: true, //PARA POSICION DE ICONO DE DESPLIEGUE
                elevation: 5,
                iconSize: 40.0,
                onChanged: (value) {
                  if (value != '-1') {
                    setState(() {
                      _opcSeleccionadaTipoDoc = value.toString();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> getOpcionesDropdown() {
    List<DropdownMenuItem<String>> listaTiposDoc = [];

    listaTiposDoc.add(const DropdownMenuItem<String>(
      value: "-1",
      child: Text("Tipo de documento", style: TextStyle(fontSize: 18)),
    ));

    if (tiposDocumento.isNotEmpty) {
      for (var i = 0; i < tiposDocumento.length; i++) {
        listaTiposDoc.add(DropdownMenuItem<String>(
          value: tiposDocumento[i].codigo,
          child: Text(
            tiposDocumento[i].nombre,
            style: const TextStyle(fontSize: 18),
          ),
        ));
      }
    } else {
      _init();
    }
    return listaTiposDoc;
  }

  Widget _labels(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.0,
          color: AppColors.blueDarkColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _inputNumeroDoc(double width, BuildContext context) {
    return Container(
      /*PARA EL INPUT DE NUMERO DE DOCUMENTO*/
      height: 50.0,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: AppColors.whiteColor,
      ),
      child: TextFormField(
        //focusNode: _focusUsuario,

        controller: _numDocController, //PARA CAPTURAR LO QUE DIGITE EN INPUT
        validator: (value) {
          if (value == '') {
            return 'INGRESE SU NÚMERO DE DOCUMENTO';
          }
          return null;
        },
        style: const TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.blueDarkColor,
          fontSize: 18.0,
        ),

        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.pin),
          ),
          contentPadding: EdgeInsets.only(
            top: (_aumentarPaddingTopInputsU) ? 50.0 : 16.0,
          ), //PARA BAJA UN POCO LA POSICION DEL TEXTO
          hintText: 'Número de documento',
          hintStyle: TextStyle(
            fontWeight: FontWeight.w400,
            color: AppColors.blueDarkColor.withOpacity(0.5),
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }

  Widget _inputContrasenia(double width) {
    return Container(
      /*PARA EL INPUT DE PASSWORD*/
      height: 50.0,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: AppColors.whiteColor,
      ),
      child: TextFormField(
        controller: _contraseniaController,
        //focusNode: _focusContrasenia,
        validator: (value) {
          if (value == '') {
            return 'INGRESE SU CONTRASEÑA';
          }
          return null;
        },
        style: const TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.blueDarkColor,
          fontSize: 18.0,
        ),
        obscureText: _noMostrarContra == 1 ? true : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          suffixIcon: IconButton(
              onPressed: () {
                _noMostrarContra = (_noMostrarContra - 1) * (-1);
                setState(() {});
              },
              icon: Icon(_noMostrarContra == 1 ? Icons.visibility : Icons.visibility_off, color: AppColors.greyColor)),
          prefixIcon: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.password),
          ),
          contentPadding: EdgeInsets.only(
            top: (_aumentarPaddingTopInputsC) ? 50.0 : 16.0,
          ),
          hintText: 'Ingrese su contraseña',
          hintStyle: TextStyle(
            fontWeight: FontWeight.w400,
            color: AppColors.blueDarkColor.withOpacity(0.5),
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }

  // void requestFocus(BuildContext contexto, FocusNode focusNode) {
  //   FocusScope.of(contexto).requestFocus(focusNode);
  // }

  Future<void> _cerrarSesionPendiente(UsuarioServicio servicio) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('CS') != null && prefs.getString('CS').toString() != "") {
      String datosCerrarSesion = prefs.getString('CS').toString();
      var datos = datosCerrarSesion.split("^");

      await servicio.cerrarSesion(datos[0], datos[1], AppData.appVersion, datos[2]);
      prefs.setString('CS', '');
    }
  }

  AwesomeDialog _modalAppDesactualizada(DatosApp datosApp) {
    bool puedesDescargar = true;

    String titulo = "APLICACIÓN DESACTUALIZADA";
    String cuerpo = "Se ha lanzado una nueva actualización. Descarga y actualiza tu aplicación para poder continuar";

    if (datosApp.rpta != "0") {
      puedesDescargar = false;
      cuerpo = "No se ha podido obtener el enlace de descarga. Intentalo otra vez";
    }

    return AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        //customHeader: null,
        animType: AnimType.topSlide,
        showCloseIcon: true,
        title: titulo,
        body: Center(
          child: Container(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
              child: Column(
                children: [
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    cuerpo,
                    textAlign: TextAlign.center,
                  ),
                ],
              )),
        ),
        btnOkColor: puedesDescargar ? AppColors.blueColor : null,
        btnOkText: puedesDescargar ? "Descargar" : null,
        btnOkOnPress: puedesDescargar
            ? () async {
                final Uri url = Uri.parse(datosApp.direccion_url);
                launchUrl(url, mode: LaunchMode.externalApplication);
              }
            : null);
  }

  _testBackground() async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return;
    }
    const config = FlutterBackgroundAndroidConfig(
      notificationTitle: 'flutter_background example app',
      notificationText: 'Background notification for keeping the example app running in the background',
      notificationIcon: AndroidResource(name: 'background_icon'),
      notificationImportance: AndroidNotificationImportance.normal,
      enableWifiLock: true,
      showBadge: true,
    );

    var hasPermissions = await FlutterBackground.hasPermissions;

    if (!hasPermissions) {
      await showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            return AlertDialog(title: const Text('Permisos necesarios'), content: const Text('En un momento se le pedirá permisos para ejecutar la aplicación en segundo plano.'), actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ]);
          });
    }

    hasPermissions = await FlutterBackground.initialize(androidConfig: config);

    if (hasPermissions) {
      if (hasPermissions) {
        final backgroundExecution = await FlutterBackground.enableBackgroundExecution();

        if (backgroundExecution) {
          if (kDebugMode) {
            print("Estoy ejecutandome en el background");
          }
        }
      }
    }
  }

  Future<void> sincronizarViaje(Usuario usuario) async {
    List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");
    List<Map<String, Object?>> listaViajeDomi = [...listaViajeDomicilio];
    if (listaViajeDomi.isNotEmpty) {
      for (var i = 0; i < listaViajeDomi.length; i++) {
        ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajeDomi[i]);
        // ignore: use_build_context_synchronously
        final usuario0 = Provider.of<UsuarioProvider>(context, listen: false).usuario;

        if (viaje.sentido == "I") {
          // ignore: use_build_context_synchronously
          await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioDesdeHome(usuario0.tipoDoc, usuario0.numDoc, context, viaje);
        } else if (viaje.sentido == "R") {
          // ignore: use_build_context_synchronously
          await Provider.of<DomicilioProvider>(context, listen: false).sincronizacionContinuaDeViajeDomicilioRepartoDesdeHome(usuario0.tipoDoc, usuario0.numDoc, context, viaje);
        }
      }
    }

    // ignore: use_build_context_synchronously
    sincronizarViajeLogin(context, usuario);
  }

  Future<ViajeDomicilio> actualizarViajeClicEmbarque(Map<String, dynamic> json) async {
    ViajeDomicilio viaje;
    viaje = ViajeDomicilio.fromJsonMapBDLocal(json);

    List<Map<String, Object?>> listaPasajeros = await AppDatabase.instance.Listar(tabla: "pasajero_domicilio", where: "nroViaje = '${viaje.nroViaje}'");

    List<PasajeroDomicilio> pasajeros = listaPasajeros.map((e) => PasajeroDomicilio.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaParada = await AppDatabase.instance.Listar(tabla: "parada", where: "nroViaje = '${viaje.nroViaje}'");

    List<Parada> paradas = listaParada.map((e) => Parada.fromJsonMapBDLocal(e)).toList();

    List<Map<String, Object?>> listaParadero = await AppDatabase.instance.Listar(tabla: "paradero");

    List<Paradero> paraderos = listaParadero.map((e) => Paradero.fromJsonMap(e)).toList();

    viaje.pasajeros = pasajeros;
    viaje.paradas = paradas;
    viaje.paraderos = paraderos;

    return viaje;
  }

  sincronizarViajeLogin(BuildContext context, Usuario usuario) async {
    var viajeServicio = ViajeServicio();

    final viajes = await viajeServicio.obtenerViajesConductorVinculadoDomicilio(usuario);
    if (viajes.isNotEmpty && viajes[0].rpta == "0") {
      await AppDatabase.instance.Eliminar(tabla: "viaje_domicilio");
      await AppDatabase.instance.Eliminar(tabla: "pasajero_domicilio");
      await AppDatabase.instance.Eliminar(tabla: "tripulante");
      await AppDatabase.instance.Eliminar(tabla: "parada");
      await AppDatabase.instance.Eliminar(tabla: "paradero");

      for (var i = 0; i < viajes.length; i++) {
        await AppDatabase.instance.Guardar(tabla: "viaje_domicilio", value: viajes[i].toMapDatabaseLocal()); //27/06/2023 16:53 -- JOHN SAMUEL : GUARDA EL VIAJE DOMICILIO EN BD LOCAL

        for (var pasajero in viajes[i].pasajeros) {
          await AppDatabase.instance.Guardar(tabla: "pasajero_domicilio", value: pasajero.toJsonBDLocal()); //27/06/2023  -- JOHN SAMUEL : GUARDA EL PASAJERO DOMICILIO EN BD LOCAL
        }

        for (var tripulante in viajes[i].tripulantes) {
          await AppDatabase.instance.Guardar(tabla: "tripulante", value: tripulante.toMapDatabase()); //27/06/2023  -- JOHN SAMUEL : GUARDA EL TRIPULANTE DOMICILIO EN BD LOCAL
        }

        for (var parada in viajes[i].paradas) {
          await AppDatabase.instance.Guardar(tabla: "parada", value: parada.toJson()); //27/06/2023  -- JOHN SAMUEL : GUARDA LA PARADA DOMICILIO EN BD LOCAL
        }

        for (var paradero in viajes[i].paraderos) {
          await AppDatabase.instance.Guardar(tabla: "paradero", value: paradero.toJson()); //27/06/2023  -- JOHN SAMUEL : GUARDA LA PARADERO DOMICILIO EN BD LOCAL
        }
      }
      List<Map<String, Object?>> listaViajeDomicilio = await AppDatabase.instance.Listar(tabla: "viaje_domicilio", where: "seleccionado = '1'");

      ViajeDomicilio viajeselecionado = ViajeDomicilio();
      if (listaViajeDomicilio.isEmpty) {
        List<Map<String, Object?>> listaViajesDomicilios = await AppDatabase.instance.Listar(tabla: "viaje_domicilio");

        for (var i = 0; i < listaViajesDomicilios.length; i++) {
          ViajeDomicilio viaje = await actualizarViajeClicEmbarque(listaViajesDomicilios[i]);

          if (viaje.nroViaje == usuario.viajeEmp) {
            await AppDatabase.instance.Update(
                table: "viaje_domicilio",
                value: {
                  "seleccionado": "1",
                },
                where: "nroViaje = '${viaje.nroViaje}'");

            viajeselecionado = viaje;
          }
        }
      } else {
        viajeselecionado = ViajeDomicilio.fromJsonMapBDLocal(listaViajeDomicilio[0]);
      }

      // ignore: use_build_context_synchronously
      await Provider.of<DomicilioProvider>(context, listen: false).actualizarViaje(viajeselecionado);

      // ignore: use_build_context_synchronously
      await Provider.of<DomicilioProvider>(context, listen: false).actualizarMarkerMostrar();

      // ignore: use_build_context_synchronously
      await Provider.of<DomicilioProvider>(context, listen: false).actualizarEstadoParadasRecojo();
    }
  }
}
