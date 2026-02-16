import 'dart:io';

import 'package:embarques_tdp/src/models/DocumentosLaborales/descuentos_model.dart';
import 'package:embarques_tdp/src/models/DocumentosLaborales/documentos_model.dart';
import 'package:embarques_tdp/src/services/documentos_laborales_service.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import 'package:embarques_tdp/src/utils/app_colors.dart';
import '../../providers/providers.dart';

class DocumentosDetallePage extends StatefulWidget {
  const DocumentosDetallePage({super.key});

  @override
  State<DocumentosDetallePage> createState() => _DocumentosDetallePageState();
}

class _DocumentosDetallePageState extends State<DocumentosDetallePage> {
  late int idAccion; // 1..7
  String descripcion = "";
  List<DocLaboralDetalle> documentos = [];

  /// N = Pendientes | S = Visualizados
  String estadoDocumento = 'N';

  /// filtro por nombre
  String filtroNombre = '';
  bool _cargadoInicial = false;

  bool cargando = false;

  @override
  void initState() {
    super.initState();

    // ⏳ Esperar al primer frame para usar context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      idAccion = args['idAccion'];
      descripcion = args['descripcion'];

      _consultarDocumentos(); // ✅ solo una vez
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, true); // 👈 avisa a la pantalla anterior
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade200,
          appBar: AppBar(
            title: Text(descripcion),
            backgroundColor: AppColors.mainBlueColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtros',
                onPressed: _mostrarFiltros,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSwitchBar(),
              const SizedBox(height: 4),

              /// 🔄 LISTADO
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.mainBlueColor,
                  onRefresh: _consultarDocumentos,
                  child: _buildListado(),
                ),
              ),
            ],
          ),
        ));
  }

  // ================= SWITCH COMPACTO =================

  Widget _buildSwitchBar() {
    return Container(
      height: 44, // 🔹 altura mínima
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Pendientes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: estadoDocumento == 'N' ? Colors.orange : Colors.grey,
            ),
          ),
          Switch(
            value: estadoDocumento == 'S',
            activeColor: Colors.green,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) {
              setState(() {
                estadoDocumento = value ? 'S' : 'N';
              });
              _consultarDocumentos();
            },
          ),
          Text(
            'Visualizados',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: estadoDocumento == 'S' ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ================= LISTADO =================

  Widget _buildListado() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.mainBlueColor,
        ),
      );
    }

    if (documentos.isEmpty) {
      return const Center(
        child: Text('No hay documentos para mostrar'),
      );
    }

    final filtrados = documentos.where((doc) {
      if (filtroNombre.isEmpty) return true;

      return doc.periodo.toLowerCase().contains(filtroNombre.toLowerCase());
    }).toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final doc = filtrados[index];

        final bool tieneDescuento = doc.tieneDescuento != 0;

        return Card(
          color: tieneDescuento ? Colors.yellow.shade100 : Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              estadoDocumento == 'N' ? Icons.hourglass_top : Icons.check_circle,
              color: estadoDocumento == 'N' ? Colors.orange : Colors.green,
            ),
            title: Text(doc.periodo),
            subtitle: doc.ultVisualizada.isNotEmpty ? Text('Últ. visualizada: ${doc.ultVisualizada}') : null,

            // ⬇️ BOTÓN DESCARGA
            trailing: IconButton(
              icon: const Icon(Icons.remove_red_eye_outlined),
              color: AppColors.mainBlueColor,
              tooltip: 'Ver documento',
              onPressed: () {
                _verDocumento(doc);
              },
            ),

            // 🟡 MODAL SOLO SI HAY DESCUENTO
            onTap: () {
              if (doc.tieneDescuento != 0) {
                _mostrarModalDocumento(doc);
              }
            },
          ),
        );
      },
    );
  }

  void _verDocumento(DocLaboralDetalle doc) async {
    final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    final result = await Navigator.pushNamed(
      context,
      'documento-viewer',
      arguments: {
        'codigo': doc.codigo,
        'tipo': idAccion,
        'tipoDoc': usuario.tipoDoc,
        'numDoc': usuario.numDoc,
        'mensaje': doc.mensaje,
        'tipoPlanilla': doc.tipoPlanilla ?? '',
        'visualizada': doc.visualizada,
        'mesanio': doc.mesAnio ?? '',
        'desc': doc.periodo,
      },
    );

    // 👇 SI SE VISUALIZÓ, RECARGA
    if (result == true) {
      _consultarDocumentos();
    }
  }

  void _mostrarModalDocumento(
    DocLaboralDetalle doc,
  ) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    final service = DocsUsuarioServicio();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('⚠ Detalle de Descuento'),
          content: FutureBuilder<List<DescuentoPersona>>(
            future: service.listarDescuentos(
              tipoDoc: usuarioProvider.tipoDoc,
              dni: usuarioProvider.numDoc,
              mesAnio: doc.mesAnio ?? "",
              tipoPlanilla: doc.tipoPlanilla ?? "",
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  '❌ Error al obtener datos',
                  style: TextStyle(color: Colors.red.shade700),
                );
              }

              final lista = snapshot.data ?? [];

              if (lista.isEmpty) {
                return const Text('No existen descuentos para este periodo');
              }

              // 👉 si solo esperas uno, tomamos el primero
              final descuento = lista.first;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motivo: ${descuento.nombre}'),
                  const SizedBox(height: 8),
                  Text('Importe: S/ ${descuento.abono.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Saldo: S/ ${descuento.saldoDesc.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // ================= FILTROS =================

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre del documento',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    filtroNombre = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= BACKEND =================

  Future<void> _consultarDocumentos() async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final service = DocsUsuarioServicio();
    setState(() {
      cargando = true;
    });

    try {
      final resp = await service.listarDocsPorEstado(
        tipo: idAccion,
        tipoDoc: usuarioProvider.usuario.tipoDoc,
        nroDoc: usuarioProvider.usuario.numDoc,
        estado: estadoDocumento,
      );

      setState(() {
        documentos = resp;
      });
    } catch (e) {
      debugPrint('ERROR consultar documentos: $e');
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _descargarDocumento(DocLaboralDetalle doc) async {
    final service = DocsUsuarioServicio();
    final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    try {
      final file = await service.descargarBoletaEnDescargas(codigo: doc.codigo, tipo: idAccion, desc: doc.periodo, tipoPlanilla: doc.tipoPlanilla ?? "", mesanio: doc.mesAnio ?? "", numDoc: usuario.numDoc, tipoDoc: usuario.tipoDoc);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Documento descargado en Descargas'),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
