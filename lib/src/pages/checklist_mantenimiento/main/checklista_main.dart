import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/new/checklist_scan.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/edit/edit_checklist_scan.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class CheckListMainPage extends StatefulWidget {
  const CheckListMainPage({super.key});

  @override
  State<CheckListMainPage> createState() => _CheckListMainPageState();
}

class _CheckListMainPageState extends State<CheckListMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SafeArea(
        child: BlocBuilder<ChecklistBloc, ChecklistState>(
          builder: (context, state) {
            final tipos = state.listaTipoCheck; // viene de GET_TipoCheckList

            return CustomScrollView(
              primary: false,
              slivers: <Widget>[
                SliverAppBar(
                  shape: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.mainBlueColor,
                  pinned: true,
                  centerTitle: true,
                  leading: IconButton(
                    onPressed: () {
                      Log.insertarLogDomicilio(
                        context: context,
                        mensaje: "Navega a la pantalla de inicio",
                        rpta: "OK",
                      );
                      Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  title: Text("Check List"),
                ),

                // -------------------------------------------------------
                // 🔥 GRID DINÁMICO DE TIPOS DE CHECKLIST
                // -------------------------------------------------------
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid.count(
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 2,
                    children: tipos.isEmpty
                        ? [
                            Center(
                              child: Text(
                                "No hay tipos de checklist disponibles",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          ]
                        : tipos.map((t) {
                            return GestureDetector(
                              onTap: () {
                                // Guardar selección del tipo en UsuarioProvider
                                Provider.of<UsuarioProvider>(context, listen: false).setTipoListSelected(t.codigo);

                                // 👉 AQUÍ DECIDES A QUÉ PANTALLA NAVEGAR
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckListScanPage(tipoCheckListNombre: t.tipo),
                                  ),
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      child: FittedBox(
                                        child: Icon(checklistIcons[t.ico] ?? Icons.help_outline, size: 60, color: AppColors.mainBlueColor),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFe42313),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        t.tipo ?? "Sin nombre",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  final Map<String, IconData> checklistIcons = {
    "assistant": Icons.supervisor_account_outlined,
    "operations": Icons.fact_check,
    "maintenance": Icons.build_circle,
  };
}
