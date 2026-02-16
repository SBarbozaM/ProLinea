import 'package:embarques_tdp/src/models/control_ingreso.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/controlador_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ControlIngresoLista extends StatefulWidget {
  const ControlIngresoLista({super.key});

  @override
  State<ControlIngresoLista> createState() => _ControlIngresoListaState();
}

class _ControlIngresoListaState extends State<ControlIngresoLista> {

  @override
  void initState() {
    super.initState();
    ControlSalidaListar();
  }

  List<ControlIngresoUsuario> listaControlSalida = [];
  List<ControlIngresoUsuario> listaControlSalidaBase = [];

  ControlSalidaListar() async {
    final nDocUsuario = Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc;
    ControladorServicio controladorServicio = ControladorServicio();
    listaControlSalida = await controladorServicio.ListarControlIngresoUsuario(
      idAndroid: Provider.of<UsuarioProvider>(context, listen: false).idDispositivo,
      DocUsuario: nDocUsuario,
    );
    listaControlSalidaBase = listaControlSalida;
    setState(() {});
  }

  Future<List<ControlIngresoUsuario>> BuscarControlNombre(String query) async {
    final newList = listaControlSalidaBase.where((control) {
      final nombre = "${control.apellidoP} ${control.apellidoM} ${control.nombre}".toLowerCase();
      final input = query.toLowerCase();
      return nombre.contains(input);
    }).toList();
    return newList;
  }

  Future<List<ControlIngresoUsuario>> BuscarControlPlaca(String query) async {
    final newList = listaControlSalidaBase.where((control) {
      final placa = "${control.placa}".toLowerCase();
      final input = query.toLowerCase();
      return placa.contains(input);
    }).toList();
    return newList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mis Llegadas",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.mainBlueColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.mainBlueColor,
                  ),
                ),
                isDense: true,
                hintText: "Buscar",
              ),
              onChanged: (value) async {
                final nombreList = await BuscarControlNombre(value);
                final placaList = await BuscarControlPlaca(value);

                final union = [...nombreList, ...placaList];
                setState(() {
                  listaControlSalida = union;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: ListView.builder(
                itemCount: listaControlSalida.length,
                itemBuilder: (context, index) {
                  ControlIngresoUsuario csUsuario = listaControlSalida[index];
                  var conductor = "";
                  var unidad = "";
                  if (csUsuario.obs.contains("|")) {
                    var obs = csUsuario.obs.split("|");
                    conductor = obs[0].split("/")[1];
                    unidad = obs[1].split("/")[1];
                  } else {
                    conductor = csUsuario.obs;
                    unidad = csUsuario.obs;
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 5),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              alignment: Alignment.centerLeft,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 2,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              child: Text(
                                "${csUsuario.fecha}",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                    child: Container(
                                      child: Row(
                                        children: [
                                          Material(
                                            color: AppColors.mainBlueColor,
                                            borderRadius: BorderRadius.circular(50),
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              padding: EdgeInsets.all(7),
                                              child: Image(
                                                image: AssetImage('assets/icons/busLinea-icon.png'),
                                                width: 30,
                                                height: 30,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Container(
                                            padding: EdgeInsets.only(top: 3),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${csUsuario.placa}",
                                                  style: TextStyle(
                                                    color: AppColors.mainBlueColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                SizedBox(height: 3),
                                                Container(width: MediaQuery.of(context).size.width * 0.7, child: Text("${unidad}")),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Divider(color: Colors.grey, height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                    child: Container(
                                      child: Row(
                                        children: [
                                          Material(
                                            color: AppColors.mainBlueColor,
                                            borderRadius: BorderRadius.circular(50),
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              padding: EdgeInsets.all(3),
                                              child: Image(
                                                image: AssetImage('assets/icons/driver_icon.png'),
                                                width: 30,
                                                height: 30,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Container(
                                            padding: EdgeInsets.only(top: 3),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${csUsuario.apellidoP} ${csUsuario.apellidoM}, ${csUsuario.nombre}",
                                                  style: TextStyle(
                                                    color: AppColors.mainBlueColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                SizedBox(height: 3),
                                                Container(
                                                  width: MediaQuery.of(context).size.width * 0.7,
                                                  child: Text(
                                                    "${conductor}",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
