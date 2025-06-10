import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/game_expression.dart';
import 'dart:math';

class ExpressionEvaluator {
  // Landmark-based thresholds
  static const double SMILE_THRESHOLD =
      0.65; // Slightly lowered for better detection
  static const double NEUTRAL_SMILE_MAX = 0.15;
  static const double NEUTRAL_SMILE_MIN = 0.005;
  static const double EYE_OPEN_THRESHOLD = 0.6;
  static const double NEUTRAL_EYE_MIN = 0.7;
  static const double DROWSY_EYE_THRESHOLD =
      0.35; // Lowered for better sleepy detection
  static const double SURPRISED_EYE_THRESHOLD =
      0.75; // Lowered for easier detection
  static const double FACING_THRESHOLD = 15.0;

  // Updated thresholds for better angry detection
  static const double ANGRY_SMILE_MAX = 0.25; // Increased tolerance
  static const double ANGRY_EYEBROW_THRESHOLD = 0.75; // More lenient
  static const double ANGRY_MOUTH_TENSION = 0.9; // More sensitive

  // Updated thresholds for better sad detection
  static const double SAD_SMILE_MAX = 0.2; // Increased tolerance
  static const double SAD_EYE_THRESHOLD = 0.65; // More lenient for droopy eyes
  static const double SAD_MOUTH_RATIO = 1; // More sensitive

  // Updated thresholds for surprised detection
  static const double SURPRISED_MOUTH_THRESHOLD = 0.7; // Lowered requirement
  static const double SURPRISED_EYEBROW_THRESHOLD = 1.1; // More lenient

  // Landmark distance thresholds
  static const double MOUTH_CORNER_RATIO_SMILE = 5;
  static const double MOUTH_CORNER_RATIO_SAD = 0.95;
  static const double NEUTRAL_MOUTH_CORNER_MIN = 3.0;
  static const double NEUTRAL_MOUTH_CORNER_MAX = 8.0;
  static const double NEUTRAL_MOUTH_ASPECT_MIN = 0.6;
  static const double NEUTRAL_MOUTH_ASPECT_MAX = 1.2;
  static const double EYEBROW_EYE_RATIO_ANGRY = 0.85;
  static const double EYEBROW_EYE_RATIO_SURPRISED = 1.15;
  static const double MOUTH_ASPECT_RATIO_OPEN = 0.8;

  bool isFacingCamera(Face face) {
    final yaw = face.headEulerAngleY?.abs() ?? 0;
    final roll = face.headEulerAngleZ?.abs() ?? 0;
    return yaw < FACING_THRESHOLD && roll < FACING_THRESHOLD;
  }

  double? _getMouthCornerRatio(Face face) {
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    if (leftMouth == null || rightMouth == null || bottomMouth == null) {
      return null;
    }

    final mouthWidth = (rightMouth.x - leftMouth.x).abs();
    final leftCornerHeight = (leftMouth.y - bottomMouth.y).abs();
    final rightCornerHeight = (rightMouth.y - bottomMouth.y).abs();
    final avgCornerHeight = (leftCornerHeight + rightCornerHeight) / 2;

    return mouthWidth / (avgCornerHeight + 1);
  }

  double? _getEyebrowEyeRatio(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;

    if (leftEye == null ||
        rightEye == null ||
        leftCheek == null ||
        rightCheek == null) {
      return null;
    }

    final eyeDistance = (rightEye.x - leftEye.x).abs();
    final cheekDistance = (rightCheek.x - leftCheek.x).abs();

    return eyeDistance / cheekDistance;
  }

  double? _getMouthAspectRatio(Face face) {
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;

    if (leftMouth == null ||
        rightMouth == null ||
        bottomMouth == null ||
        noseBase == null) {
      return null;
    }

    final mouthWidth = (rightMouth.x - leftMouth.x).abs();
    final mouthHeight = (bottomMouth.y - noseBase.y).abs();

    return mouthHeight / mouthWidth;
  }

