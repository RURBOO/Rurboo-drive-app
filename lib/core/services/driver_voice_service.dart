import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Voice Service for Driver App
/// Provides comprehensive voice announcements across all app sections
class DriverVoiceService {
  static final DriverVoiceService _instance = DriverVoiceService._internal();
  factory DriverVoiceService() => _instance;
  DriverVoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // User preference - can be toggled in settings
  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  // Queue management
  final List<String> _announcementQueue = [];
  bool _isSpeaking = false;

  /// Initialize TTS engine
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Load user preference
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('voice_enabled') ?? true;

      // Configure TTS
      bool isLanguageAvailable = await _tts.isLanguageAvailable("hi-IN");
      if (isLanguageAvailable) {
        await _tts.setLanguage("hi-IN");
        debugPrint("🔊 Driver TTS: Hindi (hi-IN) initialized");
      } else {
        await _tts.setLanguage("en-IN");
        debugPrint("🔊 Driver TTS: Hindi not available, falling back to en-IN");
      }
      
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // iOS specific settings
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _processQueue();
      });

      _isInitialized = true;
      debugPrint("✅ Driver Voice Service Initialized (${_isEnabled ? 'Enabled' : 'Disabled'})");
    } catch (e) {
      debugPrint("❌ Voice Service Init Error: $e");
    }
  }

  /// Toggle voice announcements
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', enabled);
    
    if (!enabled) {
      await stop();
    }
  }

  /// Generic speak method
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (!_isEnabled) return;

    // Phonetic correction for "RURBOO" so TTS pronounces it as a word
    final processedText = text.replaceAll("RURBOO", "Roor booo");

    _announcementQueue.add(processedText);
    _processQueue();
  }

  /// Stop all announcements
  Future<void> stop() async {
    _announcementQueue.clear();
    await _tts.stop();
    _isSpeaking = false;
  }

  void _processQueue() async {
    if (_isSpeaking || _announcementQueue.isEmpty) return;

    _isSpeaking = true;
    final text = _announcementQueue.removeAt(0);
    
    debugPrint("🗣️ Speaking: $text");
    await _tts.speak(text);
  }

}
