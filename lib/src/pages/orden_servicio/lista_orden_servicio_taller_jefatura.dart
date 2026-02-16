import 'package:embarques_tdp/src/models/orden_servicio/os_orden_servicio.dart';
import 'package:embarques_tdp/src/models/orden_servicio/os_requerimientos_unidad.dart';
import 'package:embarques_tdp/src/pages/orden_servicio/detalle_orden_servicio_jefatura.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListaOrdenServicioTallerJefatura extends StatefulWidget {
  final OsOrdenServicio ordenes;

  const ListaOrdenServicioTallerJefatura({Key? key, required this.ordenes}) : super(key: key);

  @override
  State<ListaOrdenServicioTallerJefatura> createState() => _ListaOrdenServicioTallerJefaturaState();
}

class _ListaOrdenServicioTallerJefaturaState extends State<ListaOrdenServicioTallerJefatura> {
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
        title: Text("Lista de orden de servicio"),
        centerTitle: true,
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Log.insertarLogDomicilio(context: context, mensaje: "Navega a la pantalla de inicio", rpta: "OK");
            Navigator.of(context).pushNamedAndRemoveUntil('ordenServicioTalleres', (Route<dynamic> route) => false);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListView.builder(
          itemCount: widget.ordenes.lista.length,
          itemBuilder: (context, index) {
            OsOrden osOrden = widget.ordenes.lista[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => DetalleOrdenServicioJefaturaPage(
                      orden: osOrden,
                    ),
                  ),
                );
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
                                      "${osOrden.codVeh}",
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
                                      "${osOrden.operacion}",
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
                                      "${osOrden.nro}",
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
                                      "${osOrden.tipoGasto}",
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
                                      "${osOrden.taller}",
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
                                      "${osOrden.fechaEntrada} ${osOrden.horaEntrada}",
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
                    Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // listarOrdenesServicio() async {
  //   if (taller != null) {
  //     OrdenServicioService sOrden = OrdenServicioService();
  //     OsRequerimientosUnidad requeResponse = await sOrden.ListaOrdenesServicio(Taller: taller!, Placa: "C0V966");

  //     if (requeResponse.rpta == '0') {
  //       setState(() {
  //         listaOrdenesServicio = requeResponse.lista;
  //       });
  //     } else {}
  //   }
  // }

  // obtenerTaller() async {
  //   OrdenServicioService sOrden = OrdenServicioService();
  //   Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

  //   OsObtenerTaller tallerResponse = await sOrden.ObtenerTaller(tdoc: usuario.tipoDoc, ndoc: usuario.numDoc);

  //   if (tallerResponse.rpta == '0') {
  //     setState(() {
  //       taller = tallerResponse.tallerCordigo;
  //     });
  //   } else {
  //     setState(() {
  //       taller = null;
  //     });
  //   }
  // }
}