  // Enhanced eye asymmetry detection for expressions
  double _getEyeAsymmetry(Face face) {
    final leftEye = face.leftEyeOpenProbability ?? 0;
    final rightEye = face.rightEyeOpenProbability ?? 0;
    return (leftEye - rightEye).abs();
  }

  bool _isSmiling(Face face) {
    final smile = face.smilingProbability ?? 0;
    debugPrint('Smile Probability: $smile');
    return smile > SMILE_THRESHOLD &&
        face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null;
  }

  bool _isNeutral(Face face) {
    final smile = face.smilingProbability ?? 0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;
    final mouthCornerRatio = _getMouthCornerRatio(face);
    final mouthAspectRatio = _getMouthAspectRatio(face);
    final eyebrowRatio = _getEyebrowEyeRatio(face);

    bool lowSmile = smile >= NEUTRAL_SMILE_MIN && smile <= NEUTRAL_SMILE_MAX;
    bool eyesOpen = avgEyeOpen >= NEUTRAL_EYE_MIN;
    bool eyesBalanced = (leftEyeOpen - rightEyeOpen).abs() < 0.3;

    bool mouthNeutral =
        mouthCornerRatio == null ||
        (mouthCornerRatio >= NEUTRAL_MOUTH_CORNER_MIN &&
            mouthCornerRatio <= NEUTRAL_MOUTH_CORNER_MAX);

    bool mouthAspectNeutral =
        mouthAspectRatio == null ||
        (mouthAspectRatio >= NEUTRAL_MOUTH_ASPECT_MIN &&
            mouthAspectRatio <= NEUTRAL_MOUTH_ASPECT_MAX);

    bool eyebrowNeutral =
        eyebrowRatio == null || (eyebrowRatio >= 0.65 && eyebrowRatio <= 0.85);

    bool isNeutral =
        lowSmile &&
        eyesOpen &&
        eyesBalanced &&
        mouthNeutral &&
        mouthAspectNeutral &&
        eyebrowNeutral;

    if (smile <= NEUTRAL_SMILE_MAX) {
      debugPrint(
        '[Neutral Check] Smile: $lowSmile ($smile) | Eyes: $eyesOpen ($avgEyeOpen) | '
        'Balanced: $eyesBalanced | Mouth: $mouthNeutral | Aspect: $mouthAspectNeutral | '
        'Eyebrow: $eyebrowNeutral | Result: $isNeutral',
      );
    }

    return isNeutral;
  }

  bool _isAngry(Face face) {
    final smile = face.smilingProbability ?? 0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;
    final eyebrowRatio = _getEyebrowEyeRatio(face);
    final mouthRatio = _getMouthCornerRatio(face);
    final eyeAsymmetry = _getEyeAsymmetry(face);

    // Updated angry indicators based on your specific data patterns
    bool lowSmile = smile < 0.15; // Your data: 0.067, 0.128
    bool veryLowSmile = smile < 0.08; // Very low smile threshold

    // Eye asymmetry is a strong angry indicator based on your data
    bool strongEyeAsymmetry =
        eyeAsymmetry > 0.3; // 0.026 vs 0.680 = 0.654 difference
    bool moderateEyeAsymmetry = eyeAsymmetry > 0.15; // Less strict threshold

    // One eye significantly more closed (squinting)
    bool oneEyeSquinting =
        (leftEyeOpen < 0.1 && rightEyeOpen > 0.5) ||
        (rightEyeOpen < 0.1 && leftEyeOpen > 0.5);

    // Mouth tension indicators
    bool mouthTense =
        mouthRatio != null &&
        (mouthRatio >= 7.0 && mouthRatio <= 9); // Your data: 5.93, 5.04

    // Eyebrow position
    bool eyebrowsAngry =
        eyebrowRatio != null &&
        (eyebrowRatio >= 0.69 &&
            eyebrowRatio <= 0.75); // Your data: 0.698, 0.743

    // Multiple angry detection paths based on your patterns

    // Path 1: Strong asymmetric angry - one eye squinting + low smile
    bool asymmetricAngry = oneEyeSquinting && lowSmile;

    // Path 2: Classic squinting angry - strong eye asymmetry + low smile + mouth tension
    bool squintingAngry = strongEyeAsymmetry && lowSmile && mouthTense;

    // Path 3: Moderate angry - moderate asymmetry + very low smile + eyebrows
    bool moderateAngry = moderateEyeAsymmetry && veryLowSmile && eyebrowsAngry;

    // Path 4: Subtle angry - low smile + mouth tension + eyebrow position
    bool subtleAngry = lowSmile && mouthTense && eyebrowsAngry;

    // Path 5: Intense stare - very uneven eyes + any low smile
    bool intenseStare = eyeAsymmetry > 0.5 && smile < 0.2;

    bool isAngry =
        asymmetricAngry ||
        squintingAngry && moderateAngry ||
        subtleAngry ||
        intenseStare;

    debugPrint('''
[Angry Check - Updated] Smile: $lowSmile ($smile) | VeryLowSmile: $veryLowSmile |
EyeAsymmetry: ${eyeAsymmetry.toStringAsFixed(3)} | StrongAsymmetry: $strongEyeAsymmetry | 
ModerateAsymmetry: $moderateEyeAsymmetry | OneEyeSquinting: $oneEyeSquinting |
MouthTense: $mouthTense ($mouthRatio) | EyebrowsAngry: $eyebrowsAngry ($eyebrowRatio) |
Paths: Asymmetric=$asymmetricAngry | Squinting=$squintingAngry | Moderate=$moderateAngry | 
Subtle=$subtleAngry | IntenseStare=$intenseStare | RESULT: $isAngry''');

    return isAngry;
  }

