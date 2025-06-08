import 'package:flutter/material.dart';

class VictoryInstructions extends StatelessWidget {
  final bool isSmileDetected;

  const VictoryInstructions({super.key, required this.isSmileDetected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            isSmileDetected
                ? Colors.green.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: (isSmileDetected ? Colors.green : Colors.amberAccent)
              .withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          isSmileDetected
              ? '😊 PERFECT SMILE! Capturing now...'
              : '😊 SMILE for automatic capture! 📸',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isSmileDetected ? Colors.green.shade300 : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
