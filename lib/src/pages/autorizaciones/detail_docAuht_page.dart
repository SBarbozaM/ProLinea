import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import 'package:embarques_tdp/src/services/detail_doc_auth_service.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/detail_doc_model.dart';
import 'package:intl/intl.dart';

enum statusDetailDocsAuth { initial, success, failure, progress }

class DetailPage extends StatefulWidget {
  final String pkOrden;
  final String tipoDocOrden;
  final String moneda;
  final VoidCallback onConfirm;

  DetailPage({required this.pkOrden, required this.tipoDocOrden, required this.moneda, required this.onConfirm});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  statusDetailDocsAuth status = statusDetailDocsAuth.initial;

  DetailDocModel detailModel = DetailDocModel(
    rpta: "500",
    mensaje: "ERROR EN LA CONSULTA",
    tipoDoc: "",
    numDoc: "",
    pkOrden: "",
    tipoDocOrden: "",
    authDetail: [],
  );

  @override
  void initState() {
    super.initState();
    // Aquí el contexto no está disponible. Usa el método build o didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    _obtenerDetailDocsAuth(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, widget.pkOrden, widget.tipoDocOrden);
    // Usa usuarioProvider según lo necesites
  }

  _obtenerDetailDocsAuth(String tipoDoc, String numDoc, String pkOrden, String tipoDocOrden) async {
    DetailDocsAuthServicio sDetailDocsAuth = DetailDocsAuthServicio();

    setState(() {
      status = statusDetailDocsAuth.progress;
    });

    detailModel = await sDetailDocsAuth.detailDocument(tipoDoc, numDoc, pkOrden, tipoDocOrden);

    if (detailModel.rpta != "0") {
      setState(() {
        status = statusDetailDocsAuth.failure;
      });
      return;
    }

    if (detailModel.rpta == "0") {
      setState(() {
        status = statusDetailDocsAuth.success;
      });

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatear el precio
    final NumberFormat formatter = NumberFormat('0.00');

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            color: AppColors.backColor,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (status == statusDetailDocsAuth.progress)
                Container(
                  // padding: EdgeInsets.only(top: 10),
                  alignment: Alignment.topCenter,
                  child: CircularProgressIndicator(
                    color: AppColors.mainBlueColor,
                  ),
                ),
              if (status == statusDetailDocsAuth.success) ...[
                if (detailModel.authDetail.isEmpty)
                  const Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0), 
                      child: Text(
                        'El gasto no tiene detalle',
                        style: TextStyle(color: AppColors.greyColor, fontSize: 18),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: detailModel.authDetail.length,
                      itemBuilder: (context, index) {
                        AuthDetail detail = detailModel.authDetail[index];
                        return Card(
                          child: ListTile(
                            // title: Text('Nombre: ' + detail.nombre),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: AppColors.mainBlueColor, fontSize: 18),
                                    children: [
                                      TextSpan(
                                        text: detail.descProd,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                        children: [
                                          const TextSpan(
                                            text: 'Cantidad: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: detail.cantidad.toString() + ' '),
                                          TextSpan(
                                            text: detail.nombre,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                        children: [
                                          const TextSpan(
                                            text: 'Precio: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: widget.moneda + formatter.format(detail.precioVenta).toString(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                    children: [
                                      const TextSpan(
                                        text: 'Importe: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: widget.moneda + (detail.cantidad * detail.precioVenta).toStringAsFixed(2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: AppColors.blackColor, fontSize: 16),
                                    children: [
                                      const TextSpan(
                                        text: 'Centro de Costos: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: detail.descripcion,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
              if (status == statusDetailDocsAuth.failure) Text('Error al cargar los datos'),
            ],
          ),

          // Positioned(
          //   right: 0.0,
          //   child: IconButton(
          //     icon: Icon(Icons.close),
          //     onPressed: () => Navigator.pop(context),
          //   ),
          // ),
        ],
      ),
    );
  }
}
