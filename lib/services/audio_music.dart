import 'package:audioplayers/audioplayers.dart';

class BackgroundMusicController {
  static final BackgroundMusicController _instance =
      BackgroundMusicController._internal();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isMuted = false;

  factory BackgroundMusicController() {
    return _instance;
  }

  BackgroundMusicController._internal();

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setSource(AssetSource('audio/background_music.mp3'));
      await _audioPlayer.setVolume(0.5);
      _isInitialized = true;
    }
  }

  Future<void> play() async {
    if (!_isMuted) {
      await _audioPlayer.resume();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await _audioPlayer.setVolume(0.0);
    } else {
      await _audioPlayer.setVolume(0.5);
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
