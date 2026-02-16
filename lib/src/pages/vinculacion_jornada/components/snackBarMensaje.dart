import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';

SnackBarmensaje(BuildContext context, String mensaje, Color color) {
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      mensaje,
      style: TextStyle(color: AppColors.whiteColor),
      textAlign: TextAlign.center,
    ),
    duration: Duration(seconds: 2),
    backgroundColor: color,
  ));
}
