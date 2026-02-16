import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<Uint8List> generateDocument(Viaje viaje, Usuario usuario) async {
  final doc = pw.Document(pageMode: PdfPageMode.outlines);

  final font1 = await PdfGoogleFonts.openSansRegular();
  final font2 = await PdfGoogleFonts.openSansBold();

  // doc.addPage(
  //   pw.Page(
  //     pageTheme: pw.PageTheme(
  //       pageFormat: PdfPageFormat.a4,
  //       orientation: pw.PageOrientation.portrait,
  //       buildBackground: (context) => pw.Image(shape),
  //       theme: pw.ThemeData.withFont(
  //         base: font1,
  //         bold: font2,
  //       ),
  //     ),
  //     build: (context) {
  //       return pw.Padding(
  //         padding: const pw.EdgeInsets.only(
  //           left: 60,
  //           right: 60,
  //           bottom: 30,
  //         ),
  //         child: pw.Column(
  //           children: [
  //             pw.Spacer(),
  //             pw.RichText(
  //                 text: pw.TextSpan(children: [
  //               pw.TextSpan(
  //                 text: '${DateTime.now().year}\n',
  //                 style: pw.TextStyle(
  //                   fontWeight: pw.FontWeight.bold,
  //                   color: PdfColors.grey600,
  //                   fontSize: 40,
  //                 ),
  //               ),
  //               pw.TextSpan(
  //                 text: 'Portable Document Format',
  //                 style: pw.TextStyle(
  //                   fontWeight: pw.FontWeight.bold,
  //                   fontSize: 40,
  //                 ),
  //               ),
  //             ])),
  //             pw.Spacer(),
  //             pw.Container(
  //               alignment: pw.Alignment.topRight,
  //               height: 150,
  //               child: pw.PdfLogo(),
  //             ),
  //             pw.Spacer(flex: 2),
  //             pw.Align(
  //               alignment: pw.Alignment.topLeft,
  //               child: pw.UrlLink(
  //                 destination: 'https://wikipedia.org/wiki/PDF',
  //                 child: pw.Text(
  //                   'https://wikipedia.org/wiki/PDF',
  //                   style: const pw.TextStyle(
  //                     color: PdfColors.pink100,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   ),
  // );

  // doc.addPage(
  //   pw.Page(
  //     theme: pw.ThemeData.withFont(
  //       base: font1,
  //       bold: font2,
  //     ),
  //     pageFormat: PdfPageFormat.a4,
  //     orientation: pw.PageOrientation.portrait,
  //     build: (context) {
  //       return pw.Column(
  //         children: [
  //           pw.Center(
  //             child: pw.Text('Table of content',
  //                 style: pw.Theme.of(context).header0),
  //           ),
  //           pw.SizedBox(height: 20),
  //           pw.TableOfContent(),
  //           pw.Spacer(),
  //           pw.Center(child: pw.Image(swirls)),
  //           pw.Spacer(),
  //         ],
  //       );
  //     },
  //   ),
  // );

  doc.addPage(pw.MultiPage(
    theme: pw.ThemeData.withFont(
      base: font1,
      bold: font2,
    ),
    pageFormat: PdfPageFormat.a4,
    orientation: pw.PageOrientation.portrait,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    header: (pw.Context context) {
      if (context.pageNumber == 1) {
        return pw.SizedBox();
      }
      return pw.Container(
        padding: pw.EdgeInsets.only(bottom: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                "RUTA",
                style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
              ),
              pw.Text(
                "${viaje.origen} - ${viaje.destino}",
                style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
              ),
            ]),
            pw.SizedBox(width: 10),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                "Bus/Placa",
                style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
              ),
              pw.Text(
                "${viaje.unidad}",
                style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
              ),
            ]),
            pw.SizedBox(width: 10),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                "Fecha/Hora",
                style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
              ),
              pw.Text(
                "${viaje.fechaSalida} ${viaje.horaSalida}",
                style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
              ),
            ]),
          ],
        ),
      );
    },
    // footer: (pw.Context context) {
    //   return pw.Container(
    //     alignment: pw.Alignment.centerRight,
    //     child: pw.Text(
    //       'Fecha de impresión: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
    //       style: pw.Theme.of(context).defaultTextStyle.copyWith(
    //             color: PdfColors.grey,
    //             fontSize: 7,
    //           ),
    //     ),
    //   );
    // },
    build: (pw.Context context) => <pw.Widget>[
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: <pw.Widget>[
          pw.Text(
            'MANIFIESTO DE PASAJEROS',
            textScaleFactor: 2,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Container(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Column(
                    //RUC
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "RUC",
                        style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                      ),
                      pw.Text(
                        "${viaje.ruc}",
                        style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                      ),
                    ]),
                pw.SizedBox(width: 10),
                pw.Column(
                    //Razón Social
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Razón Social",
                        style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                      ),
                      pw.Text(
                        "${viaje.razonSocial}",
                        style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                      ),
                    ]),
                pw.SizedBox(width: 10),
                pw.Column(
                    //Teléfono
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Teléfono",
                        style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                      ),
                      pw.Text(
                        "${viaje.telefono}",
                        style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                      ),
                    ]),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
              pw.Column(
                  //RUTA
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Ruta",
                      style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                    ),
                    pw.Text(
                      "${viaje.origen} - ${viaje.destino}",
                      style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                    ),
                  ]),
              pw.SizedBox(width: 10),
              pw.Column(
                  //Fecha/Hora
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Fecha/Hora",
                      style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                    ),
                    pw.Text(
                      "${viaje.fechaSalida} ${viaje.horaSalida}",
                      style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                    ),
                  ]),
              pw.SizedBox(width: 10),
              pw.Column(
                  //Empresa
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Empresa",
                      style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                    ),
                    pw.Text(
                      "${viaje.subOperacionNombre}",
                      style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                    ),
                  ]),
            ]),
            pw.SizedBox(height: 3),
            if (viaje.tripulantes[0].numDoc != "")
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
                pw.Column(
                    //Conductor 1
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Conductor 1",
                        style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                      ),
                      pw.Text(
                        "${viaje.tripulantes.length >= 1 ? viaje.tripulantes[0].nombres : ''}",
                        style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                      ),
                    ]),
              ]),
            pw.SizedBox(height: 3),
            if (viaje.tripulantes[2].numDoc != "")
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
                pw.Column(
                    //Conductor 3
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Conductor 3",
                        style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                      ),
                      pw.Text(
                        "${viaje.tripulantes.length >= 3 ? viaje.tripulantes[2].nombres : ''}",
                        style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                      ),
                    ]),
              ]),
            pw.SizedBox(height: 3),
            if (viaje.tripulantes[4].nombres != "")
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
                pw.Column(
                    //Asistente 2
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Asistente 2",
                        style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                      ),
                      pw.Text(
                        "${viaje.tripulantes.length >= 5 ? viaje.tripulantes[4].nombres : ''}",
                        style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                      ),
                    ]),
              ]),
          ]),
        ),
        pw.Container(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(
                  "Dirección",
                  style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                ),
                pw.Text(
                  "${viaje.direccion}",
                  style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                ),
              ]),
            ]),
            pw.SizedBox(height: 3),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(
                  "Bus/Placa",
                  style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                ),
                pw.Text(
                  "${viaje.unidad}",
                  style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                ),
              ]),
            ]),
            pw.SizedBox(height: 3),
            if (viaje.tripulantes[1].numDoc != "")
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    "Conductor 2",
                    style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                  ),
                  pw.Text(
                    "${viaje.tripulantes.length >= 2 ? viaje.tripulantes[1].nombres : ''}",
                    style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                  ),
                ]),
              ]),
            pw.SizedBox(height: 3),
            if (viaje.tripulantes[3].nombres != "")
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(
                    "Asistente 1",
                    style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                  ),
                  pw.Text(
                    "${viaje.tripulantes.length >= 4 ? viaje.tripulantes[3].nombres : ''}",
                    style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                  ),
                ]),
              ]),
            pw.SizedBox(height: 3),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(
                  "Responble Embarque",
                  style: pw.TextStyle(color: PdfColor.fromHex("#b1b1b1"), fontSize: 10),
                ),
                pw.Text(
                  "${usuario.apellidoPat} ${usuario.apellidoMat} ${usuario.nombres}",
                  style: pw.TextStyle(color: PdfColor.fromHex("#000000"), fontSize: 8),
                ),
              ]),
            ]),
          ]),
        ),
      ]),
      pw.SizedBox(height: 50),
      pw.Table.fromTextArray(
        headerStyle: pw.TextStyle(
          color: PdfColor.fromHex("#292929"),
          fontWeight: pw.FontWeight.normal,
          fontSize: 10,
        ),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex("#C0C0C0").shade(0.3)),
        border: pw.TableBorder(
          left: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
          right: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
          top: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
          bottom: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
          horizontalInside: pw.BorderSide(
            color: PdfColor.fromHex("#C0C0C0").shade(0.8),
          ),
          verticalInside: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
        ),
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.center,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
          5: pw.Alignment.center,
        },
        context: context,
        headers: [
          'N°',
          'Asiento',
          'Apellidos y Nombres',
          'Documento',
          'Embarque',
          'Desembarque',
        ],
        data: viaje.pasajeros
            .mapIndexed((index, element) => [
                  "${index + 1}",
                  "${element.asiento > 0 ? "${element.asiento}" : ""}",
                  "${element.apellidos} ${element.nombres}",
                  "${element.tipoDoc}-${element.numDoc}",
                  "${element.lugarEmbarque}",
                  "${element.lugarDesembarque}",
                ])
            .toList(),
      ),
      pw.SizedBox(height: 10),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 200,
            child: pw.Column(
              children: [
                pw.Container(
                    width: 200,
                    child: pw.Center(
                      child: pw.Text(
                        "Resumen Asientos",
                        style: pw.TextStyle(color: PdfColor.fromHex("#292929"), fontWeight: pw.FontWeight.normal),
                      ),
                    ),
                    color: PdfColor.fromHex("#C0C0C0").shade(0.3)),
                pw.Table.fromTextArray(
                  border: pw.TableBorder(
                    left: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
                    right: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
                    top: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
                    bottom: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
                    horizontalInside: pw.BorderSide(
                      color: PdfColor.fromHex("#C0C0C0").shade(0.8),
                    ),
                    verticalInside: pw.BorderSide(color: PdfColor.fromHex("#C0C0C0").shade(0.8)),
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColor.fromHex("#292929"),
                    fontWeight: pw.FontWeight.normal,
                    fontSize: 10,
                  ),
                  cellAlignment: pw.Alignment.center,
                  headers: [
                    'Capacidad',
                    'Ocupados',
                    'Libres',
                  ],
                  context: context,
                  data: [
                    ['${viaje.cantAsientos}', '${viaje.cantEmbarcados}', '${viaje.cantAsientos - viaje.cantEmbarcados}'],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      pw.Padding(padding: const pw.EdgeInsets.all(22)),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text("----------------------------"),
              pw.Text("FIRMA CONDUCTOR"),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text("----------------------------"),
              pw.Text("FIRMA SUPERVISOR"),
            ],
          ),
        ],
      ),
    ],
  ));

  return await doc.save();
}
