import 'package:flutter/material.dart';

class VictoryMessage extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;
  final Animation<double> bounceAnimation;

  const VictoryMessage({
    super.key,
    required this.scaleAnimation,
    required this.rotationAnimation,
    required this.bounceAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          scaleAnimation,
          rotationAnimation,
          bounceAnimation,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -bounceAnimation.value),
            child: Transform.rotate(
              angle: rotationAnimation.value,
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amberAccent,
                        Colors.orange.shade300,
                        Colors.yellow.shade300,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🏆 CHAMPION! 🏆',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Mission Accomplished! 🚀',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
