import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';

/// Service for handling camera operations
class CameraService {
  late CameraController cameraController;
  bool isInitialized = false;

  /// Initialize the camera
  Future<bool> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController.initialize();
      isInitialized = true;
      return true;
    } catch (e) {
      isInitialized = false;
      return false;
    }
  }

  InputImage getInputImageFromCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg,
        format: InputImageFormat.yuv420, // Try yuv420 instead of nv21
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  InputImage _convertAndroidImage(
    CameraImage image,
    InputImageRotation rotation,
  ) {
    // For Android, handle NV21 and YUV420 formats
    if (image.format.group == ImageFormatGroup.nv21 ||
        image.format.group == ImageFormatGroup.yuv420) {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: _getInputImageFormat(image.format.group),
          bytesPerRow:
              image.planes.isNotEmpty
                  ? image.planes[0].bytesPerRow
                  : image.width,
        ),
      );
    } else {
      // Fallback for other formats
      return _convertGenericImage(image, rotation);
    }
  }

  InputImage _convertIOSImage(CameraImage image, InputImageRotation rotation) {
    // For iOS, typically BGRA8888 format
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow:
            image.planes.isNotEmpty
                ? image.planes[0].bytesPerRow
                : image.width * 4,
      ),
    );
  }

  InputImage _convertGenericImage(
    CameraImage image,
    InputImageRotation rotation,
  ) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21, // Default fallback
        bytesPerRow:
            image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width,
      ),
    );
  }

  InputImageRotation _getRotationCorrection() {
    // Front camera typically needs different rotation
    if (Platform.isAndroid) {
      return InputImageRotation.rotation270deg;
    } else {
      return InputImageRotation.rotation90deg;
    }
  }

  InputImageFormat _getInputImageFormat(ImageFormatGroup formatGroup) {
    switch (formatGroup) {
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        return InputImageFormat.nv21;
    }
  }

  /// Dispose camera resources
  void dispose() {
    if (isInitialized) {
      cameraController.dispose();
      isInitialized = false;
    }
  }
}