  bool _isSad(Face face) {
    final smile = face.smilingProbability ?? 0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;
    final mouthRatio = _getMouthAspectRatio(face);

    // Primary sad indicators
    bool veryLowSmile = smile < 0.05; // Very low smile
    bool lowSmile = smile < SAD_SMILE_MAX;
    bool veryDroopyEyes = avgEyeOpen < 0.1; // Almost closed eyes
    bool droopyEyes = avgEyeOpen < 0.4; // Droopy but not closed
    bool mouthDown = mouthRatio != null && mouthRatio < SAD_MOUTH_RATIO;

    // Strong sad detection - very low smile + very droopy eyes
    bool strongSad = veryLowSmile && veryDroopyEyes;

    // Moderate sad detection - low smile + droopy features
    bool moderateSad = lowSmile && (droopyEyes || mouthDown);

    // Weak sad detection - very low smile + any droopy feature
    bool weakSad =
        veryLowSmile &&
        (avgEyeOpen < 0.6 || (mouthRatio != null && mouthRatio < 0.95));

    bool isSad = strongSad || moderateSad && weakSad;

    debugPrint('''
[Sad Check] VeryLowSmile: $veryLowSmile ($smile) | LowSmile: $lowSmile | 
VeryDroopyEyes: $veryDroopyEyes ($avgEyeOpen) | DroopyEyes: $droopyEyes |
Mouth: $mouthDown ($mouthRatio) | Strong: $strongSad | Moderate: $moderateSad | 
Weak: $weakSad | Result: $isSad''');

    return isSad;
  }

