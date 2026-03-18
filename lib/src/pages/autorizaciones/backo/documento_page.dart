import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/components/BarraProgresiva.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/DocumentoRegistrado.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/GrupoDocumento.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/RespuestaAction.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/TipoDocumento.dart';
import 'package:embarques_tdp/src/pages/autorizaciones/backo/modal.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/authorizador_backo.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

enum StatusListaDocsBacko { initial, success, failure, progress }

enum StatusAccion { initial, progress, success, failure }

class ListaDocumentosBackoPage extends StatefulWidget {
  const ListaDocumentosBackoPage({super.key});

  @override
  State<ListaDocumentosBackoPage> createState() => _ListaDocumentosBackoPageState();
}

class _ListaDocumentosBackoPageState extends State<ListaDocumentosBackoPage> {
  StatusListaDocsBacko status = StatusListaDocsBacko.initial;
  List<GrupoDocumento> documentos = [];
  List<StatusAccion> _responseState = [];
  List<Timer?> _timers = [];
  List<DocumentoRegistrado> documentosRegistrados = [];
  List<bool> _cardVisible = [];
  List<double> _cardOpacity = [];

  String tipo = '';
  TipoDocumento? tipoDocumento;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      setState(() {
        tipo = args['tipo'];

        final tipoDocumentoData = args['tipoDocumento'];
        // Por página llega como TipoDocumento, por notificación como Map
        if (tipoDocumentoData is TipoDocumento) {
          tipoDocumento = tipoDocumentoData;
        } else if (tipoDocumentoData is Map) {
          tipoDocumento = TipoDocumento.fromJson(
            tipoDocumentoData.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      });
      _cargarDocumentos();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t?.cancel();
    }
    super.dispose();
  }

  Future<void> _cargarDocumentos() async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final servicio = DocsBackoServicio();

    setState(() => status = StatusListaDocsBacko.progress);

    try {
      if (tipo == 'registrados') {
        documentosRegistrados = await servicio.listarDocumentosRegistrados(
          idTipoDocumento: tipoDocumento!.id,
          tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
          dniColaborador: usuarioProvider.usuario.numDoc,
        );
        setState(() {
          status = documentosRegistrados.isNotEmpty ? StatusListaDocsBacko.success : StatusListaDocsBacko.failure;
        });
        return;
      }

      List<GrupoDocumento> resultado = [];
      switch (tipo) {
        case 'pendientes':
          resultado = await servicio.listarDocumentosPendientes(
            idTipoDocAprobacion: tipoDocumento!.id,
            tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
            dniColaborador: usuarioProvider.usuario.numDoc,
          );
          break;
        case 'aprobados':
          resultado = await servicio.listarDocumentosAprobados(
            idTipoDocAprobacion: tipoDocumento!.id,
            tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
            dniColaborador: usuarioProvider.usuario.numDoc,
          );
          break;
        case 'observados':
          resultado = await servicio.listarDocumentosObservados(
            idTipoDocAprobacion: tipoDocumento!.id,
            tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
            dniColaborador: usuarioProvider.usuario.numDoc,
          );
          break;
        case 'rechazados':
          resultado = await servicio.listarDocumentosRechazados(
            idTipoDocAprobacion: tipoDocumento!.id,
            tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
            dniColaborador: usuarioProvider.usuario.numDoc,
          );
          break;
      }

      final detalles = resultado.expand((g) => g.detalle).toList();

      setState(() {
        documentos = resultado;
        _responseState = List.generate(detalles.length, (_) => StatusAccion.initial);
        _cardVisible = List.generate(detalles.length, (_) => true);
        _cardOpacity = List.generate(detalles.length, (_) => 1.0);
        _timers = List.generate(detalles.length, (_) => null);
        status = resultado.isNotEmpty ? StatusListaDocsBacko.success : StatusListaDocsBacko.failure;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => status = StatusListaDocsBacko.failure);
    }
  }

  List<DetalleDocumento> get _todosLosDetalles => documentos.expand((g) => g.detalle).toList();

  String get _titulo {
    switch (tipo) {
      case 'pendientes':
        return 'Pendientes';
      case 'aprobados':
        return 'Aprobados';
      case 'rechazados':
        return 'Rechazados';
      case 'observados':
        return 'Observados';
      case 'registrados':
        return 'Registrados';
      default:
        return 'Documentos';
    }
  }

