import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

enum AlertMode { safe, warning, caution, scanning }

class AlertService {
  final FlutterTts _tts = FlutterTts();
  bool _isMuted = false;
  double _volume = 1.0;
  String _currentVoiceAlert = '';
  AlertMode _lastActiveMode = AlertMode.scanning;

  AlertService() {
    _initTts();
  }

  bool get isMuted => _isMuted;
  double get volume => _volume;

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.55); // Easy to understand pacing
      await _tts.setVolume(_volume);
      await _tts.setPitch(1.0);
    } catch (e) {
      // Graceful fallback if TTS fails to initialize on desktop/simulator
      print("TTS Initialization warning: $e");
    }
  }

  void setMute(bool mute) {
    _isMuted = mute;
    if (_isMuted) {
      stop();
    }
  }

  void setVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    _tts.setVolume(_volume);
  }

  Future<void> announce(AlertMode mode) async {
    if (mode == _lastActiveMode) return; // Prevent duplicate repeat speech spamming
    _lastActiveMode = mode;

    switch (mode) {
      case AlertMode.safe:
        await _speak("Safe to cross. Proceed with caution.");
        await _vibrateSafe();
        break;
      case AlertMode.warning:
        await _speak("Stop! Vehicle approaching. Do not cross.");
        await _vibrateDanger();
        break;
      case AlertMode.caution:
        await _speak("Caution. Nearby traffic detected.");
        await _vibrateCaution();
        break;
      case AlertMode.scanning:
        await _speak("Scanning traffic. Please wait.");
        break;
    }
  }

  Future<void> _speak(String sentence) async {
    _currentVoiceAlert = sentence;
    if (_isMuted) return;
    try {
      await _tts.stop();
      await _tts.speak(sentence);
    } catch (e) {
      print("TTS speech warning: $e");
    }
  }

  Future<void> _vibrateSafe() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Single pleasant feedback pulse
        await Vibration.vibrate(duration: 300);
      }
    } catch (e) {
      print("Haptic feedback warning: $e");
    }
  }

  Future<void> _vibrateDanger() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Urgent repeated pulses
        await Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 400, 200, 400]);
      }
    } catch (e) {
      print("Haptic feedback warning: $e");
    }
  }

  Future<void> _vibrateCaution() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Soft double-pulse
        await Vibration.vibrate(pattern: [0, 150, 100, 150]);
      }
    } catch (e) {
      print("Haptic feedback warning: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      Vibration.cancel();
    } catch (e) {
      print("Error stopping alerts: $e");
    }
  }
}