  bool _isSurprised(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;
    final mouthAspectRatio = _getMouthAspectRatio(face);
    final eyebrowRatio = _getEyebrowEyeRatio(face);
    final smile = face.smilingProbability ?? 0;
    final mouthRatio = _getMouthCornerRatio(face);

    // Surprised indicators based on your data patterns
    bool veryWideEyes =
        avgEyeOpen > 0.95; // Very wide eyes (your data: 0.997, 0.997)
    bool wideEyes = avgEyeOpen > 0.85; // Wide eyes
    bool veryLowSmile =
        smile < 0.03; // Very low smile (your data: 0.021, 0.012)
    bool mouthVeryOpen =
        mouthAspectRatio != null &&
        mouthAspectRatio > 1.3; // High mouth aspect (your data: 1.42, 1.44)

    bool mouthOpen = mouthAspectRatio != null && mouthAspectRatio > 1.4;
    bool mouthWide =
        mouthRatio != null &&
        mouthRatio < 2; // Low mouth corner ratio (your data: 2.11, 1.99)
    bool eyebrowsNormal =
        eyebrowRatio != null &&
        eyebrowRatio > 0.7 &&
        eyebrowRatio < 0.75; // Your data: 0.72, 0.727

    // Multiple surprised detection paths
    // Path 1: Classic surprised - very wide eyes + very open mouth + very low smile
    bool classicSurprised = veryWideEyes && mouthVeryOpen && veryLowSmile;

    // Path 2: Wide-eyed surprised - very wide eyes + open mouth + low smile
    bool wideEyedSurprised = veryWideEyes && mouthOpen && smile < 0.05;

    // Path 3: Mouth-focused surprised - wide eyes + very open mouth + wide mouth shape
    bool mouthSurprised = wideEyes && mouthVeryOpen && mouthWide;

    // Path 4: Subtle surprised - very wide eyes + low smile + normal eyebrows
    bool subtleSurprised = veryWideEyes && veryLowSmile && eyebrowsNormal;

    bool isSurprised =
        classicSurprised && wideEyedSurprised ||
        mouthSurprised && subtleSurprised;

    debugPrint('''
[Surprised Check] VeryWideEyes: $veryWideEyes ($avgEyeOpen) | WideEyes: $wideEyes | 
VeryLowSmile: $veryLowSmile ($smile) | MouthVeryOpen: $mouthVeryOpen ($mouthAspectRatio) | 
MouthOpen: $mouthOpen | MouthWide: $mouthWide ($mouthRatio) | EyebrowsNormal: $eyebrowsNormal ($eyebrowRatio) |
Classic: $classicSurprised | WideEyed: $wideEyedSurprised | Mouth: $mouthSurprised | 
Subtle: $subtleSurprised | Result: $isSurprised''');

    return isSurprised;
  }

  bool _isSleepy(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;
    final smile = face.smilingProbability ?? 0;

    // Sleepy detection based on your data patterns
    bool veryDroopyEyes =
        avgEyeOpen < 0.15; // Very low eyes (your data: 0.12, 0.054)
    bool droopyEyes = avgEyeOpen < 0.3; // Moderately droopy
    bool veryLowSmile =
        smile < 0.02; // Very low smile (your data: 0.008, 0.006)
    bool lowSmile = smile < 0.1; // Low smile
    bool eyeAsymmetryHigh =
        (leftEyeOpen - rightEyeOpen).abs() > 0.15; // One eye more closed

    // Multiple sleepy detection paths
    // Path 1: Very sleepy - very droopy eyes + very low smile
    bool verySleepy = veryDroopyEyes && veryLowSmile;

    // Path 2: Moderate sleepy - droopy eyes + low smile
    bool moderateSleepy = droopyEyes && lowSmile;

    // Path 3: Asymmetric sleepy - one eye much more closed + low smile
    bool asymmetricSleepy = eyeAsymmetryHigh && avgEyeOpen < 0.25 && lowSmile;

    bool isSleepy = verySleepy || moderateSleepy || asymmetricSleepy;

    debugPrint('''
[Sleepy Check] VeryDroopy: $veryDroopyEyes ($avgEyeOpen) | Droopy: $droopyEyes | 
VeryLowSmile: $veryLowSmile ($smile) | LowSmile: $lowSmile | 
EyeAsymmetry: $eyeAsymmetryHigh | Very: $verySleepy | Moderate: $moderateSleepy | 
Asymmetric: $asymmetricSleepy | Result: $isSleepy''');

    return isSleepy;
  }

