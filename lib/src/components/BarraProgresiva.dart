// widgets/barra_progresiva.dart
import 'dart:async';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';

class BarraProgresiva extends StatefulWidget {
  final int duracion;
  final VoidCallback onCompleto;
  final VoidCallback onDeshacer;

  const BarraProgresiva({
    super.key,
    required this.duracion,
    required this.onCompleto,
    required this.onDeshacer,
  });

  @override
  State<BarraProgresiva> createState() => _BarraProgresivaState();
}

class _BarraProgresivaState extends State<BarraProgresiva>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duracion),
    )
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleto();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1 - _controller.value,
                backgroundColor: Colors.grey.shade300,
                color: AppColors.mainBlueColor,
                minHeight: 6,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final segundosRestantes =
                    ((1 - _controller.value) * widget.duracion).ceil();
                return Text(
                  'Se confirmará en $segundosRestantes seg...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
            ),
            TextButton.icon(
              onPressed: () {
                _controller.stop();
                widget.onDeshacer();
              },
              icon: const Icon(Icons.undo, size: 14),
              label: const Text('Deshacer', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}