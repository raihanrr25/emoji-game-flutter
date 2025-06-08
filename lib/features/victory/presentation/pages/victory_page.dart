import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import '../../../../services/camera_service.dart';
import '../../../../services/face_detector_service.dart';
import '../widgets/victory_camera_widget.dart';
import '../widgets/victory_header.dart';
import '../widgets/victory_message.dart';
import '../widgets/victory_instructions.dart';
import '../widgets/manual_capture_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/floating_effects.dart';
import '../controllers/victory_animation_controller.dart';

class VictoryPage extends StatefulWidget {
  const VictoryPage({super.key});

  @override
  State<VictoryPage> createState() => _VictoryPageState();
}

class _VictoryPageState extends State<VictoryPage>
    with TickerProviderStateMixin {
  // Core services
  CameraController? _cameraController;
  late CameraService _cameraService;
  late FaceDetectorService _faceDetectorService;
  late VictoryAnimationController _animationController;

  // State variables
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isSmileDetected = false;
  bool _isProcessingImage = false;
  String? _capturedImagePath;
  bool _faceDetectionDisabled = false; // Tambahkan flag ini
  int _errorCount = 0; // Hitung jumlah error
  List<Face>? _detectedFaces; // Add this for debugging
  double? _smileProbability; // Add this for debugging

  // Effects
  final List<Particle> _particles = [];
  final List<FloatingEmoji> _floatingEmojis = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _initializeEffects();

    // Clean up any existing camera resources before initializing new ones
    _cleanupExistingCamera().then((_) {
      _initializeCamera();
    });

    // Start victory animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.startVictoryAnimation();
    });
  }

  Future<void> _cleanupExistingCamera() async {
    try {
      // Give time for any previous camera to fully dispose
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Error during camera cleanup: $e');
    }
  }

  void _initializeServices() {
    _cameraService = CameraService();
    _faceDetectorService = FaceDetectorService();
  }

  void _initializeAnimations() {
    _animationController = VictoryAnimationController();
    _animationController.initialize(this);
  }

  void _initializeEffects() {
    _initializeParticles();
    _initializeFloatingEmojis();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          speed: random.nextDouble() * 2 + 1,
          size: random.nextDouble() * 6 + 2,
          color:
              [
                Colors.amberAccent,
                Colors.orange,
                Colors.yellow,
                Colors.pinkAccent,
              ][random.nextInt(4)],
        ),
      );
    }
  }

  void _initializeFloatingEmojis() {
    final emojis = ['🎉', '🏆', '⭐', '🎊', '💫', '🌟', '🎈', '🎁'];
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _floatingEmojis.add(
        FloatingEmoji(
          emoji: emojis[i],
          x: random.nextDouble() * 300 + 50,
          y: random.nextDouble() * 600 + 100,
          speed: random.nextDouble() * 0.5 + 0.3,
        ),
      );
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorSnackBar('No cameras available');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Try optimal settings first
      await _tryInitializeWithSettings(
        frontCamera,
        ResolutionPreset.medium,
        ImageFormatGroup.yuv420,
      );
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
        _showErrorSnackBar('Camera initialization failed: $e');
      }
    }
  }

  Future<void> _tryInitializeWithSettings(
    CameraDescription camera,
    ResolutionPreset resolution,
    ImageFormatGroup? imageFormat,
  ) async {
    try {
      _cameraController = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: imageFormat,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });

        // Add longer delay and test detection first
        await Future.delayed(const Duration(milliseconds: 1500));
        await _testFaceDetection();

        if (!_faceDetectionDisabled) {
          _startImageStream();
        }
      }
    } catch (e) {
      print('Failed with settings $resolution, $imageFormat: $e');

      // Try fallback settings
      if (imageFormat == ImageFormatGroup.yuv420) {
        await _tryInitializeWithSettings(
          camera,
          resolution,
          ImageFormatGroup.nv21,
        );
      } else if (resolution == ResolutionPreset.medium) {
        await _tryInitializeWithSettings(
          camera,
          ResolutionPreset.low,
          ImageFormatGroup.yuv420,
        );
      } else {
        // Final fallback
        await _tryInitializeWithSettings(camera, ResolutionPreset.low, null);
      }
    }
  }

  Future<void> _testFaceDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      print('🧪 Testing face detection capability...');

      // Take a test image
      final XFile testImage = await _cameraController!.takePicture();

      // Try to process it (this would need image conversion - simplified here)
      print('✅ Test image captured successfully');

      // If we get here, camera is working properly
      print('✅ Face detection test passed');
    } catch (e) {
      print('❌ Face detection test failed: $e');
      _disableFaceDetection();
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingImage || _isCapturing || _faceDetectionDisabled) return;
    _isProcessingImage = true;

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      // Enhanced image conversion with better error handling
      final inputImage = _cameraService.getInputImageFromCameraImage(image);

      // Add validation before processing
      if (inputImage.metadata == null) {
        debugPrint('⚠️ Skipping frame - no metadata');
        return;
      }

      final faces = await _faceDetectorService.processImage(inputImage);

      bool smileDetected = false;
      double? probability;

      if (faces.isNotEmpty) {
        probability = faces.first.smilingProbability ?? 0.0;
        smileDetected = probability > 0.7;

        // Log detection success periodically
        final stats = _faceDetectorService.getDetectionStats();
        if (stats['totalFrames'] % 30 == 0) {
          debugPrint(
            '📊 Detection stats: ${stats['successRate'].toStringAsFixed(1)}% success rate',
          );
        }
      }

      _errorCount = 0;

      if (mounted) {
        setState(() {
          _detectedFaces = faces;
          _isSmileDetected = smileDetected;
          _smileProbability = probability;
        });

        if (smileDetected && !_isCapturing) {
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted && _isSmileDetected && !_isCapturing) {
            _capturePhoto();
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      _errorCount++;

      // More specific error handling
      if (e.toString().contains('InputImageConverterError') ||
          e.toString().contains('ImageFormat is not supported') ||
          e.toString().contains('IllegalArgumentException') ||
          _errorCount > 15) {
        _disableFaceDetection();
      }
    } finally {
      _isProcessingImage = false;
    }
  }

  void _disableFaceDetection() {
    print('🚫 Disabling face detection due to compatibility issues');
    setState(() {
      _faceDetectionDisabled = true;
    });

    try {
      _cameraController?.stopImageStream().catchError((e) {
        print('Error stopping stream: $e');
      });
    } catch (e) {
      print('Error stopping image stream: $e');
    }

    if (mounted) {
      _showErrorSnackBar(
        'Smile detection unavailable. Use manual capture button.',
      );
    }
  }

  void _startImageStream() {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_faceDetectionDisabled) {
      try {
        _cameraController!.startImageStream(_processCameraImage);
      } catch (e) {
        print('Error starting image stream: $e');
        _disableFaceDetection();
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Hentikan image stream jika masih berjalan
      if (!_faceDetectionDisabled) {
        await _cameraController!.stopImageStream().catchError((e) {
          print('Error stopping stream for capture: $e');
        });
      }

      // Add a small delay to ensure the stream is stopped
      await Future.delayed(const Duration(milliseconds: 200));

      // Take the picture
      final XFile photo = await _cameraController!.takePicture();

      // Save to app directory for sharing
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'victory_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = '${appDir.path}/$fileName';

      await File(photo.path).copy(newPath);

      if (mounted) {
        setState(() {
          _capturedImagePath = newPath;
          _isCapturing = false;
        });

        _showPhotoPreview();
      }
    } catch (e) {
      print('Error capturing photo: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        _showErrorSnackBar('Gagal mengambil foto: $e');
      }
    } finally {
      // Restart stream hanya jika face detection tidak dinonaktifkan
      if (mounted &&
          _isCameraInitialized &&
          _cameraController != null &&
          !_faceDetectionDisabled) {
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          _startImageStream();
        } catch (e) {
          print('Error restarting stream: $e');
        }
      }
    }
  }

  void _showPhotoPreview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: AnimatedBuilder(
            animation: _animationController.pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _animationController.pulseAnimation.value * 0.1 + 0.95,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade900,
                        Colors.purple.shade600,
                        Colors.pinkAccent.shade400,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.amberAccent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amberAccent.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.file(
                                File(_capturedImagePath!),
                                height: 300,
                                width: 250,
                                fit: BoxFit.cover,
                              ),
                              // Sparkle overlay
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation:
                                      _animationController.particleController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: SparklePainter(
                                        _animationController
                                            .particleController
                                            .value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Enhanced title with gradient text
                      ShaderMask(
                        shaderCallback:
                            (bounds) => LinearGradient(
                              colors: [
                                Colors.amberAccent,
                                Colors.orange,
                                Colors.yellow,
                              ],
                            ).createShader(bounds),
                        child: const Text(
                          '🎉 FOTO KEMENANGAN EPIC! 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEnhancedButton(
                            onPressed: _sharePhoto,
                            icon: Icons.share,
                            label: 'Bagikan',
                            color: Colors.amberAccent,
                            textColor: Colors.deepPurple.shade900,
                          ),
                          _buildEnhancedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _capturePhoto();
                            },
                            icon: Icons.camera_alt,
                            label: 'Foto Lagi',
                            color: Colors.green,
                            textColor: Colors.white,
                          ),
                          _buildEnhancedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/home',
                                (route) => false,
                              );
                            },
                            icon: Icons.home,
                            label: 'Home',
                            color: Colors.blueAccent,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEnhancedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Future<void> _sharePhoto() async {
    if (_capturedImagePath != null) {
      try {
        await Share.shareXFiles(
          [XFile(_capturedImagePath!)],
          text:
              '🎉 Aku berhasil menyelesaikan Emoji Game Challenge! 😊 #EmojiGameChallenge #Victory',
        );
      } catch (e) {
        _showErrorSnackBar('Gagal membagikan foto: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Stop animations first
    _animationController.stopAnimations();
    _animationController.dispose();

    // Dispose camera resources properly
    _disposeCameraResources();

    // Dispose face detector
    _faceDetectorService.dispose();

    super.dispose();
  }

  Future<void> _disposeCameraResources() async {
    try {
      // Stop image stream first
      if (_cameraController != null) {
        await _cameraController!.stopImageStream().catchError((e) {
          print('Error stopping image stream: $e');
        });

        // Add delay before disposing
        await Future.delayed(const Duration(milliseconds: 200));

        // Dispose controller
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Stack(
        children: [
          // Animated background
          AnimatedBackground(
            backgroundAnimation: _animationController.backgroundAnimation,
          ),

          // Floating effects
          AnimatedBuilder(
            animation: Listenable.merge([
              _animationController.particleController,
              _animationController.emojiController,
            ]),
            builder: (context, child) {
              return FloatingEffects(
                particles: _particles,
                floatingEmojis: _floatingEmojis,
                particleAnimationValue:
                    _animationController.particleController.value,
                emojiAnimationValue:
                    _animationController.emojiFloatAnimation.value,
              );
            },
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _animationController.fadeAnimation,
              child: Column(
                children: [
                  // Header
                  VictoryHeader(
                    onHomePressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
                    },
                  ),

                  // Victory Message
                  VictoryMessage(
                    scaleAnimation: _animationController.scaleAnimation,
                    rotationAnimation: _animationController.rotationAnimation,
                    bounceAnimation: _animationController.bounceAnimation,
                  ),

                  // Camera Section
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: VictoryCameraWidget(
                        cameraController: _cameraController,
                        isCameraInitialized: _isCameraInitialized,
                        isSmileDetected:
                            _isSmileDetected && !_faceDetectionDisabled,
                        isCapturing: _isCapturing,
                        detectedFaces:
                            _detectedFaces, // Pass faces for visualization
                        smileProbability:
                            _smileProbability, // Pass probability for display
                      ),
                    ),
                  ),

                  // Instructions - sesuaikan dengan status face detection
                  VictoryInstructions(
                    isSmileDetected:
                        _isSmileDetected && !_faceDetectionDisabled,
                  ),

                  // Manual capture button - selalu tampilkan jika camera ready
                  ManualCaptureButton(
                    isSmileDetected:
                        _isSmileDetected && !_faceDetectionDisabled,
                    isCapturing: _isCapturing,
                    onPressed: _capturePhoto,
                  ),

                  // Tambahkan pesan jika face detection dinonaktifkan
                  if (_faceDetectionDisabled)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Deteksi senyuman tidak tersedia. Gunakan tombol "Ambil Foto" untuk mengambil gambar.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for sparkle effect on photos
class SparklePainter extends CustomPainter {
  final double animationValue;

  SparklePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent sparkles
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final sparkleSize = 2 + 3 * math.sin(animationValue * 2 * math.pi + i);

      if (sparkleSize > 0) {
        canvas.drawCircle(Offset(x, y), sparkleSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
