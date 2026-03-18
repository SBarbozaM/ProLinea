import 'package:embarques_tdp/src/models/Autorizaciones/backo/TipoDocumento.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/services/authorizador_backo.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum StatusListaAuthUsuarios { initial, success, failure, progress }

class TiposDocumentosPage extends StatefulWidget {
  const TiposDocumentosPage({super.key});

  @override
  State<TiposDocumentosPage> createState() => _TiposDocumentosPageState();
}

class _TiposDocumentosPageState extends State<TiposDocumentosPage> {
  StatusListaAuthUsuarios status = StatusListaAuthUsuarios.initial;
  List<TipoDocumento> tiposDocumentos = [];
  static const Map<String, String> _iconosPorCodigo = {
    'REQ-ALM': 'https://img.icons8.com/fluency/96/handcart.png',
    'OC': 'https://img.icons8.com/fluency/96/buy-for-cash.png',
    'SOL-COM': 'https://img.icons8.com/fluency/96/heck-for-payment.png'
    // agrega los demás códigos con su URL...
  };
  @override
  void initState() {
    super.initState();
    _obtenerListBacko();
  }

  Future<void> _obtenerListBacko() async {
    DocsBackoServicio sDocsBacko = DocsBackoServicio();

    setState(() {
      status = StatusListaAuthUsuarios.progress;
    });

    final resultado = await sDocsBacko.listarTiposDocumentos();

    setState(() {
      tiposDocumentos = resultado; // 👈 asigna dentro del setState
      status = tiposDocumentos.isNotEmpty ? StatusListaAuthUsuarios.success : StatusListaAuthUsuarios.failure;
    });

    print('Status: $status'); // 👈 agrega esto para confirmar
    print('Total: ${tiposDocumentos.length}');
  }

  bool _hayConexion() {
    return Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online';
  }

  final List<Color> cardColors = [
    AppColors.greenColor,
    AppColors.blueColor,
    AppColors.darkTurquesa,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Documentos BackOffice'),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (status == StatusListaAuthUsuarios.progress) {
            return Container(
              padding: const EdgeInsets.only(top: 10),
              alignment: Alignment.topCenter,
              child: const CircularProgressIndicator(
                color: AppColors.mainBlueColor,
              ),
            );
          }

          if (status == StatusListaAuthUsuarios.success) {
            return RefreshIndicator(
              onRefresh: _obtenerListBacko,
              color: AppColors.mainBlueColor,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(), // 👈 agrega esto
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: tiposDocumentos.length,
                itemBuilder: (context, index) {
                  final doc = tiposDocumentos[index];
                  if (doc.codigo != 'SOL-FONDO')
                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed('opcionesDocumento', arguments: doc);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _iconosPorCodigo[doc.codigo] != null
                                    ? Image.network(
                                        _iconosPorCodigo[doc.codigo]!,
                                        width: 60,
                                        height: 60,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, size: 60, color: AppColors.mainBlueColor),
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          );
                                        },
                                      )
                                    : const Icon(Icons.description, size: 60, color: AppColors.mainBlueColor),
                                const SizedBox(height: 8),
                                Text(
                                  doc.descripcion,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  doc.codigo,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                },
              ),
            );
          }

          if (status == StatusListaAuthUsuarios.failure) {
            return RefreshIndicator(
              onRefresh: _obtenerListBacko,
              color: AppColors.mainBlueColor,
              child: ListView(
                children: [
                  if (!_hayConexion())
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.yellow[100],
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Revisa tu conexión a internet",
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_hayConexion())
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No se encontraron documentos."),
                    ),
                ],
              ),
            );
          }

          return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
        },
        backgroundColor: AppColors.mainBlueColor,
        tooltip: 'Regresar a Inicio',
        child: const Icon(Icons.home),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
