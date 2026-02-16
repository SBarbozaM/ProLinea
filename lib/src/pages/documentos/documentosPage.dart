import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:embarques_tdp/src/components/drawer.dart';
import 'package:embarques_tdp/src/models/documento_vehiculo.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/documento_servicio.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; s
// se migro a : 29/082025
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:document_file_save_plus/document_file_save_plus.dart';

class DocumentosPage extends StatelessWidget {
  const DocumentosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        drawer: const MyDrawer(),
        appBar: AppBar(
          title: Text('Documentos ${Provider.of<UsuarioProvider>(context).usuario.unidadEmp} - ${Provider.of<UsuarioProvider>(context).usuario.placaEmp}'),
          backgroundColor: AppColors.mainBlueColor,
        ),
        body: MyStatefulWidget());
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  DocumentoServicio documento_servicio = DocumentoServicio();
  List<DocumentoVehiculo> listaVehiculos = [];

  String url_path = "";

  // late final PdfViewerController _pdfViewerController;
  late final PdfControllerPinch _pdfViewerController;

  @override
  void initState() {
    super.initState();
    obtenerDocumentosVehiculo(Provider.of<UsuarioProvider>(context, listen: false).usuario.unidadEmp);
    // _pdfViewerController = PdfViewerController();
    _pdfViewerController = PdfControllerPinch(
      document: PdfDocument.openFile(url_path),
    );
  }

  Future<void> obtenerDocumentosVehiculo(String code_vehiculo) async {
    List<DocumentoVehiculo> documentos = await documento_servicio.obtenerDocumentoVehiculo(code_vehiculo);
    setState(() {
      listaVehiculos = documentos;
    });
  }

  base64ToPdf(String base64String, String fileName) async {
    var pdfbase64 = base64String.split(',');
    var bytes = base64Decode(pdfbase64[1]);
    print(pdfbase64);

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName.pdf");
    await file.writeAsBytes(bytes.buffer.asUint8List());

    setState(() {
      url_path = "${output.path}/$fileName.pdf";
    });
  }

  Future<void> GuardarPdf(String base64String, String fileName) async {
    if (await Permission.storage.request().isGranted) {
      var pdfbase64 = base64String.split(',');
      var bytes = base64Decode(pdfbase64[1]);

      // DocumentFileSavePlus().saveFile(bytes, "${fileName}.pdf", "appliation/pdf");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('PDF Guardado')),
      // );

      //migrado 29/08/2025 a :
      final String savedPath = await FileSaver.instance.saveFile(
        name: "${fileName}.pdf", // parámetro requerido
        bytes: bytes,
        fileExtension: "pdf",
        mimeType: MimeType.other,
      );
      if (savedPath != null && savedPath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF guardado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el PDF')),
        );
      }
    }
    if (await Permission.storage.request().isDenied) {
      print("object");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ExpansionPanelList(
          expandedHeaderPadding: EdgeInsets.all(10),
          expansionCallback: (int index, bool isExpanded) async {
            setState(() {
              listaVehiculos[index].isExpanded = !isExpanded;
            });
            base64ToPdf(listaVehiculos[index].documento.toString(), listaVehiculos[index].nombre.toString());
          },
          children: listaVehiculos.map<ExpansionPanel>((DocumentoVehiculo documento) {
            final fechav = documento.fechaVencimiento.split(" ");
            print(fechav);
            String fechanew = fechav[0];

            return ExpansionPanel(
              // hasIcon: false,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      documento.isExpanded = !isExpanded;
                    });
                    base64ToPdf(documento.documento.toString(), documento.nombre.toString());
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      title: Container(
                        alignment: Alignment.centerLeft,
                        height: 25,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                child: Row(
                              children: [
                                FittedBox(
                                  child: documento.estado == "Vigente"
                                      ? Icon(
                                          Icons.check_circle,
                                          color: AppColors.greenColor,
                                        )
                                      : Icon(
                                          Icons.warning,
                                          color: AppColors.amberColor,
                                        ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.45,
                                  child: FittedBox(
                                    alignment: Alignment.bottomLeft,
                                    child: Text(
                                      documento.nombre,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ),
                                ),
                              ],
                            )),
                            Container(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    child: Text(
                                      "${fechanew}",
                                      style: TextStyle(color: AppColors.greyColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  GestureDetector(
                                      onTap: () {
                                        GuardarPdf(documento.documento, documento.nombre);
                                      },
                                      child: Icon(Icons.download_rounded))
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              body: Container(
                  padding: EdgeInsets.all(8),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: url_path == ""
                      ? Center(
                          child: CircularProgressIndicator(strokeWidth: 1),
                        )
                      : PdfViewPinch(controller: _pdfViewerController)
                  //SfPdfViewer.file(
                  //     File(url_path),
                  //     canShowScrollHead: false,
                  //     canShowScrollStatus: false,
                  //     scrollDirection: PdfScrollDirection.horizontal,
                  //     controller: _pdfViewerController,
                  //   ),
                  ),
              isExpanded: documento.isExpanded,
            );
          }).toList(),
        ),
      ),
    );
  }
}
