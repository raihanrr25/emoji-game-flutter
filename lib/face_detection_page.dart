import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:async'; // Diperlukan untuk Timer
import 'dart:math'; // Diperlukan untuk Random

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({super.key});

  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

// Enum untuk ekspresi yang harus dideteksi dalam game
enum GameExpression { smile, neutral, angry }

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true, // Penting untuk probabilitas senyum/mata
      minFaceSize: 0.3,
      performanceMode:
          FaceDetectorMode.accurate, // Accurate mode untuk deteksi lebih baik
    ),
  );

  late CameraController cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool isGameStarted = false;
  bool isGameFinished = false;

  Timer? _gameTimer;
  Timer? _countdownTimer;
  int _elapsedTimeInSeconds = 0;
  int _countdownValue = 3; // Hitung mundur sebelum mulai

  // Game State
  int _currentRound = 0;
  final int _totalRounds = 5; // Jumlah putaran game
  final List<GameExpression> _availableExpressions = [
    GameExpression.smile,
    GameExpression.neutral,
    GameExpression.angry,
  ];
  final Random _random = Random();

  GameExpression _requiredExpression =
      GameExpression.smile; // Ekspresi yang saat ini dibutuhkan

  String _instructionText = 'Bersiaplah!';
  Color _instructionColor = Colors.white;
  IconData _instructionIcon = Icons.timer;

  double? _smilingProbability;
  double? _leftEyeOpenProbability; // Probabilitas mata kiri terbuka
  double? _rightEyeOpenProbability; // Probabilitas mata kanan terbuka
  double? _headEulerAngleY; // Untuk yaw (geleng kepala)
  double? _headEulerAngleZ; // Untuk roll (miring kepala)

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await cameraController.initialize();
    if (mounted) {
      setState(() {
        isCameraInitialized = true;
      });
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 0) {
        setState(() {
          _instructionText = _countdownValue.toString();
          _instructionIcon = Icons.timer;
          _instructionColor = Colors.amberAccent;
          _countdownValue--;
        });
      } else {
        _countdownTimer?.cancel();
        setState(() {
          isGameStarted = true;
          _setRandomRequiredExpression(); // Set ekspresi acak pertama
          _instructionText = _getInstructionText(_requiredExpression);
          _instructionIcon = _getExpressionIcon(_requiredExpression);
          _instructionColor = Colors.white;
        });
        _startGameTimer();
        startFaceDetection();
      }
    });
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameFinished) {
        setState(() {
          _elapsedTimeInSeconds++;
        });
      }
    });
  }

  void startFaceDetection() {
    if (isCameraInitialized) {
      cameraController.startImageStream((CameraImage image) {
        if (!isDetecting && isGameStarted && !isGameFinished) {
          isDetecting = true;
          detectFaces(image).then((_) {
            isDetecting = false;
          });
        }
      });
    }
  }

  Future<void> detectFaces(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation:
              InputImageRotation
                  .rotation270deg, // Sesuaikan jika kamera terbalik
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        if (faces.isNotEmpty) {
          final face = faces.first;
          _smilingProbability = face.smilingProbability;
          _leftEyeOpenProbability = face.leftEyeOpenProbability;
          _rightEyeOpenProbability = face.rightEyeOpenProbability;
          _headEulerAngleY = face.headEulerAngleY;
          _headEulerAngleZ = face.headEulerAngleZ;
          _checkExpression(face);
        } else {
          _instructionText = 'Wajah tidak terdeteksi!';
          _instructionColor = Colors.red;
          _instructionIcon = Icons.face_retouching_off;
        }
      });
    } catch (e) {
      debugPrint('Error in face detection: $e');
      if (mounted) {
        setState(() {
          _instructionText = 'Terjadi error deteksi wajah.';
          _instructionColor = Colors.red;
          _instructionIcon = Icons.error_outline;
        });
      }
    }
  }

  // Logika pengecekan ekspresi untuk game (diperbarui)
  void _checkExpression(Face face) {
    bool expressionMatched = false;

    // Thresholds
    const double SMILE_THRESHOLD =
        0.75; // Menurunkan sedikit agar lebih mudah senyum
    const double NEUTRAL_SMILE_MAX_THRESHOLD =
        0.2; // Menurunkan sedikit agar lebih mudah netral
    const double EYE_OPEN_THRESHOLD = 0.5; // Ambang batas mata terbuka
    const double ANGRY_YAW_THRESHOLD = 15.0; // Geleng kepala yang signifikan
    const double ANGRY_ROLL_THRESHOLD = 15.0; // Miring kepala yang signifikan

    switch (_requiredExpression) {
      case GameExpression.smile:
        if (face.smilingProbability != null &&
            face.smilingProbability! > SMILE_THRESHOLD) {
          expressionMatched = true;
          _instructionText = 'Sempurna! 😊';
          _instructionColor = Colors.greenAccent;
        } else {
          _instructionText = 'Senyum lebar! 😁';
          _instructionColor = Colors.white;
        }
        break;
      case GameExpression.neutral:
        if (face.smilingProbability != null &&
            face.smilingProbability! < NEUTRAL_SMILE_MAX_THRESHOLD &&
            (face.headEulerAngleY?.abs() ?? 0) <
                10 && // Kepala tidak terlalu geleng
            (face.headEulerAngleZ?.abs() ?? 0) <
                10 && // Kepala tidak terlalu miring
            (face.leftEyeOpenProbability ?? 1.0) >
                EYE_OPEN_THRESHOLD && // Mata relatif terbuka
            (face.rightEyeOpenProbability ?? 1.0) > EYE_OPEN_THRESHOLD) {
          // Mata relatif terbuka
          expressionMatched = true;
          _instructionText = 'Tepat! Wajah netral. 😐';
          _instructionColor = Colors.greenAccent;
        } else {
          _instructionText = 'Buat wajah Anda netral. 😑';
          _instructionColor = Colors.white;
        }
        break;
      case GameExpression.angry:
        // Inferensi marah: tidak senyum DAN ada kemiringan/geleng kepala yang jelas
        // Atau mata sedikit menyipit (probabilitas terbuka rendah)
        final bool isNotSmiling =
            face.smilingProbability != null &&
            face.smilingProbability! < NEUTRAL_SMILE_MAX_THRESHOLD;
        final bool hasSignificantHeadMovement =
            ((face.headEulerAngleY?.abs() ?? 0) > ANGRY_YAW_THRESHOLD ||
                (face.headEulerAngleZ?.abs() ?? 0) > ANGRY_ROLL_THRESHOLD);
        final bool areEyesSquinted =
            (face.leftEyeOpenProbability ?? 1.0) < EYE_OPEN_THRESHOLD &&
            (face.rightEyeOpenProbability ?? 1.0) < EYE_OPEN_THRESHOLD;

        if (isNotSmiling && (hasSignificantHeadMovement || areEyesSquinted)) {
          expressionMatched = true;
          _instructionText = 'Hebat! Wajah marah. 😠';
          _instructionColor = Colors.greenAccent;
        } else {
          _instructionText =
              'Coba buat wajah marah (kerutkan dahi, sedikit geleng/miringkan kepala, atau sipitkan mata). 😡';
          _instructionColor = Colors.white;
        }
        break;
    }

    if (expressionMatched) {
      _nextExpression();
    }
    // Ikon instruksi selalu mengikuti ekspresi yang dibutuhkan
    _instructionIcon = _getExpressionIcon(_requiredExpression);
  }

  void _setRandomRequiredExpression() {
    _requiredExpression =
        _availableExpressions[_random.nextInt(_availableExpressions.length)];
  }

  void _nextExpression() {
    _currentRound++; // Lanjut ke round berikutnya
    if (_currentRound >= _totalRounds) {
      _finishGame();
      return;
    }

    _setRandomRequiredExpression(); // Set ekspresi acak untuk round berikutnya

    // Update instruksi untuk ekspresi berikutnya
    _instructionText =
        'BERIKUTNYA: ${_getInstructionText(_requiredExpression)}';
    _instructionColor = Colors.yellowAccent; // Warna sementara untuk transisi
    _instructionIcon = _getExpressionIcon(_requiredExpression);

    // Beri jeda singkat agar user melihat instruksi berikutnya
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !isGameFinished) {
        setState(() {
          _instructionText = _getInstructionText(_requiredExpression);
          _instructionColor = Colors.white; // Kembali ke warna normal
        });
      }
    });
  }

  void _finishGame() {
    if (isGameFinished) return; // Mencegah double call
    setState(() {
      isGameFinished = true;
      _gameTimer?.cancel();
      cameraController.stopImageStream();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.deepPurple.shade800,
            title: const Text(
              'Game Selesai!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amberAccent, size: 60),
                const SizedBox(height: 15),
                Text(
                  'Selamat! Anda menyelesaikan Tantangan Ekspresi!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Waktu: ${_elapsedTimeInSeconds} detik',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.deepPurple.shade900,
                  backgroundColor: Colors.amberAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Kembali ke HomePage
                },
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  _resetGame(); // Mulai ulang game
                },
                child: const Text(
                  'Main Lagi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _resetGame() {
    setState(() {
      isGameStarted = false;
      isGameFinished = false;
      _currentRound = 0;
      _elapsedTimeInSeconds = 0;
      _countdownValue = 3;
      _instructionText = 'Bersiaplah!';
      _instructionColor = Colors.white;
      _instructionIcon = Icons.timer;
      _setRandomRequiredExpression(); // Set ekspresi acak pertama untuk game baru
    });
    _startCountdown(); // Mulai hitung mundur lagi
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    cameraController.stopImageStream();
    faceDetector.close();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        toolbarHeight: 80,
        centerTitle: true,
        title: const Text(
          "Tantangan Ekspresi",
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.amberAccent),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Waktu: ${_elapsedTimeInSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          isCameraInitialized
              ? Stack(
                children: [
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: cameraController.value.aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
                  ),

                  // Progress Indicator
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value:
                          isGameStarted
                              ? (_currentRound / _totalRounds)
                              : 0, // Progres berdasarkan round
                      backgroundColor: Colors.grey.shade800,
                      color: Colors.greenAccent,
                      minHeight: 10,
                    ),
                  ),

                  // Main Instruction Area (diperbarui posisi dan gaya)
                  Positioned(
                    top:
                        MediaQuery.of(context).size.height *
                        0.1, // Disesuaikan ke atas (10% dari tinggi layar)
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(
                          0.85,
                        ), // Opacity lebih tinggi, tanpa blur gradien
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _instructionColor,
                          width: 3,
                        ), // Border dinamis
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _instructionIcon,
                            color: _instructionColor,
                            size: 60,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _instructionText,
                            style: TextStyle(
                              color: _instructionColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          if (!isGameStarted)
                            const Text(
                              'Game dimulai setelah hitungan mundur!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Debug / Info Area (Optional, bisa dihapus di versi final)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Round: ${_currentRound + 1}/$_totalRounds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Probabilitas Senyum: ${_smilingProbability != null ? (_smilingProbability! * 100).toStringAsFixed(1) : 'N/A'}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Probabilitas Mata Kiri Terbuka: ${_leftEyeOpenProbability != null ? (_leftEyeOpenProbability! * 100).toStringAsFixed(1) : 'N/A'}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Probabilitas Mata Kanan Terbuka: ${_rightEyeOpenProbability != null ? (_rightEyeOpenProbability! * 100).toStringAsFixed(1) : 'N/A'}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Head Yaw (Y): ${_headEulerAngleY != null ? _headEulerAngleY!.toStringAsFixed(1) : 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Head Roll (Z): ${_headEulerAngleZ != null ? _headEulerAngleZ!.toStringAsFixed(1) : 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : const Center(
                child: CircularProgressIndicator(color: Colors.amberAccent),
              ),
    );
  }

  String _getInstructionText(GameExpression expression) {
    switch (expression) {
      case GameExpression.smile:
        return 'SENYUM!';
      case GameExpression.neutral:
        return 'WAJAH NETRAL!';
      case GameExpression.angry:
        return 'WAJAH MARAH!';
    }
  }

  IconData _getExpressionIcon(GameExpression expression) {
    switch (expression) {
      case GameExpression.smile:
        return Icons.sentiment_very_satisfied;
      case GameExpression.neutral:
        return Icons.sentiment_neutral;
      case GameExpression.angry:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}
