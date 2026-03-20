import 'dart:io';
import 'dart:typed_data';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<void> savePdfToDownloads(BuildContext context, Uint8List uint8List, String fileName) async {
  try {
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      // Usamos la misma lógica que en documentos laborales para llegar a la carpeta pública
      final dir = await getExternalStorageDirectory();
      if (dir != null) {
        final rootPath = dir.path.split('/Android')[0];
        downloadsDir = Directory('$rootPath/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } else {
        downloadsDir = Directory("/storage/emulated/0/Download");
      }
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
          "✅ PDF guardado en: ${downloadsDir.path}",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.greenColor,
        duration: Duration(seconds: 3),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "❌ Error al guardar PDF: $e",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.amberColor,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
