// lib/features/victory/presentation/pages/victory_page.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import '../../../../services/camera_service.dart';
import '../../../../services/face_detector_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/floating_effects.dart';

class VictoryPage extends StatefulWidget {
  const VictoryPage({super.key});

  @override
  State<VictoryPage> createState() => _VictoryPageState();
}

class _VictoryPageState extends State<VictoryPage>
    with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final FaceDetectorService _faceDetectorService = FaceDetectorService();

  late AnimationController _backgroundController;
  late AnimationController _particleController;

  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isSmileDetected = false;
  bool _isProcessingImage = false;
  String? _capturedImagePath;

  final List<Particle> _particles = [];
  final List<FloatingEmoji> _floatingEmojis = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeEffects();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  void _initializeEffects() {
    final random = math.Random();
    const a = ['🎉', '🏆', '⭐', '🎊', '💫', '🌟', '🎈', '🎁'];
    for (int i = 0; i < 50; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble() * 500,
          y: random.nextDouble() * 1000,
          speed: random.nextDouble() * 2 + 1,
          size: random.nextDouble() * 4 + 2,
          color:
              [
                Colors.yellow.shade200,
                Colors.pink.shade200,
                Colors.cyan.shade200,
              ][random.nextInt(3)],
        ),
      );
    }
    for (int i = 0; i < 10; i++) {
      _floatingEmojis.add(
        FloatingEmoji(
          emoji: a[random.nextInt(a.length)],
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          speed: random.nextDouble() * 0.5 + 0.3,
        ),
      );
    }
  }

  Future<void> _initializeCamera() async {
    bool initialized = await _cameraService.initializeCamera();
    if (initialized && mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
      _startImageStream();
    }
  }

  void _startImageStream() {
    if (_isCameraInitialized) {
      _cameraService.cameraController.startImageStream((image) {
        if (_isProcessingImage || _isCapturing) return;
        _isProcessingImage = true;
        _processCameraImage(
          image,
        ).whenComplete(() => _isProcessingImage = false);
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final inputImage = _cameraService.getInputImageFromCameraImage(image);
    final faces = await _faceDetectorService.processImage(inputImage);

    if (faces.isNotEmpty) {
      final smileProb = faces.first.smilingProbability ?? 0.0;
      final detected = smileProb > 0.8;
      if (detected != _isSmileDetected) {
        setState(() {
          _isSmileDetected = detected;
        });
      }
      if (detected && !_isCapturing) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_isSmileDetected) _capturePhoto();
      }
    } else {
      if (_isSmileDetected)
        setState(() {
          _isSmileDetected = false;
        });
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });
    await _cameraService.cameraController.stopImageStream();

    final XFile photo = await _cameraService.cameraController.takePicture();
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String newPath =
        '${appDir.path}/victory_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(photo.path).copy(newPath);

    if (mounted) {
      setState(() {
        _capturedImagePath = newPath;
        _isCapturing = false;
      });
      _showPhotoPreview();
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _particleController.dispose();
    _cameraService.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(backgroundAnimation: _backgroundController),
          FloatingEffects(
            particles: _particles,
            floatingEmojis: _floatingEmojis,
            particleAnimationValue: _particleController.value,
            emojiAnimationValue: _particleController.value,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCameraView(),
                  const SizedBox(height: 20),
                  _buildInstructionPanel(),
                  const SizedBox(height: 20),
                  if (!_isSmileDetected) _buildManualCaptureButton(),
                ],
              ),
            ),
          ),
          if (_isCapturing) _buildCaptureOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGlassButton(
          icon: Icons.home_filled,
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
        const Text(
          "FOTO KEMENANGAN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(width: 48),
      ],
    );
  }

  Widget _buildCameraView() {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
                _isSmileDetected
                    ? Colors.cyanAccent
                    : Colors.white.withOpacity(0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _isSmileDetected
                      ? Colors.cyanAccent.withOpacity(0.5)
                      : Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child:
              _isCameraInitialized
                  ? CameraPreview(_cameraService.cameraController)
                  : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
        ),
      ),
    );
  }

  Widget _buildInstructionPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder:
                (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
            child:
                _isSmileDetected
                    ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.cyanAccent),
                        SizedBox(width: 12),
                        Text(
                          "SENYUM TERDETEKSI!",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                    : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.white70),
                        SizedBox(width: 12),
                        Text(
                          "Senyum untuk mengambil foto",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualCaptureButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.camera),
      label: Text("Ambil Foto Manual"),
      onPressed: _capturePhoto,
      style: ElevatedButton.styleFrom(
        foregroundColor: Color(0xFF764ba2),
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildCaptureOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Mengambil gambar...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showPhotoPreview() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.grey[900]?.withOpacity(0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
            ),
            contentPadding: EdgeInsets.all(16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Kemenangan!",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(_capturedImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Bagikan momen epik ini!",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: Text('Tutup'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _startImageStream(); // Resume camera stream
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white54),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.share),
                      label: Text('Bagikan'),
                      onPressed: () async {
                        await Share.shareXFiles([
                          XFile(_capturedImagePath!),
                        ], text: 'Aku menang di Emoji Game Challenge!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
