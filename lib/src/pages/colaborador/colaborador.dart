import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorAreas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorDatos.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorEmpresas.dart';
import 'package:embarques_tdp/src/models/colaborador/colaboradorTipoDoc.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/pages/colaborador/bloc/colaborador_bloc.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/colaborador/colaborador_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class ColaboradorPage extends StatelessWidget {
  const ColaboradorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => ColaboradorServicio(),
        )
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ColaboradorBloc(
              colaboradorServicio: RepositoryProvider.of<ColaboradorServicio>(context),
            ),
          ),
        ],
        child: ColaboradorPageBody(),
      ),
    );
  }
}

class ColaboradorPageBody extends StatefulWidget {
  const ColaboradorPageBody({super.key});

  @override
  State<ColaboradorPageBody> createState() => _ColaboradorPageBodyState();
}

class _ColaboradorPageBodyState extends State<ColaboradorPageBody> {
  FocusNode _focusNdoc = new FocusNode();
  FocusNode _focusPaterno = new FocusNode();
  FocusNode _focusMaterno = new FocusNode();
  FocusNode _focusNombres = new FocusNode();
  FocusNode _focusCodExt = new FocusNode();
  TextEditingController textNdocController = TextEditingController();
  TextEditingController textPaternoController = TextEditingController();
  TextEditingController textMaternoController = TextEditingController();
  TextEditingController textNombresController = TextEditingController();
  TextEditingController textCodExtController = TextEditingController();

  bool light1 = true;
  String tdoc = "";

  String idEmpresa = "";
  String idArea = "";