  void _accionDocumento(int index, DetalleDocumento detalle, String accion, {String motivo = ''}) {
    // Mostrar barra progresiva inmediatamente (aún no se envía)
    setState(() => _responseState[index] = StatusAccion.success);

    // Cancelar timer anterior si existe
    _timers[index]?.cancel();

    // Timer de 5s, al completarse recién envía
    _timers[index] = Timer(const Duration(seconds: 5), () {
      _enviarAccion(index, detalle, accion, motivo: motivo);
    });
  }

  Future<void> _enviarAccion(int index, DetalleDocumento detalle, String accion, {String motivo = ''}) async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final servicio = DocsBackoServicio();

    setState(() => _responseState[index] = StatusAccion.progress);

    RespuestaAccion? resultado;

    try {
      switch (accion) {
        case 'A':
          resultado = await servicio.aprobarDocumento(
            tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
            dniCreadoPor: usuarioProvider.usuario.numDoc,
            id: detalle.id,
            idTipoDocumento: tipoDocumento!.id,
          );
          break;
        case 'R':
          resultado = await servicio.rechazarDocumento(
            tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
            dniCreadoPor: usuarioProvider.usuario.numDoc,
            id: detalle.id,
            motivo: motivo,
            idTipoDocumento: tipoDocumento!.id,
          );
          break;
        case 'O':
          resultado = await servicio.observarDocumento(
            tipoDocumentoCodigo: usuarioProvider.usuario.tipoDoc,
            dniCreadoPor: usuarioProvider.usuario.numDoc,
            id: detalle.id,
            motivo: motivo,
            idTipoDocumento: tipoDocumento!.id,
          );
          break;
      }
    } catch (e) {
      setState(() => _responseState[index] = StatusAccion.failure);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    if (resultado == null || !resultado.resultado) {
      setState(() => _responseState[index] = StatusAccion.failure);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resultado?.mensaje.isNotEmpty == true ? resultado!.mensaje : 'Error al procesar'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    // Éxito: ocultar card
    if (mounted) setState(() => _cardVisible[index] = false);
  }

  void _deshacerAccion(int index) {
    // Cancelar el timer → nunca se envía
    _timers[index]?.cancel();
    _timers[index] = null;

    setState(() {
      _responseState[index] = StatusAccion.initial;
      _cardVisible[index] = true;
      _cardOpacity[index] = 1.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Acción cancelada'),
      backgroundColor: AppColors.mainBlueColor,
      duration: Duration(seconds: 1),
    ));
  }

  void _mostrarModalMotivo(int index, DetalleDocumento detalle, String accion) {
    final controller = TextEditingController();
    final String titulo = accion == 'R' ? 'Motivo de Rechazo' : 'Motivo de Observación';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainBlueColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Documento: ${detalle.codigoDocumento}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escriba el motivo...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.mainBlueColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accion == 'R' ? Colors.red : Colors.orange),
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Por favor escriba un motivo'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              Navigator.pop(context);
              _accionDocumento(index, detalle, accion, motivo: controller.text.trim());
            },
            child: Text(accion == 'R' ? 'Rechazar' : 'Observar', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void mostrarModalDetalle(int id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetalleDocumentoModal(
        id: id,
        tipoDocumentoId: tipoDocumento!.id,
      ),
    );
  }

