import 'dart:io';

class DocumentoTemporal {
  final File file;
  final List<int> bytes;

  DocumentoTemporal({
    required this.file,
    required this.bytes,
  });
}
