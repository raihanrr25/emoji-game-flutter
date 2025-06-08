import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatelessWidget {
  final Animation<double> backgroundAnimation;

  const AnimatedBackground({super.key, required this.backgroundAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade900,
                Colors.purple.shade700,
                Colors.indigo.shade800,
                Colors.deepPurple.shade900,
              ],
              stops: [
                0.0,
                0.3 + 0.2 * math.sin(backgroundAnimation.value),
                0.7 + 0.2 * math.cos(backgroundAnimation.value),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}
