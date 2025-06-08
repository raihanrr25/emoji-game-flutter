import 'package:flutter/material.dart';

class VictoryAnimationController extends ChangeNotifier {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _emojiController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  late AnimationController _rotationController;
  late AnimationController _bounceController;

  late Animation<double> _confettiAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _emojiFloatAnimation;

  bool _isAnimating = false;

  bool get isAnimating => _isAnimating;
  Animation<double> get confettiAnimation => _confettiAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<double> get fadeAnimation => _fadeAnimation;
  AnimationController get particleController => _particleController;
  AnimationController get emojiController => _emojiController;
  AnimationController get pulseController => _pulseController;
  Animation<double> get backgroundAnimation => _backgroundAnimation;
  Animation<double> get rotationAnimation => _rotationAnimation;
  Animation<double> get bounceAnimation => _bounceAnimation;
  Animation<double> get emojiFloatAnimation => _emojiFloatAnimation;
  Animation<double> get pulseAnimation =>
      Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

  void initialize(TickerProvider vsync) {
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: vsync,
    )..repeat();

    _emojiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: vsync,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: vsync,
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: vsync,
    )..repeat();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: vsync,
    )..repeat();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: vsync,
    )..repeat(reverse: true);

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );

    _emojiFloatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emojiController, curve: Curves.easeInOut),
    );
  }

  Future<void> startVictoryAnimation() async {
    _isAnimating = true;
    notifyListeners();

    // Start animations with slight delays
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    _confettiController.forward();
  }

  void resetAnimations() {
    _confettiController.reset();
    _scaleController.reset();
    _fadeController.reset();
    _isAnimating = false;
    notifyListeners();
  }

  void stopAnimations() {
    _confettiController.stop();
    _scaleController.stop();
    _fadeController.stop();
    _particleController.stop();
    _emojiController.stop();
    _pulseController.stop();
    _backgroundController.stop();
    _rotationController.stop();
    _bounceController.stop();
    _isAnimating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _emojiController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}
