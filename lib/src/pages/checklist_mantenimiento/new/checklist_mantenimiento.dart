import 'dart:async';
import 'package:embarques_tdp/src/models/check_list/checklist.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/new/checklist_detalle_mantenimiento.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class ChecklistMantenimientoPage extends StatefulWidget {
  final String titulo;
  final String descripcionVhlo;
  const ChecklistMantenimientoPage({super.key, required this.titulo, required this.descripcionVhlo});

  @override
  State<ChecklistMantenimientoPage> createState() => _ChecklistMantenimientoPageState();
}

class _ChecklistMantenimientoPageState extends State<ChecklistMantenimientoPage> {
  bool mostrarFiltros = false;
  bool mostrarObligatorios = false;

  String buscar = "";
  String filtroGrupo = "Todos";

  TextEditingController buscarCtrl = TextEditingController();
  String grupoActual = "";

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChecklistBloc, ChecklistState>(
      listener: (context, state) {
        if (state.statusGuardarEditarCheck == StatusGuardarEditarCheck.success) {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.pop(context);
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.greenColor,
              content: Text(
                state.guardarEditarCheck.mensaje,
                style: TextStyle(color: AppColors.whiteColor, fontSize: 18),
              ),
            ),
          );
        }

        if (state.statusGuardarEditarCheck == StatusGuardarEditarCheck.failure) {
          Navigator.pop(context);
          _showDialog("ERROR", state.guardarEditarCheck.mensaje, AppColors.redColor);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: BlocBuilder<ChecklistBloc, ChecklistState>(
            builder: (context, state) => Text("${widget.descripcionVhlo}  ${state.validarCheck.codVehiculo}"),
          ),
          centerTitle: true,
          backgroundColor: AppColors.mainBlueColor,
          actions: [
            IconButton(
              icon: Icon(
                mostrarObligatorios ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: () => setState(() => mostrarObligatorios = !mostrarObligatorios),
            ),
            IconButton(
              icon: Icon(
                mostrarFiltros ? Icons.filter_list : Icons.filter_list_outlined,
                color: Colors.white,
              ),
              onPressed: () => setState(() => mostrarFiltros = !mostrarFiltros),
            ),
          ],
        ),

        body: BlocBuilder<ChecklistBloc, ChecklistState>(
          builder: (
            context,
            state,
          ) {
            if (state.statuslista == statusLista.progress) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  color: AppColors.mainBlueColor,
                ),
              );
            }

            if (state.statuslista != statusLista.success) return Container();

            /// -----------------------------------------------------------
            /// 1) Separar sistemas y trabajos
            /// -----------------------------------------------------------
            final original = [...state.listaCheck];
            final sistemas = original.where((e) => e.orden == "0").toList();
            final trabajos = original.where((e) => e.orden != "0").toList();

            /// -----------------------------------------------------------
            /// 2) Aplicar filtros
            /// -----------------------------------------------------------
            List<CheckList> trabajosFiltrados = [...trabajos];

            if (buscar.trim().isNotEmpty) {
              final q = buscar.toLowerCase();
              trabajosFiltrados = trabajosFiltrados.where((t) => t.trabajo.toLowerCase().contains(q)).toList();
            }

            if (mostrarObligatorios) {
              trabajosFiltrados = trabajosFiltrados.where((t) => t.estadolike == 0).toList();
            }

            /// -----------------------------------------------------------
            /// 3) Sistemas visibles
            /// -----------------------------------------------------------
            final sistemasVisibles = sistemas.where((s) {
              return trabajosFiltrados.any((t) => t.sCod == s.sCod);
            }).toList();

            /// -----------------------------------------------------------
            /// 4) Filtro por sistema
            /// -----------------------------------------------------------
            if (filtroGrupo != "Todos") {
              final sistemaSel = sistemasVisibles.firstWhere((s) => s.trabajo == filtroGrupo);
              trabajosFiltrados = trabajosFiltrados.where((t) => t.sCod == sistemaSel.sCod).toList();
            }

            /// -----------------------------------------------------------
            /// 5) Reconstruir lista final
            /// -----------------------------------------------------------
            List<CheckList> listaFiltrada = [];

            for (final sistema in sistemasVisibles) {
              listaFiltrada.add(sistema);

              final listaTrab = trabajosFiltrados.where((t) => t.sCod == sistema.sCod);
              for (var t in listaTrab) {
                t.grupos = sistema.trabajo;
                listaFiltrada.add(t);
              }
            }

            /// -----------------------------------------------------------
            /// 6) Determinar motivo por el cual está vacía
            /// -----------------------------------------------------------
            bool tieneTrabajosReales = trabajos.isNotEmpty;

