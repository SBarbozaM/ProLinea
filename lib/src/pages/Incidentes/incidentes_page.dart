import 'package:embarques_tdp/src/components/webview_basica.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:flutter/material.dart';
import '../../services/incidentes_service.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:embarques_tdp/src/models/Incidentes/incidente_model.dart';

import 'package:provider/provider.dart';

import '../../providers/providers.dart';
// import '../../providers/connection_status_provider.dart';

// import '../../utils/app_icons.dart';

class IncidentesPage extends StatefulWidget {
  @override
  _IncidentesPageState createState() => _IncidentesPageState();
}

class _IncidentesPageState extends State<IncidentesPage> {
  final IncidentesService apiService = IncidentesService();
  List<Incidente> incidentes = []; // Cambiar a List<Incidente>

  bool isLoading = true;
  String mensajeError = '';

  @override
  void initState() {
    super.initState();
    fetchIncidentes(0);
  }

  Future<void> fetchIncidentes([int numDias = 0]) async {
    setState(() {
      isLoading = true; // Muestra el indicador de carga
      mensajeError = ''; // Reinicia el mensaje de error
    });

    try {
      final List<Incidente> response = await apiService.getListaIncidentesNoti(Provider.of<UsuarioProvider>(context, listen: false).usuario.tipoDoc, Provider.of<UsuarioProvider>(context, listen: false).usuario.numDoc, numDias);
      if (response.isNotEmpty) {
        setState(() {
          incidentes = response;
          isLoading = false; // Oculta el indicador de carga
        });
      } else {
        setState(() {
          mensajeError = 'No hay incidentes';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        mensajeError = e.toString();
        isLoading = false;
      });
    }
  }

  Color hexToColor(Incidente incidente) {
    String hexd = incidente.color, hex = hexd.replaceAll("#", "");

    // Validar si el valor hexadecimal tiene 6 caracteres (para #RRGGBB)
    if (hex.length == 6 && RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      return Color(int.parse("FF$hex", radix: 16)); // Si es válido, asignar color con opacidad completa
    } else {
      return incidente.tipoNoti == 'Concluido' ? AppColors.blueColor : AppColors.redColor; // Si no es válido, asignar color negro
    }
  }

  Widget buildImageFromUrl(Incidente incidente) {
    // Verificar si incidente.icono es una URL válida
    if (incidente.icono != null && incidente.icono.startsWith('http')) {
      return FutureBuilder<bool>(
        future: apiService.isValidUrl(incidente.icono), // Validamos si la URL es válida
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Muestra un indicador mientras espera la respuesta
          } else if (snapshot.hasError || !snapshot.data!) {
            // Si ocurre un error o la URL no es válida, mostramos un ícono por defecto
            return Icon(
              Icons.notifications,
              color: AppColors.greyColor,
              size: 35,
            );
          } else {
            // Si la URL es válida, mostramos la imagen
            return Image.network(
              incidente.icono,
              width: 35,
              height: 35,
              fit: BoxFit.contain,
            );
          }
        },
      );
    } else {
      // Si incidente.icono no es una URL válida
      return Icon(
        incidente.tipoNoti == 'Concluido' ? Icons.description : Icons.warning,
        color: hexToColor(incidente),
        size: 35,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backColor,
      appBar: AppBar(
        title: Text('Alertas'),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list), // Ícono del menú de filtros
            offset: Offset(0, 40),
            onSelected: (String value) {
              int numDias = int.parse(value); // Convierte el valor seleccionado a int
              fetchIncidentes(numDias); //
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: '1', //Es 1 porque en el back lo resta 1, asi que  1-1 = 0 (Osea hoy)
                  child: Text('Hoy dia'),
                ),
                PopupMenuItem<String>(
                  value: '6',
                  child: Text('Desde 5 dias'),
                ),
                PopupMenuItem<String>(
                  value: '31',
                  child: Text('Desde 1 mes'),
                ),
                PopupMenuItem<String>(
                  value: '0',
                  child: Text('Todos'),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchIncidentes(0),
        color: AppColors.mainBlueColor,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                color: AppColors.mainBlueColor,
              ))
            : mensajeError.isNotEmpty
                ? Center(child: Text(mensajeError))
                : ListView.builder(
                    itemCount: incidentes.length,
                    itemBuilder: (context, index) {
                      final incidente = incidentes[index];
                      return GestureDetector(
                        onTap: () {

                          // // Obtener los datos de URL
                          // Map<String, dynamic> urlData = incidente.getUrlData();
                          // String tituloWeb = urlData['titulo_web'] ?? 'Sin título'; // Obtener el título web
                          // String appUrl = urlData['app_url'] ?? ''; // Obtener la URL de la app

                          // // Imprimir los valores obtenidos (opcional)
                          // print('Título Web: $tituloWeb');
                          // print('App URL: $appUrl');
                          final Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
                          if (incidente.idTipo == 40) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WebViewBasicaPage(
                                        url: '${incidente.url}&usuarioId=${usuario.tipoDoc}${usuario.numDoc}',
                                        titulo: incidente.tituloWeb,
                                        back: "irVerIncidentes",
                                      )),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WebViewBasicaPage(
                                        url: '${incidente.url}',
                                        titulo: incidente.tituloWeb,
                                        back: "irVerIncidentes",
                                      )),
                            );
                          }
                        },
                        child: Card(
                          elevation: 2, // Controla la sombra de la tarjeta
                          //  color: incidente.titulo != null && incidente.titulo!.contains('Conclusión') ? Color.fromARGB(255, 243, 207, 207) :  Color.fromARGB(255, 243, 207, 207)
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Espacio entre tarjetas
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  //mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    //  Icon(Icons.notifications),
                                    Expanded(
                                      child: Text(
                                        incidente.titulo ?? 'Sin título', //thi dnn   f1c232
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: hexToColor(incidente),
                                        ),
                                      ),
                                    ),

                                    Container(
                                      child: buildImageFromUrl(incidente), // Aquí se pasa el incidente para cargar la imagen
                                    ),

                                    // Icon(
                                    //   /// incidente.tipoNoti == 'Concluido' ? Icons.description :

                                    //   getIconFromName(incidente.icono),
                                    //   color: hexToColor(incidente.color),
                                    //   size: 35,
                                    // ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text(incidente.contenido.replaceAll(r'\n', '\n') ?? 'Sin contenido', style: TextStyle(fontSize: 18), softWrap: true),
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    incidente.fecha ?? '',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
