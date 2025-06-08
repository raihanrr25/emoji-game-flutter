import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';

class FaceDetectorService {
  final FaceDetector _faceDetector;
  int _consecutiveNoFaces = 0;
  int _frameCount = 0;
  int _successfulDetections = 0;
  int _totalFrames = 0;

  FaceDetectorService()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false, // Disable for better performance
          enableLandmarks: false, // Disable for better performance
          enableClassification: true, // Keep for smile detection
          enableTracking: false, // Disable for better performance
          minFaceSize: 0.1, // Increase minimum face size
          performanceMode: FaceDetectorMode.fast, // Use fast mode
        ),
      );

  Future<List<Face>> processImage(InputImage? inputImage) async {
    if (inputImage == null) {
      debugPrint('Input image is null');
      _consecutiveNoFaces++;
      return [];
    }

    _frameCount++;
    try {
      // Validate image metadata
      if (!_validateImageMetadata(inputImage)) {
        debugPrint('Invalid image metadata, skipping detection');
        return [];
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _consecutiveNoFaces++;

        // Enhanced diagnostic logging
        if (_consecutiveNoFaces % 30 == 0) {
          debugPrint('=== FACE DETECTION DIAGNOSTICS ===');
          debugPrint('Consecutive no faces: $_consecutiveNoFaces');
          debugPrint('Total frames processed: $_frameCount');
          debugPrint('Successful detections: $_successfulDetections');
          debugPrint(
            'Success rate: ${(_successfulDetections / _frameCount * 100).toStringAsFixed(1)}%',
          );

          if (inputImage.metadata != null) {
            final metadata = inputImage.metadata!;
            debugPrint(
              'Image size: ${metadata.size.width}x${metadata.size.height}',
            );
            debugPrint('Image rotation: ${metadata.rotation}');
            debugPrint('Image format: ${metadata.format}');
            debugPrint('Bytes per row: ${metadata.bytesPerRow}');
          }

          debugPrint('=== END DIAGNOSTICS ===');
        }
      } else {
        _consecutiveNoFaces = 0;
        _successfulDetections++;

        // Log successful detection details
        debugPrint('✅ Face detection successful! Found ${faces.length} faces');

        for (int i = 0; i < faces.length; i++) {
          final face = faces[i];
          final bounds = face.boundingBox;
          final smileProb = getSmileProbability(face);

          debugPrint('Face $i:');
          debugPrint(
            '  - Bounds: (${bounds.left.toInt()}, ${bounds.top.toInt()}) - (${bounds.right.toInt()}, ${bounds.bottom.toInt()})',
          );
          debugPrint(
            '  - Size: ${bounds.width.toInt()}x${bounds.height.toInt()}',
          );
          debugPrint(
            '  - Smile probability: ${(smileProb * 100).toStringAsFixed(1)}%',
          );
          debugPrint(
            '  - Head angles: Y=${face.headEulerAngleY?.toStringAsFixed(1)}°, Z=${face.headEulerAngleZ?.toStringAsFixed(1)}°',
          );
        }
      }

      return faces;
    } catch (e) {
      debugPrint('❌ Error processing image: $e');

      // Check for specific error types
      if (e.toString().contains('InputImageConverterError')) {
        debugPrint(
          '🔍 Image format conversion error - check image format compatibility',
        );
      } else if (e.toString().contains('IllegalArgumentException')) {
        debugPrint('🔍 Invalid image data - check image dimensions and format');
      }

      return [];
    }
  }

  Map<String, dynamic> getDetectionStats() {
    return {
      'totalFrames': _frameCount,
      'successfulDetections': _successfulDetections,
      'consecutiveNoFaces': _consecutiveNoFaces,
      'successRate':
          _frameCount > 0 ? (_successfulDetections / _frameCount * 100) : 0.0,
    };
  }

  bool _validateImageMetadata(InputImage inputImage) {
    final metadata = inputImage.metadata;
    if (metadata == null) {
      debugPrint('⚠️ No image metadata available');
      return false;
    }

    // Check if image dimensions are reasonable
    if (metadata.size.width <= 0 || metadata.size.height <= 0) {
      debugPrint(
        '⚠️ Invalid image dimensions: ${metadata.size.width}x${metadata.size.height}',
      );
      return false;
    }

    // Check if image is too small for face detection
    final minDimension =
        metadata.size.width < metadata.size.height
            ? metadata.size.width
            : metadata.size.height;

    if (minDimension < 100) {
      debugPrint(
        '⚠️ Image too small for reliable face detection: ${metadata.size.width}x${metadata.size.height}',
      );
      return false;
    }

    return true;
  }

  bool isSmiling(Face face) {
    final smileProb = face.smilingProbability ?? 0.0;
    debugPrint('😊 Smile check: ${(smileProb * 100).toStringAsFixed(1)}%');
    return smileProb > 0.2; // Lower threshold for better detection
  }

  double getSmileProbability(Face face) {
    return face.smilingProbability ?? 0.0;
  }

  void dispose() {
    debugPrint('🔧 Disposing FaceDetectorService');
    debugPrint('Final stats: ${getDetectionStats()}');
    _faceDetector.close();
  }
}
