import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

AwesomeDialog mensaje(
    BuildContext context, DialogType dialogType, String mensaje) {
  return AwesomeDialog(
    context: context,
    dialogType: dialogType,
    //customHeader: null,
    animType: AnimType.topSlide,

    autoDismiss: true,
    autoHide: Duration(seconds: 2),
    body: Center(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Text(
          mensaje,
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
