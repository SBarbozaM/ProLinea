import 'package:embarques_tdp/src/pages/rutas/ruta_detalle_page.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/programacion.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:embarques_tdp/src/models/programacion/programacion_model.dart';
import 'package:provider/provider.dart';

enum statusListaProgramacion { initial, success, failure, progress }

class ProgramacionPage extends StatefulWidget {
  const ProgramacionPage({Key? key}) : super(key: key);

  @override
  _ProgramacionPageState createState() => _ProgramacionPageState();
}

class _ProgramacionPageState extends State<ProgramacionPage> {
  statusListaProgramacion status = statusListaProgramacion.initial;

  ProgramacionModel programacionModel = ProgramacionModel(
    rpta: "",
    mensaje: "",
    programacion: [],
  );

  @override
  void initState() {
    super.initState();
    _obtenerProgramacion(
      Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc,
      Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc,
    );
  }

  _obtenerProgramacion(String tipoDoc, String numDoc) async {
    ProgramacionServicio sProgramacion = ProgramacionServicio();

    setState(() {
      status = statusListaProgramacion.progress;
    });

    programacionModel = await sProgramacion.listarProgramacion(tipoDoc, numDoc);

    if (programacionModel.rpta != "0") {
      setState(() {
        status = statusListaProgramacion.failure;
      });
      return;
    }

    if (programacionModel.rpta == "0") {
      setState(() {
        status = statusListaProgramacion.success;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: AppColors.mainBlueColor,
        title: Text('Mi Programación'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Builder(builder: (context) {
        if (status == statusListaProgramacion.progress) {
          return Container(
            padding: EdgeInsets.only(top: 10),
            alignment: Alignment.topCenter,
            child: CircularProgressIndicator(
              color: AppColors.mainBlueColor,
            ),
          );
        }
        if (status == statusListaProgramacion.success) {
          if (programacionModel.programacion.isEmpty) {
            return Center(
              child: Text(
                'No tienes ninguna programación',
                style: TextStyle(fontSize: 18, color: AppColors.blackColor),
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(5),
            child: ListView.separated(
              itemCount: programacionModel.programacion.length,
              separatorBuilder: (context, index) {
                return Container(
                  height: 5,
                );
              },
              itemBuilder: (context, index) {
                final programacion = programacionModel.programacion[index];

                return Material(
                  borderRadius: BorderRadius.circular(8),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      final hasMapa = (programacion.mapa ?? '').trim().isNotEmpty;
                      if (hasMapa) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RutaDetailPage(
                              titulo: programacion.ruta,
                              descripcion: programacion.camino,
                              urlMapa: programacion.mapa,
                            ),
                          ),
                        );
                      } else {
                        // Mensaje opcional si no hay mapa
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No hay mapa disponible para esta ruta')),
                        );
                      }
                    },
                    child: Container(
                        padding: EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  programacion.salida,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    color: AppColors.blackColor,
                                  ),
                                ),
                                Container(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.directions_bus, size: 20, color: AppColors.redColor),
                                          SizedBox(width: 5),
                                          Text(
                                            programacion.bus,
                                            style: TextStyle(fontSize: 23),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            // SizedBox(width: 0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.route, color: AppColors.mainBlueColor, size: 28),
                                      const SizedBox(width: 4),
                                      Text(
                                        programacion.ruta,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: AppColors.mainBlueColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Columna de iconos
                                  Column(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: Colors.blue, size: 25),
                                      Container(
                                        width: 2,
                                        height: 20,
                                        color: Colors.grey[300],
                                      ),
                                      const Icon(Icons.location_on_rounded, color: Colors.red, size: 25),
                                    ],
                                  ),
                                  const SizedBox(width: 12),

                                  // Columna de texto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(programacion.inicio, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text('Inicio', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(programacion.h_Salida, style: const TextStyle(fontSize: 23, color: AppColors.greenColor, fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 15),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(programacion.fin, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text('Fin', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(programacion.h_Llegada, style: TextStyle(fontSize: 23, color: AppColors.greenColor, fontWeight: FontWeight.bold)),
                                                  SizedBox(width: 15),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Text(programacion.fin, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        // const SizedBox(height: 4),
                                        // Text('Fin: 01:00', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Text(
                                  'Servicio: ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  programacion.servicio,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700], // o cualquier color que encaje con tu tema
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (programacion.nombreConductor2 != "" || programacion.nombreAuxiliarViaje != "")
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        programacion.desplegable = !programacion.desplegable;
                                      });
                                    },
                                    icon: Icon(
                                      programacion.desplegable ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.blackColor,
                                      size: 22,
                                    ),
                                    label: const Text(
                                      'Tripulantes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 0.7,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.black, // color del ripple
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    ),
                                  ),
                                ],
                              ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (programacion.desplegable == true) Text(programacion.nombreConductor1, style: TextStyle(fontSize: 18)),
                                if (programacion.desplegable == true) Text(programacion.nombreConductor2, style: TextStyle(fontSize: 18)),
                                if (programacion.desplegable == true) Text(programacion.nombreAuxiliarViaje, style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        )),
                  ),
                );
              },
            ),
          );
        }

        if (status == statusListaProgramacion.failure) {
          return Container(
            child: Text(programacionModel.mensaje),
          );
        }

        return Container();
      }),
    );
  }
}
