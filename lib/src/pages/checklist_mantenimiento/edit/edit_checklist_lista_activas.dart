import 'package:embarques_tdp/src/models/check_list/validar_edit_checkList.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_requerimientos_unidad.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/new/checklist_mantenimiento.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class EditChecklistListaActivas extends StatefulWidget {
  final String placa;
  const EditChecklistListaActivas({Key? key, required this.placa}) : super(key: key);

  @override
  State<EditChecklistListaActivas> createState() => _EditChecklistListaActivasState();
}

class _EditChecklistListaActivasState extends State<EditChecklistListaActivas> {
  List<OsRequerimientos> listaOrdenesServicio = [];
  String? taller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Lista hoja de servicio"),
        centerTitle: true,
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla de inicio", rpta: "OK");
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: BlocBuilder<ChecklistBloc, ChecklistState>(
          builder: (context, state) {
            return Container(
              height: double.infinity,
              child: ListView.builder(
                itemCount: state.listaHojaServicio.length,
                itemBuilder: (context, index) {
                  HojaServicio check = state.listaHojaServicio[index];

                  return GestureDetector(
                    onTap: () {
                      context.read<ChecklistBloc>().add(
                            ListarCheckListEvent(hoseCode: check.hosECodigo, tDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc, nDoc: Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc, placa: widget.placa, tipoCheckList: Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoListSelected ?? 0),
                          );
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => ChecklistMantenimientoPage(),
                      //   ),
                      // );
                    },
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 2),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      height: height * 0.16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.car_repair,
                                            size: 26,
                                            color: AppColors.mainBlueColor,
                                          ),
                                          Text(
                                            " : ",
                                            style: TextStyle(
                                              fontSize: 22,
                                              color: AppColors.mainBlueColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${check.coDVehiculo}",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: AppColors.blackColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // SizedBox(width: MediaQuery.of(context).size.width * 0.2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 25,
                                          height: 25,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.greenColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            "${check.iteMBaja}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Container(
                                          width: 25,
                                          height: 25,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.amberColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            "${check.iteMMedia}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Container(
                                          width: 25,
                                          height: 25,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.redColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            "${check.iteMAlta}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 22,
                                            color: AppColors.mainBlueColor,
                                          ),
                                          Text(
                                            " : ",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: AppColors.mainBlueColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${check.hosECodigo}",
                                            style: TextStyle(
                                              fontSize: 19,
                                              color: AppColors.blackColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      child: Text(
                                        "${check.tipo == 'P' ? 'PARTIDA' : 'FINAL'}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      child: Row(
                                        children: [
                                          Text(
                                            "Fecha ingreso : ",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: AppColors.mainBlueColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      child: Row(
                                        children: [
                                          Text(
                                            "${check.feCRep}",
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: AppColors.blackColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
