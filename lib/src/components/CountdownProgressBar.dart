import 'package:flutter/material.dart';
import 'dart:async';
import 'package:embarques_tdp/src/utils/app_colors.dart';

class CountdownProgressBarController {
  VoidCallback? startOrResetTimer;
  VoidCallback? cancelTimer;
}

class CountdownProgressBar extends StatefulWidget {
  final int duration; // Duración en segundos
  final VoidCallback onComplete; // Callback cuando el temporizador termine
  final CountdownProgressBarController controller; // Controlador para reiniciar/iniciar el temporizador

  CountdownProgressBar({this.duration = 15, required this.onComplete, required this.controller});

  @override
  _CountdownProgressBarState createState() => _CountdownProgressBarState();
}

class _CountdownProgressBarState extends State<CountdownProgressBar> {
  double progress = 1.0;
  Timer? timer;
  bool hasStarted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.startOrResetTimer = startOrResetTimer;
    widget.controller.cancelTimer = cancelTimer;
  }

  void startOrResetTimer() {
    if (hasStarted) {
      resetTimer();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    setState(() {
      hasStarted = true;
      progress = 1.0;
    });
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (progress > 0) {
        setState(() {
          progress -= 1 / widget.duration;
        });
      } else {
        timer?.cancel();
        widget.onComplete(); // Llamar al callback cuando el tiempo se termine
      }
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      progress = 1.0;
    });
    startTimer();
  }

  void cancelTimer() {
    setState(() {
      hasStarted = false;
      progress = 1.0;
    });
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return hasStarted
        ? LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.amberColor),
          )
        : SizedBox.shrink();
  }
}