            if (listaFiltrada.isEmpty) {
              Widget mensaje;

              if (!tieneTrabajosReales) {
                mensaje = _mensaje("El checklist seleccionado no tiene trabajos asignados");
              } else if (mostrarObligatorios && buscar.isEmpty && filtroGrupo == "Todos") {
                mensaje = _mensaje("No hay trabajos obligatorios pendientes");
              } else {
                mensaje = _mensaje("No se encontraron resultados con los filtros aplicados");
              }

              return Center(child: mensaje);
            }

            /// -----------------------------------------------------------
            /// 7) Dropdown
            /// -----------------------------------------------------------
            List<String> grupos = [
              "Todos",
              ...sistemasVisibles.map((s) => s.trabajo),
            ];

            /// -----------------------------------------------------------
            /// 8) UI completa
            /// -----------------------------------------------------------
            return Column(
              children: [
                if (mostrarFiltros) _buildFiltros(grupos, widget.titulo),

                /// Cabecera
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  color: const Color(0xFFBDBDBD),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text("Verificar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text("Estado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.only(top: 0, bottom: 80),
                    itemCount: listaFiltrada.length,
                    separatorBuilder: (_, index) {
                      if (index == 0) return SizedBox.shrink();
                      return Divider(height: 1);
                    },
                    itemBuilder: (context, index) {
                      final post = listaFiltrada[index];

                      if (post.orden == "0") {
                        grupoActual = post.trabajo;
                        return Container(
                          color: Colors.grey.shade200,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          child: Text(
                            post.trabajo,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      post.grupos = grupoActual;

                      return StatefulBuilder(
                        builder: (context, setStateLocal) {
                          int localValue = post.estadolike;
                          return ChecklistItem(post: post);
                          // return ListTile(
                          //   contentPadding: EdgeInsets.only(left: 15, right: 5),
                          //   title: Row(
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     children: [
                          //       Expanded(
                          //         flex: 4,
                          //         child: Text(post.trabajo),
                          //       ),
                          //       Expanded(
                          //         flex: 2,
                          //         child: TripleStateSwitch(
                          //           value: localValue,
                          //           showQuestion: post.estadolike == 2 && post.guardado == false,
                          //           onChanged: (newValue) {
                          //             // 🔥 1) Actualiza UI sin tocar el bloc
                          //             setStateLocal(() => localValue = newValue);

                          //             // 🔥 2) Mantén la lógica que ya tenías
                          //             if (newValue == 1) {
                          //               context.read<ChecklistBloc>().add(LikeEvent(checkmodel: post));
                          //             } else if (newValue == 2) {
                          //               Navigator.push(
                          //                 context,
                          //                 MaterialPageRoute(
                          //                   builder: (_) => CheckListDetalleMantenimientoPage(checkList: post),
                          //                 ),
                          //               );
                          //             } else {
                          //               context.read<ChecklistBloc>().add(NoLikeNoCompletadoEvent(checkmodel: post));
                          //             }
                          //           },
                          //         ),
                          //       )
                          //     ],
                          //   ),
                          // );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),

        /// ---------------------------------------------------------------
        /// BOTONES INFERIORES
        /// ---------------------------------------------------------------
        floatingActionButton: Row(
          children: [
            Expanded(
              child: MaterialButton(
                height: 50,
                color: AppColors.whiteColor,
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancelar",
                  style: TextStyle(color: AppColors.mainBlueColor, fontSize: 18),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<ChecklistBloc, ChecklistState>(
                builder: (context, state) {
                  bool hayTrabajosReales = state.listaCheck.any((t) => t.orden != "0");

                  return MaterialButton(
                    height: 50,
                    color: hayTrabajosReales ? AppColors.mainBlueColor : Colors.grey.shade400,
                    disabledColor: Colors.grey.shade400,
                    onPressed: hayTrabajosReales
                        ? () {
                            _showDialogCargando(context, "Cargando...");
                            context.read<ChecklistBloc>().add(
                                  GuardarEditarCheckListEvent(
                                    usuario: Provider.of<UsuarioProvider>(context, listen: false).usuario,
                                  ),
                                );
                          }
                        : null,
                    child: Text("Guardar", style: TextStyle(color: Colors.white, fontSize: 18)),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  /// ---------------------------------------------------------
  /// WIDGETS AUXILIARES
  /// ---------------------------------------------------------
  Widget _mensaje(String texto) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 60, color: Colors.grey),
        SizedBox(height: 15),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltros(List<String> grupos, String titulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TITULO EXTERNO
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
        ),

        /// CONTENEDOR DE FILTROS
        Container(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.07),
              ),
            ],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TEXTO DE SECCIÓN
              Text(
                "Filtros",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),

              /// BUSCADOR
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: buscarCtrl,
                  style: TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Buscar trabajo...",
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
                    suffixIcon: buscar.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                            onPressed: () {
                              buscarCtrl.clear();
                              setState(() => buscar = "");
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onChanged: (v) => setState(() => buscar = v),
                ),
              ),

              SizedBox(height: 14),

              /// DROPDOWN
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: filtroGrupo,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down_rounded, size: 30),
                  items: grupos
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g, style: TextStyle(fontSize: 15)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => filtroGrupo = v ?? "Todos"),
                ),
              ),

              SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }

  void _showDialog(String titulo, String cuerpo, Color color) {
    showDialog(
      context: context,
      builder: (_) {
        // Timer(Duration(seconds: 2), () {
        //   if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        // });

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: color),
              SizedBox(width: 10),
              Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(cuerpo),
        );
      },
    );
  }

  void _showDialogCargando(BuildContext context, String titulo) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppColors.mainBlueColor),
      ),
    );
  }
}

class TripleStateSwitch extends StatefulWidget {
  final int value; // 0 = neutral, 1 = like, 2 = dislike
  final bool showQuestion;
  final Function(int) onChanged;

  const TripleStateSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.showQuestion = false,
  }) : super(key: key);