  GameExpression? getCurrentDetectedExpression(Face face) {
    if (!isFacingCamera(face)) return null;

    debugPrint('''
[Landmark Detection]
Smile Prob: ${face.smilingProbability}
Left Eye: ${face.leftEyeOpenProbability}
Right Eye: ${face.rightEyeOpenProbability}
Avg Eye Open: ${((face.leftEyeOpenProbability ?? 0) + (face.rightEyeOpenProbability ?? 0)) / 2}
Eye Asymmetry: ${_getEyeAsymmetry(face).toStringAsFixed(3)}
Mouth Corner Ratio: ${_getMouthCornerRatio(face)}
Eyebrow Eye Ratio: ${_getEyebrowEyeRatio(face)}
Mouth Aspect Ratio: ${_getMouthAspectRatio(face)}
''');

    final smile = face.smilingProbability ?? 0;
    final avgEyeOpen =
        ((face.leftEyeOpenProbability ?? 0) +
            (face.rightEyeOpenProbability ?? 0)) /
        2;
    final mouthAspectRatio = _getMouthAspectRatio(face);
    final eyeAsymmetry = _getEyeAsymmetry(face);

    // Prioritize angry detection for strong eye asymmetry patterns
    if (eyeAsymmetry > 0.3 && smile < 0.15) {
      if (_isAngry(face)) return GameExpression.marah;
    }

    // Check neutral first since it has specific requirements
    if (_isNeutral(face)) return GameExpression.netral;

    // Check smile early for clear positive expressions
    if (_isSmiling(face)) return GameExpression.senyum;

    // Prioritize surprised for very wide eyes + open mouth
    if (avgEyeOpen > 0.95 &&
        mouthAspectRatio != null &&
        mouthAspectRatio > 1.3) {
      if (_isSurprised(face)) return GameExpression.kaget;
    }

    // Prioritize sleepy for very low eyes + very low smile
    if (avgEyeOpen < 0.15 && smile < 0.02) {
      if (_isSleepy(face)) return GameExpression.ngantuk;
    }

    // Check angry again with broader conditions
    if (_isAngry(face)) return GameExpression.marah;

    // Prioritize sad for very low smile + low eyes
    if (smile < 0.05) {
      if (_isSad(face)) return GameExpression.sedih;
    }

    // Check other expressions
    if (_isSurprised(face)) return GameExpression.kaget;
    if (_isSleepy(face)) return GameExpression.ngantuk;
    if (_isSad(face)) return GameExpression.sedih;

    return null;
  }

  bool matchesExpression(Face face, GameExpression expr) {
    if (!isFacingCamera(face)) return false;

    switch (expr) {
      case GameExpression.senyum:
        return _isSmiling(face);
      case GameExpression.netral:
        return _isNeutral(face);
      case GameExpression.marah:
        return _isAngry(face);
      case GameExpression.sedih:
        return _isSad(face);
      case GameExpression.kaget:
        return _isSurprised(face);
      case GameExpression.ngantuk:
        return _isSleepy(face);
    }
  }

  /// Validate if user is smiling for share functionality
  bool isValidForSharing(Face face) {
    if (!isFacingCamera(face)) return false;
    return _isSmiling(face);
  }

  /// Helper method to check if head is in stable position
  bool _isHeadStable(Face face) {
    final angleY = face.headEulerAngleY;
    final angleZ = face.headEulerAngleZ;

    if (angleY == null || angleZ == null) return true;

    // Head is stable if angles are small
    return angleY.abs() < 15 && angleZ.abs() < 15;
  }

  /// Helper method to check if head is tilted down
  bool _isHeadTiltedDown(Face face) {
    final angleX = face.headEulerAngleX;

    if (angleX == null) return false;

    // Head tilted down if positive X angle (looking down)
    return angleX > 5;
  }

  /// Calculate mouth corner ratio for additional expression analysis
  double? _calculateMouthCornerRatio(Face face) {
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    if (leftMouth == null || rightMouth == null || bottomMouth == null) {
      return null;
    }

    final mouthWidth = (rightMouth.x - leftMouth.x).abs();
    final leftCornerHeight = (leftMouth.y - bottomMouth.y).abs();
    final rightCornerHeight = (rightMouth.y - bottomMouth.y).abs();
    final avgCornerHeight = (leftCornerHeight + rightCornerHeight) / 2;

    return mouthWidth / (avgCornerHeight + 1);
  }
}