  Widget _detalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainBlueColor)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  bool _hayConexion() => Provider.of<ConnectionStatusProvider>(context, listen: false).status.name == 'online';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text('${tipoDocumento?.descripcion}'),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: AppColors.mainBlueColor.withOpacity(0.1),
            child: Text(
              _titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.mainBlueColor,
              ),
            ),
          ),
          Expanded(
            child: Builder(builder: (context) {
              if (status == StatusListaDocsBacko.progress) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.mainBlueColor),
                );
              }
              if (status == StatusListaDocsBacko.success) {
                final detalles = _todosLosDetalles;
                return RefreshIndicator(
                    onRefresh: _cargarDocumentos,
                    color: AppColors.mainBlueColor,
                    child: Column(children: [
                      // Lista
                      Expanded(
                          child: tipo == 'registrados'
                              ? ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: documentosRegistrados.length,
                                  itemBuilder: (context, index) {
                                    return _cardRegistrado(documentosRegistrados[index]);
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: detalles.length,
                                  itemBuilder: (context, index) {
                                    final detalle = detalles[index];
                                    return Visibility(
                                      visible: _cardVisible[index],
                                      child: Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () => mostrarModalDetalle(detalle.id),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Header
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        detalle.codigoDocumento,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          color: AppColors.mainBlueColor,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getColorEstado(detalle.colorEstado),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        detalle.descripcionEstado,
                                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                // Solicitante
                                                RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                                                    children: [
                                                      const TextSpan(text: 'Solicitante: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                      TextSpan(text: '${detalle.solicitanteNombres} ${detalle.solicitanteApellidos}'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Proveedor
                                                if (detalle.proveedor.isNotEmpty)
                                                  RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                                                      children: [
                                                        const TextSpan(text: 'Proveedor: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                        TextSpan(text: detalle.proveedor),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                // Motivo
                                                RichText(
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  text: TextSpan(
                                                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                                                    children: [
                                                      const TextSpan(text: 'Motivo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                      TextSpan(text: detalle.motivoMovimiento),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Total y fecha
                                                if (detalle.observacion.isNotEmpty)
                                                  RichText(
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    text: TextSpan(
                                                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                                                      children: [
                                                        const TextSpan(text: 'Observación: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                        TextSpan(text: detalle.observacion),
                                                      ],
                                                    ),
                                                  ),

                                                // Botones solo para pendientes
                                                if (tipo == 'pendientes') ...[
                                                  const Divider(height: 16),
                                                  _responseState[index] == StatusAccion.progress
                                                      ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mainBlueColor)))
                                                      : _responseState[index] == StatusAccion.success
                                                          ? BarraProgresiva(
                                                              duracion: 5,
                                                              onCompleto: () {},
                                                              onDeshacer: () => _deshacerAccion(index),
                                                            )
                                                          : Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                              children: [
                                                                // Aprobar
                                                                ElevatedButton.icon(
                                                                  onPressed: () => _accionDocumento(index, detalle, 'A'),
                                                                  icon: const Icon(Icons.check, size: 16),
                                                                  label: const Text('Aprobar'),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: AppColors.greenColor,
                                                                    foregroundColor: Colors.white,
                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                    textStyle: const TextStyle(fontSize: 13),
                                                                  ),
                                                                ),
                                                                // Observar
                                                                ElevatedButton.icon(
                                                                  onPressed: () => _mostrarModalMotivo(index, detalle, 'O'),
                                                                  icon: const Icon(Icons.remove_red_eye, size: 16),
                                                                  label: const Text('Observar'),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: Colors.orange,
                                                                    foregroundColor: Colors.white,
                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                    textStyle: const TextStyle(fontSize: 13),
                                                                  ),
                                                                ),
                                                                // Rechazar
                                                                ElevatedButton.icon(
                                                                  onPressed: () => _mostrarModalMotivo(index, detalle, 'R'),
                                                                  icon: const Icon(Icons.close, size: 16),
                                                                  label: const Text('Rechazar'),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: Colors.red,
                                                                    foregroundColor: Colors.white,
                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                    textStyle: const TextStyle(fontSize: 13),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ))
                    ]));
              }
              if (status == StatusListaDocsBacko.failure) {
                return RefreshIndicator(
                  onRefresh: _cargarDocumentos,
                  color: AppColors.mainBlueColor,
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
                              Expanded(child: Text('Revisa tu conexión a internet', style: TextStyle(color: Colors.orange))),
                            ],
                          ),
                        ),
                      if (_hayConexion())
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No se encontraron documentos.')),
                        ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('inicio', (route) => false),
        backgroundColor: AppColors.mainBlueColor,
        tooltip: 'Regresar a Inicio',
        child: const Icon(Icons.home),
      ),
    );
  }

  Color _getColorEstado(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppColors.mainBlueColor;
    }
  }

  Widget _cardRegistrado(DocumentoRegistrado doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => mostrarModalDetalle(doc.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.codigo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.mainBlueColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorEstado(doc.estadoColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      doc.estado,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Solicitante: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: doc.solicitante),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Motivo: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: doc.motivo),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Almacén: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: doc.almacen),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (doc.observacion.isNotEmpty)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      const TextSpan(text: 'Observación: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: doc.observacion),
                    ],
                  ),
                ),
              if (doc.observacion.isNotEmpty) const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doc.sede,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    doc.fechaSolicitud,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
