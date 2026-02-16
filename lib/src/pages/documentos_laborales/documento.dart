import 'dart:io';

import 'package:embarques_tdp/src/services/documentos_laborales_service.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DocumentoViewerPage extends StatefulWidget {
  const DocumentoViewerPage({super.key});

  @override
  State<DocumentoViewerPage> createState() => _DocumentoViewerPageState();
}

class _DocumentoViewerPageState extends State<DocumentoViewerPage> {
  String? pdfPath;
  List<int>? pdfBytes;
  bool cargando = true;
  String? error;
  bool _yaAviso = false;

  late Map<String, dynamic> args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _cargarPdf();
  }

  Future<void> _cargarPdf() async {
    try {
      final result = await DocsUsuarioServicio.obtenerDocumentoTemporal(
        codigo: args['codigo'],
        tipo: args['tipo'],
        tipoDoc: args['tipoDoc'],
        numDoc: args['numDoc'],
        tipoPlanilla: args['tipoPlanilla'],
        mesanio: args['mesanio'],
        desc: args['desc'],
      );
      setState(() {
        pdfPath = result.file.path;
        pdfBytes = result.bytes;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        cargando = false;
        error = e.toString();
      });
    }
  }

  Future<void> _descargarDocumento() async {
    if (pdfBytes == null) return;

    try {
      final downloadsDir = await getDownloadDirectoryAndroid();
      final nombreArchivo = nombreSeguro('${args['desc']}.pdf');
      final file = File('${downloadsDir.path}/$nombreArchivo');

      await file.writeAsBytes(pdfBytes!, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Documento guardado en Descargas'),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String nombreSeguro(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<Directory> getDownloadDirectoryAndroid() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
      return (await getExternalStorageDirectory())!;
    }
    return getApplicationDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final bool noVisualizado = args['visualizada'] == 'NO';
    final String mensaje = args['mensaje'] ?? '';

    return WillPopScope(
      onWillPop: () async {
        if (!_yaAviso) {
          _yaAviso = true;
          Navigator.pop(context, true); // 👈 avisa al volver
        }
        return false; // evitamos doble pop
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: AppColors.mainBlueColor,
          title: Text(args['desc']),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (!_yaAviso) {
                _yaAviso = true;
                Navigator.pop(context, true); // 👈 mismo aviso
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Descargar',
              onPressed: _descargarDocumento,
            ),
          ],
        ),
        body: cargando
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Column(
                    children: [
                      if (noVisualizado)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.orange.shade100,
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  mensaje.isNotEmpty ? mensaje : 'Este documento aún no ha sido visualizado.',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: PDFView(
                          filePath: pdfPath!,
                          enableSwipe: true,
                          autoSpacing: true,
                          pageFling: true,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
