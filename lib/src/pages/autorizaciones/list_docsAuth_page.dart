import 'package:embarques_tdp/src/models/Autorizaciones/doc_Auth_model.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/auto_desauth_model.dart';
import 'package:embarques_tdp/src/services/list_docs_auth_service.dart';
import 'package:embarques_tdp/src/services/auth_desauth_service.dart';
import 'package:embarques_tdp/src/pages/autorizaciones/detail_docAuht_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/widgets.dart';
import '../../providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../../providers/connection_status_provider.dart';
import 'dart:async'; // ------------------

import '../../components/CountdownProgressBar.dart';

enum statusListaDocsAuth { initial, success, failure, progress }

enum statusAutorizaRechaza { initial, success, failure, progress }

enum statusAuthRechaza { initial, success, failure, progress }

//Switch del card
enum SwitchState { active, inactive, dual }

class ListDocsPage extends StatefulWidget {
  const ListDocsPage({super.key});

  @override
  State<ListDocsPage> createState() => _ListDocsPageState();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ListDocsPageState extends State<ListDocsPage> {
  statusListaDocsAuth status = statusListaDocsAuth.initial;

  //List<statusAuthRechaza> _responseState = [statusAuthRechaza.initial];

  //conf switch
  statusAutorizaRechaza arstatus = statusAutorizaRechaza.initial;
  SwitchState initialState = SwitchState.dual; // Estado inicial opcional con valor predeterminado

  late SwitchState _switchState = SwitchState.dual;

  late Color _switchBackgroundColor;
  late Color _circleBackgroundColor;
  late AlignmentGeometry _alignment;

  List<bool> _isCheckedList = [];
  List<bool> _isCheckedListRechaze = [];
  List<bool> _isCheckedListRevertir = [];

  List<statusAuthRechaza> _responseState = [];

  late List<SwitchState> _switchStates;
  late List<SwitchState> _previousState;

  final Map<int, Timer?> _timers = {};

  //Map<int, Timer?> _visibilityTimers = {};
  //Map<int, bool> _isCardVisible = {};  -- tis retroc

  List<bool> isCardVisible = []; // Visibilidad de cada Card
  List<double> cardOpacity = []; // Opacidad de cada Card
  List<CountdownProgressBarController> controllers = [];

  List<String> messages = [];

  bool showFullText = false;

  bool isAnySwitchSelected() {
    return _isCheckedList.contains(true);
  }

  bool isAnyRechazeSelected() {
    return _isCheckedListRechaze.contains(true);
  }

  bool isAnyRevertirSelected() {
    return _isCheckedListRevertir.contains(true);
  }

  String capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  double _sliderValue = 0.5; // Valor inicial en el centro
  DocAuthModel docsListModel = DocAuthModel(
    count: 0,
    rpta: "",
    mensaje: "",
    tipoDoc: "",
    numDoc: "",
    idSubAuth: 0,
    authDocs: [],
  );

  AutorizaRechazaModel autorizaRechazaModel = AutorizaRechazaModel(
    rpta: "500",
    mensaje: "ERROR EN LA CONSULTA",
    tipoDoc: "",
    numDoc: "",
    subAccion: "",
    idDoc: "",
    tipoDocumento: "",
    estado: "",
    motivo: "",
    documento: "",
  );

  @override
  void dispose() {
    _timers.values.forEach((timer) => timer?.cancel());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final subauthIdModel = Provider.of<SubAuthIdModel>(context, listen: false);
    final authIdModel = Provider.of<AuthIdModel>(context, listen: false);

    _obtenerListDocsAuth(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, subauthIdModel.subAuthAction.id);

    _setSwitchColors();
  }

  _obtenerListDocsAuth(String tipoDoc, String numDoc, String idSubAut) async {
    ListDocsAuthServicio sListDocsAuth = ListDocsAuthServicio();

    setState(() {
      status = statusListaDocsAuth.progress;
    });

    docsListModel = await sListDocsAuth.listarDocsAuthsUsuario(tipoDoc, numDoc, idSubAut);

    if (docsListModel.rpta != "0") {
      setState(() {
        status = statusListaDocsAuth.failure;
      });
      return;
    }

    if (docsListModel.rpta == "0") {
      setState(() {
        status = statusListaDocsAuth.success;
        _isCheckedList = List.generate(docsListModel.authDocs.length, (index) => false);
        _isCheckedListRechaze = List.generate(docsListModel.authDocs.length, (index) => false);
        _isCheckedListRevertir = List.generate(docsListModel.authDocs.length, (index) => true);
        _responseState = List.generate(docsListModel.authDocs.length, (index) => statusAuthRechaza.initial);
        //_switchStates = List.generate(docsListModel.authDocs.length, (index) => SwitchState.dual);
        _switchStates = List.generate(docsListModel.authDocs.length, (index) => SwitchState.dual);
        _previousState = List.generate(docsListModel.authDocs.length, (index) => SwitchState.dual);
        isCardVisible = List.generate(docsListModel.authDocs.length, (index) => true);
        cardOpacity = List.generate(docsListModel.authDocs.length, (index) => 1.0);
        controllers = List.generate(docsListModel.authDocs.length, (index) => CountdownProgressBarController());
      });

      return;
    }
  }

  Future<AutorizaRechazaModel> _AutorizaRechaza(String subAccion, String idDoc, String tipoDocAc, String estado, String documento, String motivo) async {
    AutorizaRechazaServicio sAutorizaRechaza = AutorizaRechazaServicio();
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final subauthIdModel = Provider.of<SubAuthIdModel>(context, listen: false);

    final autorizaRechazaModel = await sAutorizaRechaza.autorizaRechaza(
      usuarioProvider.usuario.tipoDoc,
      usuarioProvider.usuario.numDoc,
      subAccion,
      idDoc,
      tipoDocAc,
      estado,
      motivo,
      documento,
    );

    return autorizaRechazaModel;
  }

  void _setSwitchColors() {
    _switchBackgroundColor = _switchState == SwitchState.active
        ? AppColors.greenColor
        : _switchState == SwitchState.inactive
            ? AppColors.rojoLineaColor
            : AppColors.greyColor;

    _circleBackgroundColor = const Color(0xffFFFFFF);

    _alignment = _switchState == SwitchState.active
        ? Alignment.centerRight
        : _switchState == SwitchState.inactive
            ? Alignment.centerLeft
            : Alignment.center;
  }

//manejar el  color del treeswitch de tres estados
  Color _getSwitchBackgroundColor(SwitchState state, statusAuthRechaza responseState) {
    Color baseColor;
    switch (state) {
      case SwitchState.active:
        baseColor = AppColors.greenColor;
        break;
      case SwitchState.inactive:
        baseColor = AppColors.rojoLineaColor;
        break;
      case SwitchState.dual:
      default:
        baseColor = Color(0xFFefefee);
        break;
    }

    if (responseState == statusAuthRechaza.progress) {
      return Color.alphaBlend(Color.fromARGB(100, 224, 224, 224), baseColor);
    } else {
      return baseColor;
    }
  }

  //Manejar el color del los switch  de dos estados
  Color _getSwitchBackColor(bool _isCheckedListRevertir, statusAuthRechaza responseState) {
    Color baseColor;

    if (_isCheckedListRevertir) {
      baseColor = AppColors.greenColor;
    } else {
      baseColor = AppColors.greenColor;
    }

    if (responseState == statusAuthRechaza.progress) {
      return Color.alphaBlend(Color.fromARGB(100, 224, 224, 224), baseColor);
    } else {
      return baseColor;
    }
  }

  Color _getSwitchBackColorRed(bool _isCheckedListRevertir, statusAuthRechaza responseState) {
    Color baseColor;

    if (_isCheckedListRevertir) {
      baseColor = AppColors.rojoLineaColor;
    } else {
      baseColor = AppColors.rojoLineaColor;
    }

    if (responseState == statusAuthRechaza.progress) {
      return Color.alphaBlend(Color.fromARGB(100, 224, 224, 224), baseColor);
    } else {
      return baseColor;
    }
  }

  AlignmentGeometry _getSwitchAlignment(SwitchState state) {
    switch (state) {
      case SwitchState.active:
        return Alignment.centerRight;
      case SwitchState.inactive:
        return Alignment.centerLeft;
      case SwitchState.dual:
      default:
        return Alignment.center;
    }
  }

  void _toggleState() {
    setState(() {
      switch (_switchState) {
        case SwitchState.active:
          _switchState = SwitchState.dual;
          break;
        case SwitchState.inactive:
          _switchState = SwitchState.dual;
          break;
        case SwitchState.dual:
          _switchState = SwitchState.dual;
          break;
      }
      _setSwitchColors();
      // if (widget.onChanged != null) {
      //   widget.onChanged!(_switchState);
      // }
    });
  }

  // void _handleSwitchStateChange(int index, SwitchState newState) {
  //   setState(() {
  //     _switchStates[index] = newState;

  //     // Cancelar el temporizador anterior si existe
  //     _visibilityTimers[index]?.cancel();

  //     if (newState != SwitchState.dual) {
  //       // Iniciar un nuevo temporizador si el estado no es dual
  //       _visibilityTimers[index] = Timer(Duration(seconds: 10), () {
  //         setState(() {
  //           _isCardVisible[index] = false;
  //         });
  //       });
  //     } else {
  //       // Si el estado es dual, asegurarse de que el card sea visible
  //       _isCardVisible[index] = true;
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final subauthIdModel = Provider.of<SubAuthIdModel>(context);
    final authIdModel = Provider.of<AuthIdModel>(context, listen: false);
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    String subactiontext = "";
    String subactiontextplural = "";
    final provSub = Provider.of<SubAuthIdModel>(context).subAuthAction.id;

    if (provSub == "194" || provSub == "196" || provSub == "195" || provSub == "215") {
      subactiontext = "Gasto";
      subactiontextplural = "Gastos";
    } else if (provSub == "197" || provSub == "198" || provSub == "199" || provSub == "216") {
      subactiontext = "Cortesia";
      subactiontextplural = "Cortesias";
    } else if (provSub == "200" || provSub == "201" || provSub == "202" || provSub == "217") {
      subactiontext = "Adelanto de sueldo";
      subactiontextplural = "Adelantos de sueldo";
    } else if (provSub == "203" || provSub == "204" || provSub == "205" || provSub == "218") {
      subactiontext = "Vale de caja";
      subactiontextplural = "Vales de caja";
    } else {
      subactiontext = provSub;
    }

    return WillPopScope(
      onWillPop: () async {
        bool hasPendingResponses = _responseState.contains(statusAuthRechaza.progress);
        if (hasPendingResponses) {
          bool shouldExit = await _showExitConfirmationDialog();
          return shouldExit;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(subactiontextplural + ' ' + subauthIdModel.subAuthAction.action.toLowerCase()),
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () async {
              bool hasPendingResponses = _responseState.contains(statusAuthRechaza.progress);
              if (hasPendingResponses) {
                bool shouldExit = await _showExitConfirmationDialog();
                if (shouldExit) {
                  Navigator.of(context).pushNamedAndRemoveUntil('listarSubAutorizaciones', (Route<dynamic> route) => false);
                }
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil('listarSubAutorizaciones', (Route<dynamic> route) => false);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: Builder(
          builder: (context) {
            if (status == statusListaDocsAuth.progress) {
              return Container(
                padding: EdgeInsets.only(top: 10),
                alignment: Alignment.topCenter,
                child: CircularProgressIndicator(
                  color: AppColors.mainBlueColor,
                ),
              );
            }

            if (status == statusListaDocsAuth.success) {
              if (docsListModel.authDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No se encontraron ${subactiontextplural.toLowerCase()}',
                    style: TextStyle(fontSize: 18, color: AppColors.blackColor),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => _obtenerListDocsAuth(
                  usuarioProvider.usuario.tipoDoc,
                  usuarioProvider.usuario.numDoc,
                  subauthIdModel.subAuthAction.id,
                ),
                color: AppColors.mainBlueColor,
                backgroundColor: AppColors.backColor,
                child: Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 35),
                      itemCount: docsListModel.authDocs.length,
                      itemBuilder: (context, index) {
                        final docAuth = docsListModel.authDocs[index];

                        // bool isVisible = _isCardVisible[index] ?? true;
                        // if (subauthIdModel.subAuthAction.orden == "2" || subauthIdModel.subAuthAction.orden == "3") {
                        //   isVisible = _timers[index] != null || _isCheckedListRevertir[index] ?? true;
                        // } else {
                        //   isVisible = _isCardVisible[index] ?? true;
                        // }

                        return Visibility(
                          visible: isCardVisible[index],
                          // visible: isVisible,
                          child: AnimatedOpacity(
                            opacity: cardOpacity[index],
                            duration: Duration(seconds: 1),
                            onEnd: () {
                              if (cardOpacity[index] == 0) {
                                setState(() {
                                  isCardVisible[index] = false;
                                });
                              }
                            },
                            child: GestureDetector(
                              onTap: () {
                                if (docAuth.tipoDoc == 'O' || docAuth.tipoDoc == 'C'  || docAuth.tipoDoc == 'I' ) {
                                  _showDetailDialog(
                                    context,
                                    docAuth.documento,
                                    docAuth.pkOrden,
                                    docAuth.tipoDoc,
                                    docAuth.moneda,
                                    () {},
                                  );
                                }
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0), // Ajusta el radio del borde del Card
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                                  title: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              child: Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(color: AppColors.mainBlueColor, fontSize: 18),
                                                    children: [
                                                      TextSpan(
                                                        text: capitalize(docAuth.documento),
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (subauthIdModel.subAuthAction.orden == "1")
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 65,
                                                    height: 25,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius: BorderRadius.circular(20.0),
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        if (_switchStates[index] == SwitchState.active || _switchStates[index] == SwitchState.inactive) {
                                                          setState(() {
                                                            _responseState[index] = statusAuthRechaza.progress;
                                                          });
                                                          String preautOauto = 'P';
                                                          if (docAuth.tipoDoc == 'O' && docAuth.beneficiado == 'SPNA') {
                                                            preautOauto = 'P';
                                                          } else if (docAuth.tipoDoc == 'O' && docAuth.beneficiado == 'SANP') {
                                                            preautOauto = 'U';
                                                          } else {
                                                            preautOauto = 'P';
                                                          }

                                                          final response = await _AutorizaRechaza(subauthIdModel.subAuthAction.id, docAuth.pkOrden, docAuth.tipoDoc, preautOauto, docAuth.motivo, docAuth.documento);
                                                          setState(() {
                                                            _switchStates[index] = SwitchState.dual;
                                                            _previousState[index] = _switchStates[index];
                                                            _responseState[index] = response.rpta == "0" ? statusAuthRechaza.success : statusAuthRechaza.failure;
                                                          });
                                                          if (response.rpta == "0") {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('Mantener ${subactiontext.toLowerCase()} en pendiente'),
                                                                duration: Duration(seconds: 1),
                                                                backgroundColor: AppColors.greyColor,
                                                              ),
                                                            );
                                                            controllers[index].cancelTimer?.call();
                                                          } else if (response.rpta != "0") {
                                                            setState(() {
                                                              _switchStates[index] = SwitchState.dual;
                                                              _previousState[index] = _switchStates[index];
                                                            });
                                                            if (_hayConexion()) {
                                                              _showErrorDialog(context, 'Error', 'Ha ocurrido un error en la operación: ${response.documento}: ${response.mensaje}', DialogType.error);
                                                            } else {
                                                              _showErrorDialog(context, 'Sin Conexión', 'Revise su conexión a internet', DialogType.warning);
                                                            }
                                                          }
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Deslice a la derecha para aprobar y a la izquierda para rechazar.'),
                                                              duration: Duration(seconds: 2),
                                                              backgroundColor: AppColors.mainBlueColor,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      onHorizontalDragUpdate: (details) {
                                                        setState(() {
                                                          final containerWidth = 100.0;
                                                          final horizontalDrag = details.primaryDelta! / containerWidth;
                                                          //SwitchState estadoInicial = _switchStates[index];
                                                          // Actualizar el estado del interruptor basado en la dirección del gesto horizontal

                                                          if (horizontalDrag > 0.0) {
                                                            _switchStates[index] = SwitchState.active;
                                                          } else if (horizontalDrag < 0.0) {
                                                            _switchStates[index] = SwitchState.inactive;
                                                          } else {
                                                            _switchStates[index] = SwitchState.dual;
                                                          }
                                                        });
                                                      },
                                                      onHorizontalDragEnd: (details) {
                                                        void callApiAndUpdateState(int index, String estado) async {
                                                          setState(() {
                                                            _responseState[index] = statusAuthRechaza.progress;
                                                          });
                                                          final response = await _AutorizaRechaza(subauthIdModel.subAuthAction.id, docAuth.pkOrden, docAuth.tipoDoc, estado, docAuth.motivo, docAuth.documento);

                                                          setState(() {
                                                            if (response.rpta == "0") {
                                                              if (_switchStates[index] == SwitchState.active) {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text('$subactiontext aprobado con éxito'),
                                                                    duration: Duration(seconds: 1),
                                                                    backgroundColor: AppColors.greenColor,
                                                                  ),
                                                                );
                                                                controllers[index].startOrResetTimer?.call();
                                                              } else if (_switchStates[index] == SwitchState.inactive) {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text('$subactiontext rechazado con éxito'),
                                                                    duration: Duration(seconds: 1),
                                                                    backgroundColor: AppColors.rojoLineaColor,
                                                                  ),
                                                                );
                                                                controllers[index].startOrResetTimer?.call();
                                                              } else if (_switchStates[index] == SwitchState.dual) {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text('Mantener ${subactiontext.toLowerCase()}  en pendiente'),
                                                                    duration: Duration(seconds: 1),
                                                                    backgroundColor: AppColors.greyColor,
                                                                  ),
                                                                );
                                                                controllers[index].cancelTimer?.call();
                                                              }

                                                              _responseState[index] = statusAuthRechaza.success;
                                                            } else if (response.rpta == "2") {
                                                              // Tratar otro caso si es necesario
                                                            } else {
                                                              _switchStates[index] = SwitchState.dual; // Actualizar estado si hay error
                                                              _responseState[index] = statusAuthRechaza.failure;
                                                              if (_hayConexion()) {
                                                                _showErrorDialog(context, 'Error', 'Ha ocurrido un error en la operación: ${response.documento}: ${response.mensaje}', DialogType.error);
                                                              } else {
                                                                _showErrorDialog(context, 'Sin Conexión', 'Revise su conexión a internet', DialogType.warning);
                                                              }
                                                            }
                                                            _previousState[index] = _switchStates[index]; // Actualizar estado previo
                                                          });
                                                        }

                                                        setState(() {
                                                          if (_previousState[index] != _switchStates[index]) {
                                                            String estado;
                                                            if (_switchStates[index] == SwitchState.active) {
                                                              if (docAuth.tipoDoc == 'O' && docAuth.beneficiado == 'SPNA') {
                                                                estado = 'U';
                                                              } else {
                                                                estado = 'A';
                                                              }
                                                            } else if (_switchStates[index] == SwitchState.inactive) {
                                                              estado = 'R';
                                                            } else {
                                                              estado = 'P';
                                                            }

                                                            callApiAndUpdateState(index, estado); // Llama a la función aquí
                                                          } else {
                                                            _showErrorDialog(context, 'Sin cambio', 'No se realizó ningún cambio', DialogType.info);
                                                          }
                                                          _previousState[index] = _switchStates[index];
                                                        });
                                                      },
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 200),
                                                        decoration: BoxDecoration(
                                                          color: _getSwitchBackgroundColor(_switchStates[index], _responseState[index]),
                                                          borderRadius: BorderRadius.circular(20.0),
                                                        ),
                                                        padding: const EdgeInsets.all(2.0),
                                                        alignment: _getSwitchAlignment(_switchStates[index]),
                                                        child: Stack(
                                                          children: [
                                                            Align(
                                                              alignment: Alignment.centerLeft,
                                                              child: Icon(Icons.close, color: _switchStates[index] == SwitchState.dual ? AppColors.rojoLineaColor : Colors.transparent, size: 14.0), // Icono de "X" a la izquierda
                                                            ),
                                                            Align(
                                                              alignment: Alignment.centerRight,
                                                              child: Icon(Icons.check, color: _switchStates[index] == SwitchState.dual ? AppColors.greenColor : Colors.transparent, size: 14.0), // Icono de "check" a la derecha
                                                            ),
                                                            Align(
                                                              alignment: _getSwitchAlignment(_switchStates[index]),
                                                              child: Container(
                                                                //------start
                                                                height: 27.0,
                                                                width: 27.0,
                                                                decoration: BoxDecoration(
                                                                  shape: BoxShape.circle,
                                                                  color: _circleBackgroundColor,
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors.black.withOpacity(0.2), // Color de la sombra
                                                                      spreadRadius: 1, // Radio de expansión de la sombra
                                                                      blurRadius: 5, // Radio de desenfoque de la sombra
                                                                      offset: Offset(0, 2), // Desplazamiento de la sombra (x, y)
                                                                    ),
                                                                  ],
                                                                ),
                                                              ), // --------end
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (subauthIdModel.subAuthAction.orden == "2" || subauthIdModel.subAuthAction.orden == "3")
                                              Row(
                                                children: [
                                                  Switch(
                                                    value: _isCheckedListRevertir[index] ?? true,
                                                    onChanged: (bool value) async {
                                                      final bool originalValue = _isCheckedListRevertir[index] ?? true;

                                                      setState(() {
                                                        _isCheckedListRevertir[index] = value;
                                                        _responseState[index] = statusAuthRechaza.progress;
                                                      });

                                                      // if (!value) {
                                                      //   // Si el switch se desactiva, inicia un temporizador de 15 segundos
                                                      //   controllers[index].controlTimer?.call(); // Iniciar o reiniciar el temporizador
                                                      //   if (cardOpacity[index] == 0.0) {
                                                      //     setState(() {
                                                      //       cardOpacity[index] = 1.0;
                                                      //       isCardVisible[index] = true;
                                                      //     });
                                                      //   }
                                                      // } else {
                                                      //   controllers[index].controlTimer?.call(); // Iniciar o reiniciar el temporizador
                                                      //   if (cardOpacity[index] == 0.0) {
                                                      //     setState(() {
                                                      //       cardOpacity[index] = 1.0;
                                                      //       isCardVisible[index] = true;
                                                      //     });
                                                      //   }
                                                      // }

                                                      String activaOrecha = "";
                                                      String textactivaOrecha = "";
                                                      String OrdenAuthoPreAut = "";
                                                      Color Coloresult = AppColors.greyColor;

                                                      if (docAuth.tipoDoc == 'O' && docAuth.beneficiado == 'SANP') {
                                                        OrdenAuthoPreAut = "U";
                                                      } else {
                                                        OrdenAuthoPreAut = "P";
                                                      }

                                                      if (subauthIdModel.subAuthAction.orden == "2") {
                                                        if (docAuth.tipoDoc == 'O' && docAuth.beneficiado == 'SPNA') {
                                                          activaOrecha = "U";
                                                        } else {
                                                          activaOrecha = "A";
                                                          textactivaOrecha = "aprobados";
                                                          Coloresult = AppColors.greenColor;
                                                        }
                                                      } else if (subauthIdModel.subAuthAction.orden == "3") {
                                                        activaOrecha = "R";
                                                        textactivaOrecha = "rechazados";
                                                        Coloresult = AppColors.rojoLineaColor;
                                                      } //--hou

                                                      final response = await _AutorizaRechaza(subauthIdModel.subAuthAction.id, docAuth.pkOrden, docAuth.tipoDoc, value ? activaOrecha : OrdenAuthoPreAut, docAuth.motivo, docAuth.documento);
                                                      if (response.rpta == "0") {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(value ? "Mantener  ${subactiontext.toLowerCase()} en $textactivaOrecha" : "$subactiontext enviado a pendientes con éxito"),
                                                            duration: Duration(seconds: 1),
                                                            backgroundColor: value ? Coloresult : AppColors.greyColor,
                                                          ),
                                                        );
                                                        setState(() {
                                                          _responseState[index] = statusAuthRechaza.success;
                                                        });

                                                        if (!value) {
                                                          controllers[index].startOrResetTimer?.call();
                                                        } else {
                                                          controllers[index].cancelTimer?.call();
                                                        }
                                                      } else if (response.rpta != "0" && _hayConexion()) {
                                                        _showErrorDialog(context, 'Error', 'Ha ocurrido un error en la operación: ${response.documento}: ${response.mensaje}', DialogType.error);
                                                        setState(() {
                                                          _isCheckedListRevertir[index] = originalValue;
                                                          _responseState[index] = statusAuthRechaza.failure;
                                                        });
                                                      } else if (!_hayConexion()) {
                                                        _showErrorDialog(context, 'Sin Conexión', 'Revise su conexión a internet', DialogType.warning);
                                                        setState(() {
                                                          _isCheckedListRevertir[index] = originalValue;
                                                          _responseState[index] = statusAuthRechaza.failure;
                                                        });
                                                      }
                                                    },

                                                    activeColor: subauthIdModel.subAuthAction.orden == '2' ? _getSwitchBackColor(_isCheckedListRevertir[index], _responseState[index]) : _getSwitchBackColorRed(_isCheckedListRevertir[index], _responseState[index]), //_isCheckedListRevertir[index] ?? false ? AppColors.greenColor : Color.fromARGB(255, 7, 38, 180),
                                                    // inactiveThumbColor:
                                                    // inactiveTrackColor: AppColors.rojoLineaColor,

                                                    inactiveThumbColor: _responseState[index] == statusAuthRechaza.progress ? AppColors.greyColor.withOpacity(0.5) : AppColors.whiteColor,
                                                    // inactiveTrackColor: _responseState[index] == statusAuthRechaza.progress ? Color.fromARGB(173, 76, 176, 10).withOpacity(0.2) : null,
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                ],
                                              ),
                                            if (subauthIdModel.subAuthAction.orden == "4")
                                              Container(
                                                padding: EdgeInsets.all(3.0), // Padding alrededor del texto
                                                decoration: BoxDecoration(
                                                  color: getColor(docAuth.canalizador), // Color de fondo

                                                  borderRadius: BorderRadius.circular(4), // Bordes redondeados, si quieres bordes rectos puedes eliminar esta línea
                                                ),
                                                child: Text(
                                                  getText(docAuth.canalizador),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white, // Color del texto
                                                  ),
                                                ),
                                              )

                                            //   Row(
                                            //     mainAxisAlignment: MainAxisAlignment.start,
                                            //     children: [
                                            //       Expanded(
                                            //         child: RichText(
                                            //           text: TextSpan(
                                            //             style: const TextStyle(color: AppColors.greenColor, fontSize: 16, backgroundColor: AppColors.amberColor),
                                            //             children: [
                                            //               const TextSpan(
                                            //                 text: 'Estado: ',
                                            //                 style: TextStyle(fontWeight: FontWeight.bold),
                                            //               ),
                                            //               TextSpan(text: docAuth.beneficiado),
                                            //             ],
                                            //           ),
                                            //         ),
                                            //       ),
                                            //     ],
                                            //   ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(color: AppColors.greenColor, fontSize: 16),
                                                      children: [
                                                        const TextSpan(
                                                          text: 'Fecha: ',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        TextSpan(text: docAuth.fecha.substring(0, 10)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            if (docAuth.preAutorizador != "" && provSub == '215') const SizedBox(height: 6),
                                            if (docAuth.preAutorizador != "" && provSub == '215')
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                        children: [
                                                          TextSpan(
                                                            text: 'PreAutorizador: ',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          TextSpan(
                                                            text: docAuth.preAutorizador,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            if (docAuth.beneficiado != "" && provSub == '215') const SizedBox(height: 6),
                                            if (docAuth.beneficiado != "" && provSub == '215')
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                        children: [
                                                          TextSpan(
                                                            text: 'Autorizador: ',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          TextSpan(
                                                            text: docAuth.beneficiado,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            if (docAuth.preAutorizador != "" && provSub != '215') const SizedBox(height: 6),
                                            if (docAuth.preAutorizador != "" && provSub != '215')
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                        children: [
                                                          TextSpan(
                                                            text: docAuth.beneficiado == 'SPNA' ? 'Autorizador: ' : 'PreAutorizador: ',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          TextSpan(
                                                            text: docAuth.preAutorizador,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            //Proveedor
                                            if (docAuth.proveedor != "" && subauthIdModel.subAuthAction.orden == "4" && docAuth.tipoDoc != 'O') const SizedBox(height: 6),
                                            if (docAuth.proveedor != "" && subauthIdModel.subAuthAction.orden == "4" && docAuth.tipoDoc != 'O')
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                        children: [
                                                          const TextSpan(
                                                            text: 'Autorizador: ',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          TextSpan(
                                                            text: capitalize(docAuth.proveedor),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            const SizedBox(height: 6),
                                            //Motivo
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  //child: GestureDetector(
                                                  // onTap: () {
                                                  //   setState(() {
                                                  //     docAuth.showFullText = !docAuth.showFullText;
                                                  //   });
                                                  // },
                                                  child: RichText(
                                                    softWrap: true,
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                    text: TextSpan(
                                                      style: const TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                      children: <TextSpan>[
                                                        TextSpan(text: 'Motivo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                        TextSpan(
                                                          text: capitalize(docAuth.motivo.toLowerCase()),
                                                          //text: capitalize(docAuth.showFullText || docAuth.motivo.length <= 55 ? docAuth.motivo.toLowerCase() : '${docAuth.motivo.substring(0, 55).toLowerCase()}...'),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 6),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  flex: 5,
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                      children: [
                                                        const TextSpan(
                                                          text: 'Total: ',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        TextSpan(text: docAuth.moneda + docAuth.precioVenta.toString()),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 6,
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                      children: [
                                                        const TextSpan(
                                                          text: 'Forma Pago: ',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        TextSpan(text: docAuth.tipoPago),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            if (docAuth.tipoDoc != 'O') const SizedBox(height: 6),
                                            if (docAuth.tipoDoc != 'O')
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                        children: [
                                                          const TextSpan(
                                                            text: 'Beneficiado: ',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          TextSpan(
                                                            text: capitalize(docAuth.beneficiado),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            //Proveedor
                                            if (docAuth.proveedor != "" && subactiontext == 'Gasto') const SizedBox(height: 6),
                                            if (docAuth.proveedor != "" && subactiontext == 'Gasto')
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                        children: [
                                                          const TextSpan(
                                                            text: 'Proveedor: ',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          TextSpan(
                                                            text: capitalize(docAuth.proveedor),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            if (subauthIdModel.subAuthAction.orden != "4")
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                                        children: [
                                                          const TextSpan(
                                                            text: 'Registrador: ',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          TextSpan(
                                                            text: docAuth.canalizador,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (docAuth.tipoDoc == "O" || docAuth.tipoDoc == "C")
                                                    GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _showDetailDialog(
                                                            context,
                                                            docAuth.documento,
                                                            docAuth.pkOrden,
                                                            docAuth.tipoDoc,
                                                            docAuth.moneda,
                                                            () {},
                                                          );
                                                        });
                                                      },
                                                      child: const Padding(
                                                        padding: const EdgeInsets.all(5),
                                                        child: Icon(
                                                          Icons.add,
                                                          size: 25,
                                                          color: AppColors.blackColor,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),

                                            //Registrador con  el + y es encaso que no exista preautorizador
                                            // if (docAuth.preAutorizador == ""&& ) const SizedBox(height: 6),
                                            // if (docAuth.preAutorizador == "" && subauthIdModel.subAuthAction.orden != "4")

                                            //   ///cercaaa .................
                                            //   Row(
                                            //     children: [
                                            //       Expanded(
                                            //         child: RichText(
                                            //           text: TextSpan(
                                            //             style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                            //             children: [
                                            //               const TextSpan(
                                            //                 text: 'Registrador: ',
                                            //                 style: TextStyle(fontWeight: FontWeight.bold),
                                            //               ),
                                            //               TextSpan(
                                            //                 text: docAuth.canalizador,
                                            //               ),
                                            //             ],
                                            //           ),
                                            //         ),
                                            //       ),
                                            //       if (docAuth.tipoDoc == "O" || docAuth.tipoDoc == "C")
                                            //         GestureDetector(
                                            //           onTap: () {
                                            //             setState(() {
                                            //               _showDetailDialog(
                                            //                 context,
                                            //                 docAuth.documento,
                                            //                 docAuth.pkOrden,
                                            //                 docAuth.tipoDoc,
                                            //                 docAuth.moneda,
                                            //                 () {},
                                            //               );
                                            //             });
                                            //           },
                                            //           child: const Padding(
                                            //             padding: const EdgeInsets.all(5),
                                            //             child: Icon(
                                            //               Icons.add,
                                            //               size: 25,
                                            //               color: AppColors.blackColor,
                                            //             ),
                                            //           ),
                                            //         ),
                                            //     ],
                                            //   ),

                                            //Preautorizador
                                            // if (docAuth.preAutorizador != "")
                                            //   Row(
                                            //     children: [
                                            //       Expanded(
                                            //         child: RichText(
                                            //           text: TextSpan(
                                            //             style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                            //             children: [
                                            //               TextSpan(
                                            //                 text: docAuth.beneficiado == 'SPNA' ? 'Autorizador: ' : 'PreAutorizador: ',
                                            //                 style: TextStyle(fontWeight: FontWeight.bold),
                                            //               ),
                                            //               TextSpan(
                                            //                 text: docAuth.preAutorizador,
                                            //               ),
                                            //             ],
                                            //           ),
                                            //         ),
                                            //       ),
                                            //       if (docAuth.tipoDoc == "O" || docAuth.tipoDoc == "C")
                                            //         GestureDetector(
                                            //           onTap: () {
                                            //             setState(() {
                                            //               _showDetailDialog(
                                            //                 context,
                                            //                 docAuth.documento,
                                            //                 docAuth.pkOrden,
                                            //                 docAuth.tipoDoc,
                                            //                 docAuth.moneda,
                                            //                 () {},
                                            //               );
                                            //             });
                                            //           },
                                            //           child: const Padding(
                                            //             padding: const EdgeInsets.all(5),
                                            //             child: Icon(
                                            //               Icons.add,
                                            //               size: 25,
                                            //               color: AppColors.blackColor,
                                            //             ),
                                            //           ),
                                            //         ),
                                            //     ],
                                            //   ),
                                            CountdownProgressBar(
                                              duration: 15,
                                              onComplete: () async {
                                                setState(() {
                                                  cardOpacity[index] = 0.0;
                                                });
                                              },
                                              controller: controllers[index], // Pasar el controlador correspondiente
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            if (status == statusListaDocsAuth.failure) {
              return RefreshIndicator(
                onRefresh: () => _obtenerListDocsAuth(
                  usuarioProvider.usuario.tipoDoc,
                  usuarioProvider.usuario.numDoc,
                  subauthIdModel.subAuthAction.id,
                ),
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
                        child: Text(docsListModel.mensaje),
                      ),
                  ],
                ),
              );
            }

            return Container();
          },
        ),
      ),
    );
  }

  bool _hayConexion() {
    if (Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online')
      return true;
    else
      return false;
  }

  void _showErrorDialog(BuildContext context, String title, String description, DialogType error) {
    AwesomeDialog(
      context: context,
      dialogType: error,
      animType: AnimType.rightSlide,
      title: title,
      desc: description,
      btnOkOnPress: () {},
      btnOkColor: AppColors.rojoLineaColor,
      btnOkText: 'Aceptar',
    ).show();
  }

  //Alerta para asegurar  que en caso haya procedimientos que aun no dan respuesta  confirme si salir de la  pagina  o no
  Future<bool> _showExitConfirmationDialog() async {
    bool? shouldExit = false;
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: 'Confirmación',
      desc: 'Es posible que no se realicen algunos cambios, ¿seguro de salir?',
      btnCancelOnPress: () {
        shouldExit = false;
      },
      btnOkOnPress: () {
        shouldExit = true;
      },
      btnCancelText: 'Cancelar',
      btnOkText: 'Salir',
    ).show();

    return shouldExit ?? false;
  }
  // Future<void> _autorizarRezhazar() async {
  //   final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
  //   final subauthIdModel = Provider.of<SubAuthIdModel>(context, listen: false);
  //   // Mostrar diálogo de progreso
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false, // Evita que el usuario cierre el diálogo haciendo clic fuera de él
  //     builder: (context) => const AlertDialog(
  //       content: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           CircularProgressIndicator(
  //             color: AppColors.mainBlueColor,
  //           ), // Indicador de progreso circular
  //           SizedBox(width: 20),
  //           Text('Procesando...'), // Texto que indica que se está procesando
  //         ],
  //       ),
  //     ),
  //   );
  //   List<String> failedMessages = [];
  //   for (int i = 0; i < docsListModel.authDocs.length; i++) {
  //     if (_isCheckedList[i] == true) {
  //       final result = await _AutorizaRechaza(docsListModel.authDocs[i].pkOrden, docsListModel.authDocs[i].tipoDoc, 'A', docsListModel.authDocs[i].motivo, docsListModel.authDocs[i].documento);
  //       if (result.rpta != "0") {
  //         failedMessages.add("${result.idDoc}: ${result.mensaje}");
  //       }
  //     }
  //     if (_isCheckedListRechaze[i] == true) {
  //       final result = await _AutorizaRechaza(docsListModel.authDocs[i].pkOrden, docsListModel.authDocs[i].tipoDoc, 'R', docsListModel.authDocs[i].motivo, docsListModel.authDocs[i].documento);
  //       if (result.rpta != "0") {
  //         failedMessages.add("${result.documento}: ${result.mensaje}");
  //       }
  //     }
  //     if (_isCheckedListRevertir[i] == true) {
  //       final result = await _AutorizaRechaza(docsListModel.authDocs[i].pkOrden, docsListModel.authDocs[i].tipoDoc, 'P', docsListModel.authDocs[i].motivo, docsListModel.authDocs[i].documento);
  //       if (result.rpta != "0") {
  //         failedMessages.add(" ${result.idDoc}: ${result.mensaje}");
  //       }
  //     }
  //   }
  //   Navigator.of(context).pop();
  //   setState(() {
  //     arstatus = statusAutorizaRechaza.initial;
  //   });
  //   if (failedMessages.isEmpty) {
  //     _showResultDialog('Cambios realizados con éxito', 'Todos los cambios han sido actualizados exitosamente.', DialogType.success);
  //     _obtenerListDocsAuth(
  //       usuarioProvider.usuario.tipoDoc,
  //       usuarioProvider.usuario.numDoc,
  //       subauthIdModel.subAuthAction.id,
  //     );
  //   } else {
  //     _showResultDialog('Cambios parcialmente realizados', 'Algunos cambios no pudieron ser realizados:\n${failedMessages.join('\n')}', DialogType.info);
  //     _obtenerListDocsAuth(
  //       usuarioProvider.usuario.tipoDoc,
  //       usuarioProvider.usuario.numDoc,
  //       subauthIdModel.subAuthAction.id,
  //     );
  //   }
  // }

  // void _showResultDialog(String titulo, String mensaje, DialogType dialogtype) {
  //   AwesomeDialog(
  //     context: context,
  //     dialogType: dialogtype,
  //     animType: AnimType.rightSlide,
  //     title: titulo,
  //     desc: mensaje,
  //     btnOkOnPress: () {},
  //     btnOkColor: AppColors.mainBlueColor,
  //   )..show();
  // }

  // Función para obtener el color dinámico
  Color getColor(String canalizador) {
    switch (canalizador) {
      case 'P':
        return AppColors.greyColor; // Color para 'Pendiente'
      case 'R':
        return AppColors.redColor; // Color para 'Rechazado'
      case 'A':
        return AppColors.greenColor; // Color para 'Aprobado'
      case 'U':
        return AppColors.amberColor; // Color para 'Preautorizado'
      default:
        return AppColors.lightBlue; // Color por defecto
    }
  }

// Función para obtener el texto dinámico
  String getText(String canalizador) {
    switch (canalizador) {
      case 'P':
        return 'Pendiente';
      case 'R':
        return 'Rechazado';
      case 'A':
        return 'Aprobado';
      case 'U':
        return 'Preautorizado';
      default:
        return 'Desconocido'; // Texto por defecto
    }
  }

  void _showDetailDialog(BuildContext context, String documento, String pkOrden, String tipoDocOrden, String moneda, VoidCallback onConfirm) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          titlePadding: EdgeInsets.fromLTRB(15.0, 10.0, 0.0, 0.0),
          contentPadding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
          backgroundColor: AppColors.backColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 20),
                    children: [
                      TextSpan(
                        text: documento,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blackColor),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.cancel_presentation_rounded),
                onPressed: () => Navigator.pop(context),
                color: AppColors.rojoLineaColor,
              ),
            ],
          ),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.6, // Ajusta la altura aquí
            width: MediaQuery.of(context).size.width * 0.9,
            child: DetailPage(
              pkOrden: pkOrden,
              tipoDocOrden: tipoDocOrden,
              moneda: moneda,
              onConfirm: onConfirm,
            ),
          ),
        );
      },
    );
  }
}
