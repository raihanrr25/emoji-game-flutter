import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../face_detection/domain/services/camera_service.dart';
import '../../../face_detection/domain/services/face_detector_service.dart';

class VictoryPage extends StatefulWidget {
  const VictoryPage({super.key});

  @override
  State<VictoryPage> createState() => _VictoryPageState();
}

class _VictoryPageState extends State<VictoryPage>
    with TickerProviderStateMixin {
  // Services
  final CameraService _cameraService = CameraService();
  final FaceDetectorService _faceDetectorService = FaceDetectorService();

  // State variables
  bool isDetecting = false;
  bool isSmileDetected = false;
  bool isCapturing = false;
  String statusText = 'Senyum untuk mengambil foto! 😊';
  Color statusColor = Colors.white;

  // Face metrics
  double? smilingProbability;
  bool _hasShownCaptureDialog = false;

  // Animation controllers
  late AnimationController _congratsAnimationController;
  late AnimationController _smileAnimationController;
  late Animation<double> _congratsAnimation;
  late Animation<double> _smileAnimation;

  // Smile detection threshold
  static const double _smileThreshold = 0.7;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    _congratsAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _smileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _congratsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _congratsAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _smileAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _smileAnimationController,
        curve: Curves.elasticInOut,
      ),
    );

    _congratsAnimationController.forward();
  }

  Future<void> _initializeServices() async {
    try {
      await _cameraService.initializeCamera();
      if (mounted) {
        setState(() {});
        _startSmileDetection();
      }
    } catch (e) {
      print('[Victory] Error initializing camera: $e');
      setState(() {
        statusText = 'Error initializing camera';
        statusColor = Colors.red;
      });
    }
  }

  void _startSmileDetection() {
    if (_cameraService.isInitialized) {
      _cameraService.cameraController.startImageStream((CameraImage image) {
        if (!isDetecting && !isCapturing && !_hasShownCaptureDialog) {
          isDetecting = true;
          _processCameraImage(image).then((_) {
            isDetecting = false;
          });
        }
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (isCapturing || _hasShownCaptureDialog) return;

    try {
      final inputImage = _cameraService.getInputImageFromCameraImage(image);
      final faces = await _faceDetectorService.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        if (faces.isNotEmpty) {
          final face = faces.first;
          smilingProbability = face.smilingProbability;

          bool currentlySmiling = (smilingProbability ?? 0) >= _smileThreshold;

          if (currentlySmiling && !isSmileDetected) {
            isSmileDetected = true;
            statusText = 'Senyum terdeteksi! Mengambil foto... 📸';
            statusColor = Colors.greenAccent;
            _smileAnimationController.forward();
            _captureSmilePhoto();
          } else if (!currentlySmiling && isSmileDetected) {
            isSmileDetected = false;
            statusText = 'Senyum untuk mengambil foto! 😊';
            statusColor = Colors.white;
            _smileAnimationController.reverse();
          }

          if (!currentlySmiling) {
            statusText = 'Senyum untuk mengambil foto! 😊';
            statusColor = Colors.white;
          }
        } else {
          smilingProbability = null;
          statusText = 'Wajah tidak terdeteksi. Posisikan wajah di kamera!';
          statusColor = Colors.orange;
        }
      });
    } catch (e) {
      print('[Victory] Error processing camera image: $e');
    }
  }

  Future<void> _captureSmilePhoto() async {
    if (isCapturing || _hasShownCaptureDialog) return;

    setState(() {
      isCapturing = true;
      statusText = 'Mengambil foto... 📸';
      statusColor = Colors.blue;
    });

    try {
      // Stop image stream before capture
      await _cameraService.cameraController.stopImageStream();

      // Small delay for better capture timing
      await Future.delayed(const Duration(milliseconds: 500));

      final XFile photo = await _cameraService.cameraController.takePicture();

      setState(() {
        statusText = 'Foto berhasil diambil! 🎉';
        statusColor = Colors.greenAccent;
        _hasShownCaptureDialog = true;
      });

      // Show share dialog
      _showShareDialog(photo.path);
    } catch (e) {
      print('[Victory] Error capturing photo: $e');
      setState(() {
        statusText = 'Gagal mengambil foto. Coba lagi!';
        statusColor = Colors.red;
        isCapturing = false;
      });

      // Restart image stream if capture failed
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_hasShownCaptureDialog) {
          _startSmileDetection();
        }
      });
    }
  }

  void _showShareDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.deepPurple.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '📸 Foto Kemenangan! 🎉',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display captured image
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.amberAccent, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(imagePath), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amberAccent.withOpacity(0.2),
                        Colors.orange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '🏆 SELAMAT! 🏆',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Anda telah menyelesaikan Tantangan Ekspresi!',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Bagikan momen kemenangan Anda!',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Share Button
              TextButton.icon(
                onPressed: () => _sharePhoto(imagePath),
                icon: const Icon(Icons.share, color: Colors.greenAccent),
                label: const Text(
                  'Bagikan',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.greenAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Take Another Photo Button
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetForNewPhoto();
                },
                icon: const Icon(Icons.camera_alt, color: Colors.amberAccent),
                label: const Text(
                  'Foto Lagi',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amberAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Home Button
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous page
                },
                icon: const Icon(Icons.home, color: Colors.white70),
                label: const Text(
                  'Home',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _sharePhoto(String imagePath) async {
    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text:
            '🎉 Saya telah menyelesaikan Tantangan Ekspresi! 🏆\n\n'
            'Berhasil menunjukkan semua ekspresi dengan sempurna! 😊\n\n'
            '#TantanganEkspresi #GameEkspresi #Victory',
      );
    } catch (e) {
      print('[Victory] Error sharing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membagikan foto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForNewPhoto() {
    setState(() {
      _hasShownCaptureDialog = false;
      isCapturing = false;
      isSmileDetected = false;
      statusText = 'Senyum untuk mengambil foto! 😊';
      statusColor = Colors.white;
      smilingProbability = null;
    });

    _smileAnimationController.reset();

    // Restart smile detection
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startSmileDetection();
      }
    });
  }

  @override
  void dispose() {
    _congratsAnimationController.dispose();
    _smileAnimationController.dispose();

    // Stop camera stream
    if (_cameraService.isInitialized) {
      try {
        _cameraService.cameraController.stopImageStream();
      } catch (e) {
        print('[Victory] Error stopping camera stream: $e');
      }
    }

    _faceDetectorService.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          "🏆 Victory! 🏆",
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.amberAccent),
        elevation: 0,
      ),
      body:
          _cameraService.isInitialized
              ? Stack(
                children: [
                  // Camera Preview
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio:
                          _cameraService.cameraController.value.aspectRatio,
                      child: CameraPreview(_cameraService.cameraController),
                    ),
                  ),

                  // Congratulations Overlay
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _congratsAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _congratsAnimation.value,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amberAccent.withOpacity(0.9),
                                  Colors.orange.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amberAccent.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  '🎉 SELAMAT! 🎉',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Anda telah menyelesaikan\nTantangan Ekspresi!',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Status Panel
                  Positioned(
                    top: 200,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _smileAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isSmileDetected ? _smileAnimation.value : 1.0,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color:
                                    isSmileDetected
                                        ? Colors.greenAccent
                                        : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isSmileDetected
                                      ? Icons.camera_alt
                                      : Icons.face,
                                  color: statusColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Smile Detection Metrics
                  if (smilingProbability != null && !_hasShownCaptureDialog)
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Deteksi Senyum',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: smilingProbability! / 1.0,
                              backgroundColor: Colors.grey.shade700,
                              color:
                                  smilingProbability! >= _smileThreshold
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Senyum: ${(smilingProbability! * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color:
                                    smilingProbability! >= _smileThreshold
                                        ? Colors.greenAccent
                                        : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Threshold: ${(_smileThreshold * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Instructions
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '📷 Posisikan wajah di kamera dan berikan senyum terbaik Anda!\nFoto akan diambil secara otomatis saat senyum terdeteksi.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
              : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.amberAccent),
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
