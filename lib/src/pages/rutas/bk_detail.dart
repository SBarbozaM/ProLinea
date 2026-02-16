import 'package:embarques_tdp/src/models/rutas/ruta_listar.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RutaDetailPage extends StatefulWidget {
  final RutaListar ruta;

  const RutaDetailPage({Key? key, required this.ruta}) : super(key: key);

  @override
  _RutaDetailPageState createState() => _RutaDetailPageState();
}

class _RutaDetailPageState extends State<RutaDetailPage> {
  late InAppWebViewController _webViewController;
  double _loadingProgress = 0;
  bool _showFullPath = true;

  List<String> _dividirCamino(String camino) {
    return camino.split('-').map((parte) => parte.trim()).where((parte) => parte.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final partesCamino = _dividirCamino(widget.ruta.camino);
    final partesParaMostrar = _showFullPath ? partesCamino : partesCamino.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Ruta ${widget.ruta.origen} ${widget.ruta.destino}'),
        backgroundColor: AppColors.mainBlueColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webViewController.reload();
            },
          ),
        ],
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          // Sección de información de la ruta
          /* Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Text(
                  //   'Camino:',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //     color: AppColors.mainBlueColor,
                  //   ),
                  // ),

                  Wrap(
                    spacing: 1.0, // Espacio horizontal entre elementos
                    runSpacing: 8.0, // Espacio vertical entre líneas
                    children: [
                      for (int i = 0; i < partesParaMostrar.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          decoration: BoxDecoration(
                            color: i == 0 ? Colors.green[50] : (i == partesParaMostrar.length - 1 ? Colors.red[50] : Colors.blue[50]),
                            borderRadius: BorderRadius.circular(20),
                            // border: Border.all(
                            //   color: i == 0 ? Colors.green : (i == partesParaMostrar.length - 1 ? Colors.red : AppColors.mainBlueColor),
                            //   width: 1.5,
                            // ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icono según la posición
                              //if (i == 0) const Icon(Icons.my_location, color: Colors.green, size: 16) else if (i == partesParaMostrar.length - 1) const Icon(Icons.location_on, color: Colors.red, size: 16) else const Icon(Icons.fiber_manual_record, color: AppColors.mainBlueColor, size: 12),

                              //const SizedBox(width: 6),

                              // Texto del punto
                              Text(
                                partesParaMostrar[i],
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 0.7,
                                  //fontWeight: FontWeight.w500,
                                  color: i == 0 ? Colors.green[800] : (i == partesParaMostrar.length - 1 ? Colors.red[800] : AppColors.mainBlueColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),  
                  //),

                  ///const SizedBox(height: 16),

                  // Botón para ver menos (si estamos mostrando todo)
                  // if (_showFullPath)
                  //   Center(
                  //     child: TextButton(
                  //       onPressed: () {
                  //         setState(() {
                  //           _showFullPath = false;
                  //         });
                  //       },
                  //       child: const Text(
                  //         'Ver menos',
                  //         style: TextStyle(
                  //           color: AppColors.mainBlueColor,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ),

                  // const SizedBox(height: 8),
                  // Text(widget.ruta.camino),
                  const SizedBox(height: 16),
                  if (_loadingProgress < 1.0)
                    LinearProgressIndicator(
                      value: _loadingProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.mainBlueColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
           */
          Expanded(
            flex: 3,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.ruta.mapa)),
              onWebViewCreated: (InAppWebViewController controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _loadingProgress = 0;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _loadingProgress = 1.0;
                });
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _loadingProgress = progress / 100;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
