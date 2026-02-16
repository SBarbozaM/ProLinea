import 'package:embarques_tdp/src/models/DocumentosLaborales/docsAcciones_model.dart';
import 'package:embarques_tdp/src/pages/documentos_laborales/helper.dart';
import 'package:embarques_tdp/src/services/documentos_laborales_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:embarques_tdp/src/models/DocumentosLaborales/docsUsuario_model.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/widgets.dart';

import '../../providers/providers.dart';
import '../../providers/connection_status_provider.dart';

enum StatusListaDocsUsuarios { initial, progress, success, failure }

class DocumentosLaboralesPage extends StatefulWidget {
  const DocumentosLaboralesPage({super.key});

  @override
  State<DocumentosLaboralesPage> createState() => _DocumentosLaboralesPageState();
}

class _DocumentosLaboralesPageState extends State<DocumentosLaboralesPage> {
  StatusListaDocsUsuarios status = StatusListaDocsUsuarios.initial;

  final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  DocsUsuario docsUsuario = DocsUsuario(
    rpta: '',
    mensaje: '',
    tipoDoc: '',
    numDoc: '',
    docsAcciones: [],
  );

  @override
  void initState() {
    super.initState();
    final usuario = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    ).usuario;

    _obtenerDocs(usuario.tipoDoc, usuario.numDoc);
  }

  Future<void> _obtenerDocs(String tipoDoc, String numDoc) async {
    final service = DocsUsuarioServicio();

    setState(() {
      status = StatusListaDocsUsuarios.progress;
    });

    try {
      final resp = await service.listarDocsLabsAccionesUsuario(tipoDoc, numDoc);

      // ✅ ÉXITO REAL
      if (resp.rpta == '0' || resp.rpta == '200') {
        setState(() {
          docsUsuario = resp;
          status = StatusListaDocsUsuarios.success;
        });
        return;
      }

      // ⚠️ RESPUESTA CONTROLADA PERO NO OK
      setState(() {
        docsUsuario = resp;
        status = StatusListaDocsUsuarios.failure;
      });
    } catch (e) {
      debugPrint('ERROR _obtenerDocs: $e');

      setState(() {
        status = StatusListaDocsUsuarios.failure;
      });
    }
  }

  bool _hayConexion() {
    return Provider.of<ConnectionStatusProvider>(
          context,
          listen: false,
        ).status.name ==
        'online';
  }

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Documentos Laborales'),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              'inicio',
              (route) => false,
            );
          },
        ),
      ),
      body: _buildBody(usuarioProvider),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mainBlueColor,
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            'inicio',
            (route) => false,
          );
        },
        child: const Icon(Icons.home),
      ),
    );
  }

  Widget _buildBody(UsuarioProvider usuarioProvider) {
    switch (status) {
      case StatusListaDocsUsuarios.progress:
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.mainBlueColor,
          ),
        );

      case StatusListaDocsUsuarios.success:
        return RefreshIndicator(
          color: AppColors.mainBlueColor,

          /// 🔄 AQUÍ SE RECARGA TODO EL PAGE
          onRefresh: () => _obtenerDocs(
            usuarioProvider.usuario.tipoDoc,
            usuarioProvider.usuario.numDoc,
          ),

          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: docsUsuario.docsAcciones.length,
              itemBuilder: (context, index) {
                final doc = docsUsuario.docsAcciones[index];
                return DocCardGlass(doc: doc);
              },
            ),
          ),
        );

      case StatusListaDocsUsuarios.failure:
        return RefreshIndicator(
          color: AppColors.mainBlueColor,
          onRefresh: () => _obtenerDocs(
            usuarioProvider.usuario.tipoDoc,
            usuarioProvider.usuario.numDoc,
          ),
          child: ListView(
            children: [
              if (!_hayConexion())
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.yellow[100],
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Revisa tu conexión a internet',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_hayConexion())
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(docsUsuario.mensaje),
                ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class DocCardGlass extends StatelessWidget {
  final DocsAccion doc;

  const DocCardGlass({Key? key, required this.doc}) : super(key: key);

  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).pushNamed(
            'documentosDetalle',
            arguments: {
              'idAccion': doc.orden,
              'descripcion': doc.nombre,
            },
          );

          // 👇 SOLO si volvió del detalle
          if (result == true) {
            final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);

            final state = context.findAncestorStateOfType<_DocumentosLaboralesPageState>();

            state?._obtenerDocs(
              usuarioProvider.usuario.tipoDoc,
              usuarioProvider.usuario.numDoc,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // ICONO
              Icon(
                getIconFromString(doc.icono),
                size: 22,
                color: AppColors.mainBlueColor,
              ),

              const SizedBox(width: 12),

              // TEXTO
              Expanded(
                child: Text(
                  doc.nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // BADGE PENDIENTES
              if (doc.pendientes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    doc.pendientes > 99 ? '99+' : doc.pendientes.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(width: 6),

              // FLECHA (opcional, UX clara)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
