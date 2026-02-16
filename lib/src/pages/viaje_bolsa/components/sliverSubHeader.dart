import 'package:embarques_tdp/src/pages/viaje_bolsa/components/sliverAppBarDelegate.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';

class SliverSubHeader extends StatelessWidget {
  final Widget child;
  final Color colorContainer;
  final double minHeight;
  final double maxHeight;

  const SliverSubHeader({
    super.key,
    required this.child,
    required this.colorContainer,
    required this.minHeight,
    required this.maxHeight,
  });
  @override
  Widget build(BuildContext context) {
    // 1
    return SliverPersistentHeader(
      pinned: true,
      delegate: SliverAppBarDelegate(
        // 2
        minHeight: minHeight,
        maxHeight: maxHeight,
        // 3
        child: Container(
          child: child,
          color: colorContainer,
        ),
      ),
    );
  }
}
