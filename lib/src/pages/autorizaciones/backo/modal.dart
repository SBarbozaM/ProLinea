// widgets/detalle_documento_modal.dart
import 'package:embarques_tdp/src/models/Autorizaciones/backo/DocumentoDetalle.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/backo/GrupoDocumento.dart';
import 'package:embarques_tdp/src/services/authorizador_backo.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';

class DetalleDocumentoModal extends StatefulWidget {
  final int id;
  final int tipoDocumentoId;

  const DetalleDocumentoModal({
    super.key,
    required this.id,
    required this.tipoDocumentoId,
  });

  @override
  State<DetalleDocumentoModal> createState() => _DetalleDocumentoModalState();
}

class _DetalleDocumentoModalState extends State<DetalleDocumentoModal> {
  DocumentoDetalleNormalizado? _detalle;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    final servicio = DocsBackoServicio();
    try {
      final resultado = await servicio.obtenerDocumentoDetalle(
        id: widget.id,
        tipoId: widget.tipoDocumentoId,
      );
      setState(() {
        _detalle = resultado;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar detalle';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _detalle?.codigo ?? 'Cargando...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.mainBlueColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator(color: AppColors.mainBlueColor))
                      : _error != null
                          ? Center(child: Text(_error!))
                          : _detalle == null
                              ? const Center(child: Text('Sin datos'))
                              : ListView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    _seccion('Información General'),
                                    _fila('Código', _detalle!.codigo),
                                    _fila('Empresa', _detalle!.empresa),
                                    _fila('Estado', _detalle!.estado),
                                    _fila('Motivo', _detalle!.motivo),
                                    _fila('Fecha Solicitud', _detalle!.fechaSolicitud),
                                    _fila('Fecha Entrega', _detalle!.fechaEntrega),
                                    _fila('Aprobaciones', '${_detalle!.nivelActual}/${_detalle!.ultimoNivel}'),
                                    if (_detalle!.motivo_Movimiento_Codigo == 'SE-E') ...[
                                      const SizedBox(height: 12),
                                      _seccion('Referencias Base'),
                                      _fila('Nota Crédito', _detalle!.notaCredito),
                                      _fila('Orden Compra', _detalle!.ordenCompra),
                                      _fila('Comprobante', _detalle!.comprobante),
                                    ],
                                    const SizedBox(height: 12),
                                    _seccion('Solicitante'),
                                    _fila('Nombre', _detalle!.solicitante),
                                    if (_detalle!.area.isNotEmpty) _fila('Área', _detalle!.area),
                                    if ((_detalle!.motivo_Movimiento_Codigo == 'SN-O' || _detalle!.motivo_Movimiento_Codigo == 'SAL-CON') && _detalle!.centroCosto.isNotEmpty) _fila('Centro Costo', _detalle!.centroCosto),
                                    if (_detalle!.proveedorNombre.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _seccion('Proveedor'),
                                      _fila('Nombre', _detalle!.proveedorNombre),
                                      _fila('RUC', _detalle!.proveedorRuc),
                                      if (_detalle!.condicionPago.isNotEmpty) _fila('Condición Pago', _detalle!.condicionPago),
                                      if (_detalle!.formaPago.isNotEmpty) _fila('Forma Pago', _detalle!.formaPago),
                                    ],
                                    if (_detalle!.almacen.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      if (_detalle!.TipoDocAproCodigo == 'REQ-ALM') _seccion('Almacén Salida'),
                                      if (_detalle!.TipoDocAproCodigo == 'SOL-COM') _seccion('Almacén Destino'),
                                      if (_detalle!.TipoDocAproCodigo == 'OC') _seccion('Almacén Recepción'),
                                      _fila('Almacén', _detalle!.almacen),
                                      _fila('Sede', _detalle!.sede),
                                      if (_detalle!.observacion.isNotEmpty) _fila('Observación', _detalle!.observacion),
                                    ],
                                    if (_detalle!.total > 0) ...[
                                      const SizedBox(height: 12),
                                      _seccion('Totales'),
                                      if (_detalle!.moneda.isNotEmpty) _fila('Moneda', _detalle!.moneda),
                                      if (_detalle!.subtotal > 0) _fila('Subtotal', '${_detalle!.moneda} ${_detalle!.subtotal.toStringAsFixed(2)}'),
                                      if (_detalle!.impuesto > 0) _fila('Impuesto', '${_detalle!.moneda} ${_detalle!.impuesto.toStringAsFixed(2)}'),
                                      _filaDestacada('Monto Total', 'S/ ${_detalle!.total.toStringAsFixed(2)}'),
                                    ],
                                    if (_detalle!.items.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _seccion('Detalles (${_detalle!.items.length})'),
                                      ..._detalle!.items.map((item) => _cardItem(item, _detalle!.TipoDocAproCodigo, _detalle!.motivo_Movimiento_Codigo, _detalle!.moneda)),
                                    ],
                                    if (_detalle!.aprobadores.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _seccion('Aprobadores'),
                                      ..._detalle!.aprobadores.map((ap) => _cardAprobador(ap)),
                                    ],
                                  ],
                                )),
            ],
          ),
        );
      },
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.mainBlueColor)),
    );
  }

  Widget _fila(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _filaDestacada(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.greenColor)),
        ],
      ),
    );
  }

  Widget _cardItem(ItemNormalizado item, String tipoDocAprobCod, String motivoCodigo, String? tipoMoneda) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Item ${item.item} - ${item.codigo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.mainBlueColor),
                  ),
                ),
                // if (item.estadoRecepcion.isNotEmpty)
                //   Container(
                //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                //     decoration: BoxDecoration(
                //       color: _getColorEstado(item.estadoColor),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Text(item.estadoRecepcion, style: const TextStyle(color: Colors.white, fontSize: 11)),
                //   ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.descripcion, style: const TextStyle(fontSize: 13)),
            if (item.subCategoria.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Categoría: ${item.subCategoria}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cant: ${item.cantidad} ${item.unidad}', style: const TextStyle(fontSize: 13)),
                Text(
                  '${_detalle!.moneda.isNotEmpty ? _detalle!.moneda : 'S/'} ${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.greenColor),
                ),
              ],
            ),
            if (((tipoDocAprobCod == 'SOL-COM' || tipoDocAprobCod == 'OC') && item.esServicio && item.centroCosto.isNotEmpty) || (tipoDocAprobCod == 'REQ-ALM' && (motivoCodigo == 'SN-O' || motivoCodigo == 'SAL-CON'))) ...[
              const SizedBox(height: 2),
              Text('CC: ${item.centroCosto}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            if (!item.esServicio && item.almacen.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Almacén: ${item.almacen}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            if (item.proyectoDescripcion.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Proyecto: ${item.proyectoDescripcion}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _cardAprobador(AprobadorNormalizado ap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nivel ${ap.nivel}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainBlueColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ap.finalizado == true ? AppColors.greenColor : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ap.finalizado == true ? 'Finalizado' : 'Pendiente',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (ap.nombre.isNotEmpty) Text(ap.nombre, style: const TextStyle(fontSize: 13)),
            if (ap.email != null) Text(ap.email!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (ap.fechaLimite != null) Text('Límite: ${ap.fechaLimite}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (ap.comentario.isNotEmpty) Text('Comentario: ${ap.comentario}', style: const TextStyle(fontSize: 12)),
            if (ap.motivoRechazo != null && ap.motivoRechazo!.isNotEmpty) Text('Rechazo: ${ap.motivoRechazo}', style: const TextStyle(fontSize: 12, color: Colors.red)),
            if (ap.motivoObservacion != null && ap.motivoObservacion!.isNotEmpty) Text('Observación: ${ap.motivoObservacion}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
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
}
