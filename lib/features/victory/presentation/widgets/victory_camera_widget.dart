import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class VictoryCameraWidget extends StatelessWidget {
  final CameraController? cameraController;
  final bool isCameraInitialized;
  final bool isSmileDetected;
  final bool isCapturing;
  final List<Face>? detectedFaces;
  final double? smileProbability;

  const VictoryCameraWidget({
    Key? key,
    required this.cameraController,
    required this.isCameraInitialized,
    required this.isSmileDetected,
    required this.isCapturing,
    this.detectedFaces,
    this.smileProbability,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSmileDetected ? Colors.green : Colors.amber,
          width: isSmileDetected ? 4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isSmileDetected
                    ? Colors.green.withOpacity(0.5)
                    : Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Camera preview or placeholder
            Positioned.fill(child: _buildCameraPreview()),

            // Face detection overlay
            if (detectedFaces != null && detectedFaces!.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: FaceDetectionPainter(
                    faces: detectedFaces!,
                    imageSize: Size(
                      cameraController?.value.previewSize?.width ?? 1,
                      cameraController?.value.previewSize?.height ?? 1,
                    ),
                    previewSize: MediaQuery.of(context).size,
                    cameraLensDirection:
                        cameraController?.description.lensDirection,
                  ),
                ),
              ),

            // Status indicators
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: _buildStatusIndicators(),
            ),

            // "Capturing" overlay
            if (isCapturing)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (isCameraInitialized && cameraController != null) {
      return CameraPreview(cameraController!);
    } else {
      return Container(
        color: Colors.black26,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Mempersiapkan kamera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatusIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debug info container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Face detection status
              Row(
                children: [
                  Icon(
                    detectedFaces != null && detectedFaces!.isNotEmpty
                        ? Icons.face_retouching_natural
                        : Icons.face_retouching_off,
                    color:
                        detectedFaces != null && detectedFaces!.isNotEmpty
                            ? Colors.green
                            : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    detectedFaces != null && detectedFaces!.isNotEmpty
                        ? 'Wajah terdeteksi: ${detectedFaces!.length}'
                        : 'Wajah tidak terdeteksi',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Smile status
              Row(
                children: [
                  Icon(
                    isSmileDetected
                        ? Icons.sentiment_very_satisfied
                        : Icons.sentiment_neutral,
                    color: isSmileDetected ? Colors.amber : Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Senyum: ${smileProbability != null ? (smileProbability! * 100).toStringAsFixed(1) + '%' : 'N/A'}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FaceDetectionPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size previewSize;
  final CameraLensDirection? cameraLensDirection;

  FaceDetectionPainter({
    required this.faces,
    required this.imageSize,
    required this.previewSize,
    this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.green;

    final Paint textBackgroundPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black54;

    final textStyle = const TextStyle(color: Colors.white, fontSize: 12);

    for (final Face face in faces) {
      // Transform face rectangle to the preview coordinates
      final rect = _scaleRect(
        rect: face.boundingBox,
        imageSize: imageSize,
        previewSize: size,
        flipX: cameraLensDirection == CameraLensDirection.front,
      );

      // Draw face rectangle
      canvas.drawRect(rect, paint);

      // Draw smile probability if available
      if (face.smilingProbability != null) {
        final smileText =
            'Smile: ${(face.smilingProbability! * 100).toStringAsFixed(0)}%';
        final textSpan = TextSpan(text: smileText, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Background for text
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left,
            rect.bottom + 5,
            textPainter.width + 10,
            textPainter.height + 10,
          ),
          textBackgroundPaint,
        );

        // Text
        textPainter.paint(canvas, Offset(rect.left + 5, rect.bottom + 10));
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectionPainter oldDelegate) {
    return oldDelegate.faces != faces;
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size previewSize,
    bool flipX = false,
  }) {
    // Handle image rotation for front camera
    final double scaleX =
        previewSize.width / (flipX ? imageSize.height : imageSize.width);
    final double scaleY =
        previewSize.height / (flipX ? imageSize.width : imageSize.height);

    if (flipX) {
      // For front camera with rotated view
      final double translatedLeft = imageSize.width - rect.right;
      return Rect.fromLTWH(
        translatedLeft * scaleX,
        rect.top * scaleY,
        rect.width * scaleX,
        rect.height * scaleY,
      );
    } else {
      // For back camera or standard view
      return Rect.fromLTWH(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.width * scaleX,
        rect.height * scaleY,
      );
    }
  }
}
