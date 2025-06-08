import 'package:flutter/material.dart';

/// Enum for facial expressions to be detected in the game
enum GameExpression { senyum, netral, marah, sedih, kaget, ngantuk }

/// Extension methods for the GameExpression enum
extension GameExpressionExtension on GameExpression {
  String get instructionText {
    switch (this) {
      case GameExpression.senyum:
        return 'SENYUM!';
      case GameExpression.netral:
        return 'WAJAH NETRAL!';
      case GameExpression.marah:
        return 'WAJAH MARAH!';
      case GameExpression.sedih:
        return 'WAJAH SEDIH!';
      case GameExpression.kaget:
        return 'WAJAH KAGET!';
      case GameExpression.ngantuk:
        return 'WAJAH NGANTUK!';
    }
  }

  Widget buildExpressionImage(String assetPath) {
    return Image.asset(assetPath, width: 128, height: 128, fit: BoxFit.contain);
  }

  Widget get expressionImage {
    switch (this) {
      case GameExpression.senyum:
        return buildExpressionImage("assets/images/smile.png");
      case GameExpression.netral:
        return buildExpressionImage("assets/images/neutral.png");
      case GameExpression.marah:
        return buildExpressionImage("assets/images/angry.png");
      case GameExpression.sedih:
        return buildExpressionImage("assets/images/sad.png");
      case GameExpression.kaget:
        return buildExpressionImage("assets/images/surprised.png");
      case GameExpression.ngantuk:
        return buildExpressionImage("assets/images/sleepy.png");
    }
  }
}
