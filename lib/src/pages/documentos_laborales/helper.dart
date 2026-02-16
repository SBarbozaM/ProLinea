import 'package:flutter/material.dart';

final Map<String, IconData> iconMap = {
  'laborales': Icons.fact_check_outlined,
  'liquidacion': Icons.file_present_outlined,
  'certificado': Icons.camera_rear_outlined,
  'aportaciones': Icons.safety_divider,
  'utilidades': Icons.move_up_outlined
};

IconData getIconFromString(String iconName) {
  return iconMap[iconName] ?? Icons.folder;
}