  @override
  State<TripleStateSwitch> createState() => _TripleStateSwitchState();
}

class _TripleStateSwitchState extends State<TripleStateSwitch> {
  // position: -1 = left, 0 = center, 1 = right
  late double dragPos;

  @override
  void initState() {
    super.initState();
    dragPos = widget.value == 2
        ? -1
        : widget.value == 1
            ? 1
            : 0;
  }

  @override
  void didUpdateWidget(covariant TripleStateSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      setState(() {
        dragPos = widget.value == 2
            ? -1
            : widget.value == 1
                ? 1
                : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double width = 130;
    const double height = 50;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showQuestion)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              "?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade500, width: 1.4),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              /// Indicadores de fondo
              Row(
                children: const [
                  Expanded(child: Center(child: Icon(Icons.thumb_down_alt_rounded, size: 18, color: Colors.red))),
                  Expanded(child: Center(child: Icon(Icons.remove_rounded, size: 20, color: Colors.grey))),
                  Expanded(child: Center(child: Icon(Icons.thumb_up_rounded, size: 18, color: Colors.green))),
                ],
              ),

              /// Áreas táctiles
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(onTap: () => _snapTo(-1)),
                  ),
                  Expanded(
                    child: GestureDetector(onTap: () => _snapTo(0)),
                  ),
                  Expanded(
                    child: GestureDetector(onTap: () => _snapTo(1)),
                  ),
                ],
              ),

              /// Bolita arrastrable
              AnimatedAlign(
                duration: Duration(milliseconds: 150),
                alignment: Alignment(dragPos, 0),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      dragPos += details.delta.dx / 40;
                      dragPos = dragPos.clamp(-1.2, 1.2);
                    });
                  },
                  onPanEnd: (details) {
                    double snap = dragPos;

                    if (snap <= -0.5)
                      snap = -1;
                    else if (snap >= 0.5)
                      snap = 1;
                    else
                      snap = 0;

                    _snapTo(snap);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: dragPos == 1
                          ? Colors.green
                          : dragPos == -1
                              ? Colors.red
                              : Colors.grey.shade600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Icon(
                      dragPos == 1
                          ? Icons.thumb_up_rounded
                          : dragPos == -1
                              ? Icons.thumb_down_alt_rounded
                              : Icons.remove_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _snapTo(double pos) {
    setState(() => dragPos = pos);

    int newValue = pos == -1
        ? 2
        : pos == 1
            ? 1
            : 0;
    widget.onChanged(newValue);
  }
}

class ChecklistItem extends StatefulWidget {
  final CheckList post;

  const ChecklistItem({super.key, required this.post});

  @override
  State<ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<ChecklistItem> {
  late int localValue;

  @override
  void initState() {
    super.initState();
    localValue = widget.post.estadolike;
  }

  @override
  void didUpdateWidget(covariant ChecklistItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.post.estadolike != localValue) {
      setState(() {
        localValue = widget.post.estadolike;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return ListTile(
      contentPadding: EdgeInsets.only(left: 15, right: 5),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text.rich(
              TextSpan(
                text: post.trabajo + " ",
                children: [
                  if (post.obligatorio)
                    TextSpan(
                      text: "*",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TripleStateSwitch(
              value: localValue,
              showQuestion: post.estadolike == 2 && !post.guardado,
              onChanged: (newValue) async {
                setState(() => localValue = newValue);

                if (newValue == 1) {
                  context.read<ChecklistBloc>().add(LikeEvent(checkmodel: post));
                } else if (newValue == 2) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckListDetalleMantenimientoPage(checkList: post),
                    ),
                  );

                  if (result == "cancelado") {
                    setState(() => localValue = 0);
                  }
                } else {
                  context.read<ChecklistBloc>().add(NoLikeNoCompletadoEvent(checkmodel: post));
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
