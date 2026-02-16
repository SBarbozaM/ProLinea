import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class RutaDetailPage extends StatefulWidget {
  //final RutaListar ruta;
  final String titulo;
  final String descripcion;
  final String urlMapa;

  const RutaDetailPage({Key? key, required this.titulo, required this.descripcion, required this.urlMapa}) : super(key: key);

  @override
  _RutaDetailPageState createState() => _RutaDetailPageState();
}

class _RutaDetailPageState extends State<RutaDetailPage> {
  late InAppWebViewController _webViewController;
  double _loadingProgress = 0;
  double _panelHeight = 90.0;
  final double _minPanelHeight = 90.0;
  final double _maxPanelHeight = 0.9;
  bool _isPanelExpanded = false;
  bool _isExiting = false;
  //bool _esvacio = false;

  List<String> _dividirCamino(String camino) {
    //final normalizado = camino.replaceAll('–', '-').replaceAll('—', '-').replaceAll('−', '-');
    return camino.split('|').map((parte) => parte.trim()).where((parte) => parte.isNotEmpty).toList();
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;

    try {
      // 1. Detener todas las cargas del WebView
      await _webViewController.stopLoading();

      // 2. Opcional: Limpiar el contenido
      await _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));

      setState(() {
        _isExiting = true;
      });

      // 3. Pequeña pausa para que se complete la limpieza
      await Future.delayed(Duration(milliseconds: 300));

      // 4. Navegar de regreso
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Si hay error, navegar de todas formas
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    // Limpiar recursos cuando el widget se destruye
    _webViewController.stopLoading();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partesCamino = _dividirCamino(widget.descripcion);
    final partesParaMostrar = partesCamino;
    final maxHeight = MediaQuery.of(context).size.height * _maxPanelHeight;

    ///final _esvacio  = _
    //final rawUrl = (widget.urlMapa ?? '').trim();

    return Scaffold(
      appBar: null, // Eliminamos la AppBar tradicional
      body: Stack(
        children: [
          // WebView como fondo
          if (!_isExiting)
            Positioned(
              top: 90,
              bottom: 0,
              left: 0,
              right: 0,
              child: widget.urlMapa != ''
                  ? Opacity(
                      opacity: _isExiting ? 0.7 : 1.0,
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(widget.urlMapa)),
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                        },

                        // Intercepta navegación
                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                          final uri = navigationAction.request.url;
                          if (uri == null) return NavigationActionPolicy.ALLOW;

                          final urlString = uri.toString();
                          final scheme = uri.scheme?.toLowerCase();

                          // Permitir http/https
                          if (scheme == 'http' || scheme == 'https') {
                            return NavigationActionPolicy.ALLOW;
                          }
                          try {
                            if (urlString.startsWith('intent://')) {
                              final fallbackMatch = RegExp(r'browser_fallback_url=([^;]+)').firstMatch(urlString);
                              if (fallbackMatch != null) {
                                final fallback = Uri.decodeComponent(fallbackMatch.group(1)!);
                                if (await canLaunchUrl(Uri.parse(fallback))) {
                                  await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication);
                                  return NavigationActionPolicy.CANCEL;
                                }
                              }

                              // si no hay fallback, cancelar o abrir por intent mediante platform channel (opcional)
                              return NavigationActionPolicy.CANCEL;
                            }

                            // 2) geo: y otros esquemas geo: -> abrir externamente
                            if (scheme == 'geo') {
                              final uriToLaunch = Uri.parse(urlString);
                              if (await canLaunchUrl(uriToLaunch)) {
                                await launchUrl(uriToLaunch, mode: LaunchMode.externalApplication);
                                return NavigationActionPolicy.CANCEL;
                              }
                            }

                            // 3) comgooglemaps:// o restricciones de apps -> intentar abrir externamente
                            final toLaunch = Uri.parse(urlString);
                            if (await canLaunchUrl(toLaunch)) {
                              await launchUrl(toLaunch, mode: LaunchMode.externalApplication);
                              return NavigationActionPolicy.CANCEL;
                            }
                          } catch (e) {
                            // fallo al lanzar: cancelar navegación
                            return NavigationActionPolicy.CANCEL;
                          }

                          // por defecto cancela para evitar ERR_UNKNOWN_URL_SCHEME
                          return NavigationActionPolicy.CANCEL;
                        },

                        onLoadStart: (controller, url) {
                          if (!_isExiting) setState(() => _loadingProgress = 0);
                        },
                        onLoadStop: (controller, url) {
                          if (!_isExiting) setState(() => _loadingProgress = 1.0);
                        },
                        onProgressChanged: (controller, progress) {
                          if (!_isExiting) setState(() => _loadingProgress = progress / 100);
                        },
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Sin Mapa o URL no válida',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

          if (!_isExiting && _loadingProgress < 1.0)
            Positioned(
              top: _minPanelHeight, // justo debajo del panel superior
              left: 0,
              right: 0,
              child: SizedBox(
                height: 4, // altura de la barra
                child: LinearProgressIndicator(
                  value: _loadingProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mainBlueColor),
                ),
              ),
            ),

          // Panel superior personalizado con funcionalidad de AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: _panelHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_isPanelExpanded ? 24 : 0),
                  bottomRight: Radius.circular(_isPanelExpanded ? 24 : 0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Barra de control (siempre visible)
                  Container(
                    height: _minPanelHeight,
                    padding: EdgeInsets.only(top: 28, left: 16, right: 16),
                    child: Row(
                      children: [
                        // Botón de retroceso
                        GestureDetector(
                          //onTap: () => Navigator.of(context).pop(),
                          onTap:
                              // Pequeña pausa antes de navegar
                              ///await Future.delayed(Duration(milliseconds: 50));
                              _isExiting ? null : _handleExit,

                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.mainBlueColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: _isExiting
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.mainBlueColor,
                                  ) // ← Indicador de carga
                                : const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: AppColors.mainBlueColor,
                                  ),
                          ),
                        ),

                        SizedBox(width: 12),

                        // Título
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ruta ${widget.titulo}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${partesCamino.length} puntos intermedios',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Botones de acción
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _webViewController.reload(),
                              // onTap: () async {
                              //   // Pequeña pausa antes de navegar
                              //   await Future.delayed(Duration(milliseconds: 50));
                              //   if (mounted) {
                              //     Navigator.of(context).pop();
                              //   }
                              // },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.mainBlueColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: AppColors.mainBlueColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_isPanelExpanded) {
                                    _panelHeight = _minPanelHeight;
                                  } else {
                                    _panelHeight = maxHeight;
                                  }
                                  _isPanelExpanded = !_isPanelExpanded;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.mainBlueColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPanelExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: AppColors.mainBlueColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Contenido expandido
                  if (_isPanelExpanded)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Puntos de la ruta:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16),
                            ...List.generate(partesParaMostrar.length, (index) {
                              final bool isFirst = index == 0;
                              final bool isLast = index == partesParaMostrar.length - 1;

                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ícono y línea de conexión
                                    Column(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isFirst ? Colors.green : (isLast ? Colors.red : AppColors.mainBlueColor),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isFirst ? Icons.my_location : (isLast ? Icons.location_on : Icons.circle),
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        if (index < partesParaMostrar.length - 1)
                                          Container(
                                            width: 2,
                                            height: 20,
                                            color: Colors.grey[300],
                                          ),
                                      ],
                                    ),

                                    SizedBox(width: 12),

                                    // Texto del punto
                                    Expanded(
                                      child: Text(
                                        partesParaMostrar[index],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isFirst ? Colors.green[800] : (isLast ? Colors.red[800] : Colors.grey[700]),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
