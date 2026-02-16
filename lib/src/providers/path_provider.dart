import 'dart:io';
import 'dart:typed_data';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> savePdfToDownloads(BuildContext context, Uint8List uint8List, String fileName) async {
  try {
    // Verificamos si el permiso ya está concedido
    // var status = await Permission.storage.status;
    // if (!status.isGranted) {
    //   // Solicitamos permiso
    //   status = await Permission.storage.request();
    // }

    // if (status.isGranted) {
    // Obtenemos la carpeta "Downloads"
    Directory downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory("/storage/emulated/0/Download");
    } else {
      downloadsDir = await getApplicationDocumentsDirectory(); // iOS
    }

    final filePath = "${downloadsDir.path}/$fileName.pdf";

    // Guardamos el archivo
    final file = File(filePath);
    await file.writeAsBytes(uint8List);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ PDF guardado en: $filePath",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.greenColor,
        duration: Duration(seconds: 1),
      ),
    );
    // print("✅ PDF guardado en: $filePath");
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "❌ Error al guardar PDF: $e",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.amberColor,
        duration: Duration(seconds: 1),
      ),
    );
    //  print("❌ Error al guardar PDF: $e");
  }
}
