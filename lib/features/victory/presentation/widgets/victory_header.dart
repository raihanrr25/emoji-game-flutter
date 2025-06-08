import 'package:flutter/material.dart';

class VictoryHeader extends StatelessWidget {
  final VoidCallback onHomePressed;

  const VictoryHeader({super.key, required this.onHomePressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.amberAccent, size: 28),
              onPressed: onHomePressed,
            ),
            Expanded(
              child: ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [
                        Colors.amberAccent,
                        Colors.orange,
                        Colors.yellow,
                      ],
                    ).createShader(bounds),
                child: const Text(
                  'KEMENANGAN EPIK! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
