import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'face_detection_page.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestCameraPermission();

  runApp(const MyApp());
}

/// Requests camera permission from the user.
Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    // Handle permission denial
    runApp(const PermissionDeniedApp());
  }
}

class PermissionDeniedApp extends StatelessWidget {
  const PermissionDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // Tambahkan ini untuk menghilangkan banner debug
      home: Scaffold(
        backgroundColor:
            Colors.deepPurple.shade900, // Warna latar belakang gelap
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.amberAccent,
                  size: 80,
                ),
                SizedBox(height: 20),
                Text(
                  "Akses Kamera Diperlukan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "Kami butuh izin kamera untuk memulai filter wajah interaktif. Mohon izinkan akses kamera Anda.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.deepPurple.shade900,
                    backgroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    openAppSettings(); // Membuka pengaturan aplikasi untuk mengizinkan permission
                  },
                  child: const Text(
                    "Buka Pengaturan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text(
                    "Keluar Aplikasi",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Filter Game',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      theme: ThemeData(
        primarySwatch: Colors.amber, // Mengubah warna primer aplikasi
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900, // Latar belakang gelap
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar transparan
        elevation: 0, // Tanpa shadow
        toolbarHeight: 90,
        centerTitle: true,
        title: const Text(
          'Face Filter Fun!',
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon atau logo game
            Icon(Icons.camera_roll, color: Colors.amberAccent, size: 120),
            const SizedBox(height: 40),
            const Text(
              'Siap bermain dengan wajah Anda?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Deteksi ekspresi dan bersenang-senang!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            ScaleTransition(
              scale: _scaleAnimation,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor:
                      Colors.deepPurple.shade900, // Warna teks tombol
                  backgroundColor:
                      Colors.amberAccent, // Warna latar belakang tombol
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      30,
                    ), // Sudut tombol lebih bulat
                  ),
                  elevation: 8, // Sedikit shadow untuk efek 3D
                ),
                onPressed: () async {
                  // Animasi tekan tombol
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                  });

                  final cameras = await availableCameras();
                  if (cameras.isNotEmpty) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaceDetectionPage(),
                      ),
                    );
                    if (result == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Verifikasi Wajah Berhasil!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating, // Efek floating
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(20),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Kamera tidak aktif atau tidak ditemukan!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(20),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Mulai Bermain!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
