import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingEffects extends StatelessWidget {
  final List<Particle> particles;
  final List<FloatingEmoji> floatingEmojis;
  final double particleAnimationValue;
  final double emojiAnimationValue;

  const FloatingEffects({
    super.key,
    required this.particles,
    required this.floatingEmojis,
    required this.particleAnimationValue,
    required this.emojiAnimationValue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating particles
        CustomPaint(
          painter: ParticlePainter(particles, particleAnimationValue),
          size: Size.infinite,
        ),
        // Floating emojis
        CustomPaint(
          painter: FloatingEmojiPainter(floatingEmojis, emojiAnimationValue),
          size: Size.infinite,
        ),
      ],
    );
  }
}

// Move the Particle and FloatingEmoji classes here
class Particle {
  double x, y, speed, size;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class FloatingEmoji {
  String emoji;
  double x, y, speed;

  FloatingEmoji({
    required this.emoji,
    required this.x,
    required this.y,
    required this.speed,
  });
}

// Custom painter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint =
          Paint()
            ..color = particle.color.withOpacity(0.7)
            ..style = PaintingStyle.fill;

      final offset = Offset(
        particle.x +
            50 * math.sin(animationValue * 2 * math.pi + particle.x / 100),
        particle.y +
            30 * math.cos(animationValue * 2 * math.pi + particle.y / 100),
      );

      canvas.drawCircle(offset, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for floating emojis
class FloatingEmojiPainter extends CustomPainter {
  final List<FloatingEmoji> emojis;
  final double animationValue;

  FloatingEmojiPainter(this.emojis, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var emoji in emojis) {
      final textPainter = TextPainter(
        text: TextSpan(text: emoji.emoji, style: const TextStyle(fontSize: 24)),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final offset = Offset(
        emoji.x + 30 * math.sin(animationValue * 2 * math.pi * emoji.speed),
        emoji.y + 20 * math.cos(animationValue * 2 * math.pi * emoji.speed),
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
