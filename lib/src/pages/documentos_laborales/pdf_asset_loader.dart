import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PdfAssetLoader {
  static Future<String> loadFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/documento_temp.pdf');

    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file.path;
  }
}
