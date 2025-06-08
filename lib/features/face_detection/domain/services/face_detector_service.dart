import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/game_expression.dart';
import 'expression_evaluator.dart';

class FaceDetectorService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.3,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  final ExpressionEvaluator _evaluator = ExpressionEvaluator();

  Future<List<Face>> processImage(InputImage inputImage) async {
    try {
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      debugPrint('Face detection error: $e');
      return [];
    }
  }

  bool matchesExpression(Face face, GameExpression expression) {
    return _evaluator.matchesExpression(face, expression);
  }

  GameExpression? getCurrentDetectedExpression(Face face) {
    return _evaluator.getCurrentDetectedExpression(face);
  }

  void dispose() {
    _faceDetector.close();
  }
}
