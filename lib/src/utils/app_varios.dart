import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppVarios {
  static const double _iconSize = 75;
  static const List<Widget> iconosEstados = <Widget>[
    Icon(
      Icons.check_rounded,
      size: _iconSize,
      color: AppColors.greenColor,
    ),
    Icon(
      Icons.close_rounded,
      size: _iconSize,
      color: AppColors.redColor,
    ),
    Icon(
      Icons.schedule_rounded,
      size: _iconSize,
      color: AppColors.mainBlueColor,
    ),
  ];

  static const List<Widget> iconosDesembarque = <Widget>[
    Icon(
      Icons.check_rounded,
      size: _iconSize,
      color: AppColors.greenColor,
    ),
    Icon(
      Icons.close_rounded,
      size: _iconSize,
      color: AppColors.redColor,
    ),
  ];

  static Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return AppColors.greyColor;
    }
    return AppColors.turquesaLinea;
  }
}
