import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced Voice Service for Driver App
/// Provides comprehensive voice announcements across all app sections
/// With full Hindi digit/word conversion for rural-friendly TTS output
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

  // =============================================
  // 🔡 HINDI DIGIT & WORD CONVERSION MAP
  // Converts English digits/words to natural Hindi
  // so TTS engine reads aloud in proper Hindi.
  // =============================================
  static const Map<String, String> _englishToHindiDigits = {
    '0': '०', '1': '१', '2': '२', '3': '३', '4': '४',
    '5': '५', '6': '६', '7': '७', '8': '८', '9': '९',
  };

  static const Map<String, String> _wordReplacements = {
    // App name
    'RURBOO': 'रूर-बू',
    'Rurboo': 'रूर-बू',
    'rurboo': 'रूर-बू',
    // Acronyms → Hindi phonetic
    'OTP': 'ओटीपी',
    'otp': 'ओटीपी',
    'GPS': 'जीपीएस',
    'gps': 'जीपीएस',
    'SOS': 'एसओएस',
    'sos': 'एसओएस',
    'RC': 'आरसी',
    // Units → Hindi
    'km': 'किलोमीटर',
    'KM': 'किलोमीटर',
    'km.': 'किलोमीटर',
    'min': 'मिनट',
    'mins': 'मिनट',
    'minute': 'मिनट',
    'minutes': 'मिनट',
    'sec': 'सेकंड',
    'seconds': 'सेकंड',
    // Currency
    '₹': 'रुपये ',
    'Rs': 'रुपये',
    'rs': 'रुपये',
    'rupees': 'रुपये',
    // Common English → Hindi
    'pickup': 'पिकअप',
    'Pickup': 'पिकअप',
    'distance': 'दूरी',
    'Distance': 'दूरी',
  };

  /// Converts English text to TTS-friendly format.
  /// When locale is Hindi: converts digits, acronyms, units to Hindi equivalents.
  /// When locale is English: returns text as-is (natural English TTS).
  String _prepareForTts(String text) {
    // English TTS: don't modify, let engine handle it naturally
    if (_currentLangCode != 'hi') return text;

    String result = text;

    // 1. Replace whole words / acronyms first (order matters)
    _wordReplacements.forEach((english, hindi) {
      result = result.replaceAll(english, hindi);
    });

    // 2. Convert English digits to Devanagari digits
    for (final entry in _englishToHindiDigits.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  // =============================================
  // 🌐 LANGUAGE-AWARE TTS
  // When Hindi is selected, use hi-IN TTS engine
  // + apply full Hindi digit/word substitution.
  // When English is selected, use en-US TTS engine
  // + skip Hindi substitution so text is spoken naturally.
  // =============================================
  String _currentLangCode = 'hi'; // default to Hindi

  /// Current language code used by TTS ('hi' or 'en')
  String get currentLangCode => _currentLangCode;

  /// Call this when user changes language via LanguageProvider
  Future<void> setLocale(String languageCode) async {
    _currentLangCode = languageCode;
    if (!_isInitialized) await init();
    if (languageCode == 'hi') {
      await _tts.setLanguage("hi-IN");
      await _tts.setSpeechRate(0.45);
      debugPrint("🔊 TTS language switched to Hindi (hi-IN)");
    } else {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      debugPrint("🔊 TTS language switched to English (en-US)");
    }
  }

  /// Initialize TTS engine
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Load user preferences
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('voice_enabled') ?? true;

      // Load saved language and set TTS accordingly
      final savedLang = prefs.getString('language_code') ?? 'hi';
      _currentLangCode = savedLang;
      final ttsLang = (savedLang == 'hi') ? 'hi-IN' : 'en-US';

      await _tts.setLanguage(ttsLang);
      debugPrint("🔊 Driver TTS: $ttsLang initialized (lang_code: $savedLang)");

      // Slightly slower speech rate for rural/first-time users
      await _tts.setSpeechRate(0.45);
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

  /// Generic speak method — auto-converts text to Hindi-friendly TTS format
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (!_isEnabled) return;

    final processedText = _prepareForTts(text);
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

    debugPrint("🗣️ Speaking (Hindi): $text");
    await _tts.speak(text);
  }
}