  late Usuario _usuario;
  @override
  void initState() {
    super.initState();
    _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    context.read<ColaboradorBloc>().add(ListarTipoDoc());
    context.read<ColaboradorBloc>().add(
          ListarEmpresas(
            CodOperacion: _usuario.codOperacion,
            usuario: "${_usuario.tipoDoc.trim()}${_usuario.numDoc.trim()}",
            initialEmpresa: "",
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ColaboradorBloc, ColaboradorState>(
      listener: (context, state) {
        if (state.rpta == "1") {
          textPaternoController.text = state.colaboradorDatos.paterno;
          textMaternoController.text = state.colaboradorDatos.materno;
          textNombresController.text = state.colaboradorDatos.nombres;
          textCodExtController.text = state.colaboradorDatos.codigoExterno;
          light1 = state.colaboradorDatos.activo == "1" ? true : false;

          setState(() {
            idArea = state.initialArea;
            idEmpresa = state.initialEmpresa;
          });
        }
        if (state.rptaGuardarEditar == "0") {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
            ..showSnackBar(
              SnackBar(
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
                content: Text("Colaborador guardado correctamente"),
              ),
            );
        }
        if (state.rptaGuardarEditar != "0" && state.rptaGuardarEditar != "-1") {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
            ..showSnackBar(
              SnackBar(
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
                content: Text("Error al guardar el colaborador"),
              ),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Agregar Personal"),
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
            ),
          ),
          actions: [
            Container(
              child: Switch(
                hoverColor: Colors.grey,
                focusColor: Colors.grey,
                trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color.fromARGB(255, 0, 179, 21).withOpacity(0.8);
                  }
                  return Colors.grey;
                }),
                activeColor: const Color.fromARGB(255, 0, 179, 21),
                thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return const Icon(Icons.check);
                    }
                    return const Icon(Icons.close);
                  },
                ),
                value: light1,
                onChanged: (bool value) {
                  setState(() {
                    light1 = value;
                  });
                },
              ),
            )
          ],
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 45,
              width: MediaQuery.of(context).size.width * 0.45,
              child: MaterialButton(
                color: AppColors.greenColor,
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                onPressed: () {
                  bool validate = true;

                  if (textPaternoController.text.trim().length == 0) {
                    MensajeAlert("El apellido paterno obligatorio", "", false).show();
                    validate = false;
                    return;
                  }

                  if (textMaternoController.text.trim().length == 0) {
                    MensajeAlert("El apellido materno obligatorio", "", false).show();
                    validate = false;

                    return;
                  }

                  if (textNombresController.text.trim().length == 0) {
                    MensajeAlert("El nombre obligatorio", "", false).show();
                    validate = false;

                    return;
                  }

                  if (textCodExtController.text.trim().length == 0) {
                    MensajeAlert("El codigo externo obligatorio", "", false).show();
                    validate = false;

                    return;
                  }
                  if (textNdocController.text.trim().length == 0) {
                    MensajeAlert("El número documento obligatorio", "", false).show();
                    validate = false;

                    return;
                  }
                  if (tdoc == "DNI" && textNdocController.text.trim().length < 8 || textNdocController.text.trim().length > 8) {
                    MensajeAlert("El número de debe tener 8 digitos", "", false).show();
                    validate = false;

                    return;
                  }
                  if (idEmpresa.trim().length == 0) {
                    MensajeAlert("La empresa es obligatorio", "", false).show();
                    validate = false;

                    return;
                  }
                  if (idArea.trim().length == 0) {
                    MensajeAlert("El area es obligatorio", "", false).show();
                    validate = false;
                    return;
                  }

                  if (validate) {
                    _showDialogSincronizandoDatos(context, "Cargando...");
                    context.read<ColaboradorBloc>().add(CrearEditarColaborador(
                          CodOperacion: _usuario.codOperacion,
                          usuario: "${_usuario.tipoDoc}${_usuario.numDoc}",
                          tDoc: "${tdoc}",
                          nDoc: "${textNdocController.text.trim()}",
                          paterno: "${textPaternoController.text.trim()}",
                          materno: "${textMaternoController.text.trim()}",
                          nombres: "${textNombresController.text.trim()}",
                          idEmpresa: "${idEmpresa}",
                          idArea: "${idArea}",
                          Activo: light1 == true ? "1" : "0",
                          codExterno: "${textCodExtController.text.trim()}",
                        ));
                  }
                },
                child: Text(
                  "Guardar",
                  style: TextStyle(color: AppColors.whiteColor),
                ),
              ),
            )
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      BlocBuilder<ColaboradorBloc, ColaboradorState>(
                        builder: (context, state) {
                          tdoc = state.listaTipoDoc.length > 0 ? state.listaTipoDoc.first.nombre : "";

                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 0),
                            child: DropdownMenu<String>(
                              inputDecorationTheme: InputDecorationTheme(
                                isDense: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                constraints: BoxConstraints.tight(const Size.fromHeight(53)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              textStyle: TextStyle(
                                color: AppColors.mainBlueColor,
                              ),
                              initialSelection: state.listaTipoDoc.length > 0 ? state.listaTipoDoc.first.codigo : "",
                              onSelected: (String? value) {
                                if (value != null) {
                                  tdoc = value;
                                }

                                // dropdownValue = value!;
                              },
                              dropdownMenuEntries: state.listaTipoDoc.map<DropdownMenuEntry<String>>((ColaboradorTipoDoc value) {
                                return DropdownMenuEntry<String>(
                                  value: value.codigo,
                                  label: value.nombre,
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      Container(
                        child: Expanded(
                          child: inputField(
                            label: "Número Documento",
                            focus: _focusNdoc,
                            isButton: true,
                            Controller: textNdocController,
                            onEditingComplete: () {},
                            onPressed: () {
                              if (textNdocController.text.trim().length > 0) {
                                context.read<ColaboradorBloc>().add(GetColaboradorDatos(
                                      CodOperacion: _usuario.codOperacion,
                                      usuario: "${_usuario.tipoDoc}${_usuario.numDoc}",
                                      tDoc: "${tdoc}",
                                      nDoc: "${textNdocController.text.trim()}",
                                    ));
                              }
                            },
                            onChanged: (value) {
                              if (value.length == 8) {
                                print("1");
                                context.read<ColaboradorBloc>().add(GetColaboradorDatos(
                                      CodOperacion: _usuario.codOperacion,
                                      usuario: "${_usuario.tipoDoc}${_usuario.numDoc}",
                                      tDoc: "${tdoc}",
                                      nDoc: "${value.trim()}",
                                    ));
                              }
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    child: inputField(
                      label: "A. Paterno",
                      focus: _focusPaterno,
                      Controller: textPaternoController,
                      onEditingComplete: () {},
                      onPressed: () async {},
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    child: inputField(
                      label: "A. Materno",
                      focus: _focusMaterno,
                      Controller: textMaternoController,
                      onEditingComplete: () {},
                      onPressed: () async {},
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    child: inputField(
                      label: "Nombres",
                      focus: _focusNombres,
                      Controller: textNombresController,
                      onEditingComplete: () {},
                      onPressed: () async {},
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    child: inputField(
                      label: "Cod Externo",
                      focus: _focusCodExt,
                      Controller: textCodExtController,
                      onEditingComplete: () {},
                      onPressed: () async {},
                      onChanged: (value) {},
                    ),
                  ),
                  SizedBox(height: 10),
                  BlocBuilder<ColaboradorBloc, ColaboradorState>(
                    builder: (context, state) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: DropdownMenu<String>(
                          label: Text("Empresa"),
                          width: MediaQuery.of(context).size.width * 0.92,
                          inputDecorationTheme: InputDecorationTheme(
                            isDense: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            constraints: BoxConstraints.tight(const Size.fromHeight(53)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          initialSelection: state.rpta == "1" ? state.initialEmpresa : "",
                          textStyle: TextStyle(
                            color: AppColors.mainBlueColor,
                          ),
                          onSelected: (String? value) {
                            if (value != null) {
                              setState(() {
                                idEmpresa = value;
                              });
                              context.read<ColaboradorBloc>().add(
                                    ListarAreas(
                                      CodOperacion: _usuario.codOperacion,
                                      usuario: "${_usuario.tipoDoc}${_usuario.numDoc}",
                                      idEmpresa: int.parse(value),
                                      initialArea: "",
                                    ),
                                  );
                            }
                          },
                          menuHeight: MediaQuery.of(context).size.height * 0.4,
                          menuStyle: MenuStyle(),
                          dropdownMenuEntries: state.listaEmpresas.map<DropdownMenuEntry<String>>((ColaboradorEmpresas value) {
                            return DropdownMenuEntry<String>(
                              value: value.id,
                              label: buildLabel(value.nombre),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  BlocBuilder<ColaboradorBloc, ColaboradorState>(
                    builder: (context, state) {
                      return Container(
                        child: DropdownMenu<String>(
                          label: Text("Area"),
                          width: MediaQuery.of(context).size.width * 0.92,
                          inputDecorationTheme: InputDecorationTheme(
                            isDense: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            constraints: BoxConstraints.tight(const Size.fromHeight(53)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          textStyle: TextStyle(
                            color: AppColors.mainBlueColor,
                          ),
                          initialSelection: state.rpta == "1"
                              ? state.initialArea
                              : state.listaAreas.length > 0
                                  ? state.listaAreas.first.id
                                  : "",
                          onSelected: (String? value) {
                            if (value != null) {
                              setState(() {
                                idArea = value;
                              });
                            }
                          },
                          dropdownMenuEntries: state.listaAreas.map<DropdownMenuEntry<String>>((ColaboradorAreas value) {
                            return DropdownMenuEntry<String>(
                              value: value.id,
                              label: buildLabel(value.nombre),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String buildLabel(String text) {
    final int maxLength = 33; // Longitud máxima permitida
    if (text.length <= maxLength) {
      return text; // Devolver el texto sin cambios si es corto
    } else {
      return text.substring(0, maxLength) + '...'; // Recortar y agregar puntos suspensivos si es largo
    }
  }

  AwesomeDialog MensajeAlert(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      autoHide: Duration(seconds: 2),
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      onDismissCallback: (type) async {},
    );
  }

  void _showDialogSincronizandoDatos(BuildContext context, String titulo) {
    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: AlertDialog(
                title: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mainBlueColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                //content: Text('...'),
                content: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Circular progress indicator',
                            color: AppColors.blueColor,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              onWillPop: () {
                return Future.value(false);
              });
        });
  }
}

class inputField extends StatelessWidget {
  const inputField({
    super.key,
    required FocusNode focus,
    required TextEditingController Controller,
    required void Function()? onPressed,
    required void Function()? onEditingComplete,
    required void Function(String)? onChanged,
    bool? isButton,
    required String label,
  })  : _focus = focus,
        _odometro = Controller,
        _onEditingComplete = onEditingComplete,
        _onChanged = onChanged,
        _onPressed = onPressed,
        _isButton = isButton,
        _label = label;

  final FocusNode? _focus;
  final TextEditingController? _odometro;
  final void Function()? _onPressed;
  final void Function()? _onEditingComplete;
  final void Function(String)? _onChanged;

  final bool? _isButton;
  final String _label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textAlign: TextAlign.start,
      focusNode: _focus,
      autofocus: true,
      controller: _odometro,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        label: Text(_label),
        isDense: true,
        suffixIcon: _isButton != null
            ? IconButton(
                onPressed: _onPressed,
                icon: Icon(
                  Icons.search,
                  size: 25,
                  color: AppColors.mainBlueColor,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.mainBlueColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.mainBlueColor,
            width: 1.5,
          ),
        ),
      ),
      onEditingComplete: _onEditingComplete,
      onChanged: _onChanged,
    );
  }
}
