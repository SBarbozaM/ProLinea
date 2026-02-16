import 'package:embarques_tdp/src/models/orden_servicio/os_orden_servicio.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_requerimientos_unidad.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_trabajos_unidad.dart';
import 'package:embarques_tdp/src/services/ordenServicio_service.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetalleOrdenServicioJefaturaPage extends StatefulWidget {
  final OsOrden orden;

  const DetalleOrdenServicioJefaturaPage({Key? key, required this.orden}) : super(key: key);

  @override
  State<DetalleOrdenServicioJefaturaPage> createState() => _DetalleOrdenServicioJefaturaPageState();
}

class _DetalleOrdenServicioJefaturaPageState extends State<DetalleOrdenServicioJefaturaPage> {
  List<OsRequerimientos> listaRequerimientos = [];
  List<OsTrabajos> listaTrabajos = [];

  bool loadingRequerimientos = false;
  bool loadingTrabajos = false;

  @override
  void initState() {
    super.initState();
    ListarRequerimientos();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Orden Servicio"),
        centerTitle: true,
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Log.insertarLogDomicilio(context: context, mensaje: "Navega a la lista de orden de servicio", rpta: "OK");
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
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
                                    "${widget.orden.codVeh}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.home,
                                    size: 22,
                                    color: AppColors.mainBlueColor,
                                  ),
                                  Text(
                                    " : ",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: AppColors.mainBlueColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${widget.orden.operacion}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                ],
                              ),
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
                                    "${widget.orden.nro}",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: AppColors.blackColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_tree_rounded,
                                    size: 22,
                                    color: AppColors.mainBlueColor,
                                  ),
                                  Text(
                                    " : ",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: AppColors.mainBlueColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${widget.orden.tipoGasto}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              child: Row(
                                children: [
                                  Text(
                                    "Taller : ",
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
                                    "${widget.orden.taller}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                    "${widget.orden.fechaEntrada} ${widget.orden.horaEntrada}",
                                    style: TextStyle(
                                      fontSize: 16,
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
                ],
              ),
            ),
            Container(
              width: width - 10,
              height: height * 0.25,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: (width * 0.1),
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        width: (width * 0.90) - 10,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          border: Border(
                            left: BorderSide(
                              width: 1,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        child: Text(
                          "Requerimiento",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.mainBlueColor,
                          ),
                        ),
                      ),
                      // Container(
                      //   alignment: Alignment.center,
                      //   width: (width * 0.25) - 10,
                      //   height: 40,
                      //   decoration: BoxDecoration(
                      //     color: Colors.grey.shade300,
                      //     border: Border(
                      //       left: BorderSide(
                      //         width: 1,
                      //         color: Colors.grey.shade500,
                      //       ),
                      //     ),
                      //   ),
                      //   child: Text(
                      //     "Tipo",
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.bold,
                      //       fontSize: 17,
                      //       color: AppColors.mainBlueColor,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  loadingRequerimientos
                      ? Container(
                          width: 80,
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.mainBlueColor,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Expanded(
                          child: Container(
                            width: width - 10,
                            child: ListView.builder(
                              physics: BouncingScrollPhysics(),
                              itemCount: listaRequerimientos.length,
                              itemBuilder: (context, index) {
                                OsRequerimientos requerimiento = listaRequerimientos[index];

                                return GestureDetector(
                                  onTap: () {
                                    ListarTrabajos(requerimiento);
                                    setState(() {
                                      loadingTrabajos = true;
                                      requerimiento.selecionado = true;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        alignment: Alignment.center,
                                        width: (width * 0.1),
                                        height: 60,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                          color: requerimiento.selecionado ? AppColors.mainBlueColor : Colors.white,
                                        ),
                                        child: Icon(
                                          Icons.calendar_month_rounded,
                                          size: 30,
                                          color: requerimiento.selecionado ? AppColors.whiteColor : Colors.black,
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        width: (width * 0.90) - 10,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                          color: requerimiento.selecionado ? AppColors.mainBlueColor : Colors.white,
                                        ),
                                        child: Text(
                                          requerimiento.trabajoVerificacion,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: requerimiento.selecionado ? AppColors.whiteColor : Colors.black,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Container(
                                      //   alignment: Alignment.center,
                                      //   width: (width * 0.25) - 10,
                                      //   height: 40,
                                      //   decoration: BoxDecoration(
                                      //     border: Border.all(
                                      //       color: Colors.grey.shade300,
                                      //       width: 1,
                                      //     ),
                                      //   ),
                                      //   child: Text(
                                      //     "Preventivo",
                                      //     style: TextStyle(
                                      //       fontSize: 15,
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: width,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: (width) - 10,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "Trabajo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.mainBlueColor,
                            ),
                          ),
                        ),
                        // Container(
                        //   alignment: Alignment.center,
                        //   width: width * 0.15,
                        //   height: 40,
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey.shade300,
                        //     border: Border(
                        //       left: BorderSide(
                        //         width: 1,
                        //         color: Colors.grey.shade500,
                        //       ),
                        //     ),
                        //   ),
                        //   child: Text(
                        //     "Terce",
                        //     style: TextStyle(
                        //       fontWeight: FontWeight.bold,
                        //       fontSize: 17,
                        //       color: AppColors.mainBlueColor,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                    loadingTrabajos
                        ? Container(
                            width: 80,
                            height: 60,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.mainBlueColor,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Expanded(
                            child: Container(
                              width: width - 10,
                              child: ListView.builder(
                                physics: BouncingScrollPhysics(),
                                itemCount: listaTrabajos.length,
                                itemBuilder: (context, index) {
                                  OsTrabajos trabajos = listaTrabajos[index];

                                  return Row(
                                    children: [
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.symmetric(horizontal: 5),
                                        width: (width) - 10,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          trabajos.trabajo,
                                          style: TextStyle(
                                            fontSize: 18,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Container(
                                      //   alignment: Alignment.center,
                                      //   width: width * 0.15,
                                      //   height: 40,
                                      //   decoration: BoxDecoration(
                                      //     border: Border.all(
                                      //       color: Colors.grey.shade300,
                                      //       width: 1,
                                      //     ),
                                      //   ),
                                      //   child: Transform.scale(
                                      //     scale: 1.3,
                                      //     child: Checkbox(
                                      //       checkColor: AppColors.whiteColor,
                                      //       activeColor: AppColors.mainBlueColor,
                                      //       value: false,
                                      //       onChanged: (value) {},
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  ListarRequerimientos() async {
    setState(() {
      loadingRequerimientos = true;
    });
    OrdenServicioService sOrden = OrdenServicioService();
    OsRequerimientosUnidad requeResponse = await sOrden.BuscarProblemasUnidad_Jefatura(CodVeh: widget.orden.codVeh, CodPro: widget.orden.codPro.toString());

    if (requeResponse.rpta == '0') {
      setState(() {
        listaRequerimientos = requeResponse.lista;
        loadingRequerimientos = false;
      });
    } else {
      loadingRequerimientos = false;
    }
  }

  ListarTrabajos(OsRequerimientos orden) async {
    OrdenServicioService sOrden = OrdenServicioService();
    OsTrabajosUnidad trabaResponse = await sOrden.Listar_BuscarTrabajosRegistrados_Jefatura(NroOS: widget.orden.nro.toString(), taller: widget.orden.codTaller, CodPro: orden.pro.toString());

    if (trabaResponse.rpta == '0') {
      setState(() {
        loadingTrabajos = false;
        listaTrabajos = trabaResponse.lista;
      });
    } else {
      loadingTrabajos = false;
    }
  }
}
