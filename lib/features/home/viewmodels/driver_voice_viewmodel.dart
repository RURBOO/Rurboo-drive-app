import 'package:flutter/foundation.dart';
import '../../../../core/services/driver_preferences.dart';
import '../../../../core/services/driver_voice_service.dart';
import '../../../../state/app_state_viewmodel.dart';

class DriverVoiceViewModel extends ChangeNotifier {
  final DriverVoiceService _voiceService = DriverVoiceService();

  bool _isVoiceEnabled = true;
  bool get isVoiceEnabled => _isVoiceEnabled;

  Future<void> init() async {
    await _voiceService.init();
    _isVoiceEnabled = await DriverPreferences.getVoiceEnabled();
    notifyListeners();
  }

  Future<void> toggleVoice(bool enabled) async {
    _isVoiceEnabled = enabled;
    await DriverPreferences.saveVoiceEnabled(enabled);
    notifyListeners();

    if (enabled) {
      speak(_t(
        hi: "आवाज़ सूचनाएं चालू हो गई हैं।",
        en: "Voice announcements are now enabled.",
      ));
    }
  }

  Future<void> speak(String text) async {
    if (!_isVoiceEnabled) return;
    await _voiceService.speak(text);
  }

  /// Returns the correct language string based on current TTS locale.
  /// [hi] = Hindi text, [en] = English text
  String _t({required String hi, required String en}) {
    return _voiceService.currentLangCode == 'hi' ? hi : en;
  }

  // --- LOCALE-AWARE ANNOUNCEMENTS ---

  void announceNewRide(String pickupLocation, String distance) {
    if (!_isVoiceEnabled) return;
    _voiceService.stop();
    speak(_t(
      hi: "नई सवारी का अनुरोध। पिकअप स्थान $pickupLocation। दूरी $distance।",
      en: "New ride request. Pickup at $pickupLocation. Distance $distance.",
    ));
  }

  void announceRideAccepted() {
    speak(_t(
      hi: "सवारी स्वीकार कर ली गई है। पिकअप स्थान पर पहुँचें।",
      en: "Ride accepted. Please proceed to the pickup location.",
    ));
  }

  void announceArrived() {
    speak(_t(
      hi: "आप पिकअप स्थान पर पहुँच गए हैं। यात्री का इंतज़ार करें।",
      en: "You have arrived at the pickup location. Please wait for the rider.",
    ));
  }

  void announceRideStarted() {
    speak(_t(
      hi: "यात्रा शुरू हो चुकी है। सुरक्षित चलाएं।",
      en: "Trip has started. Please drive safely.",
    ));
  }

  void announceRideCompleted() {
    speak(_t(
      hi: "यात्रा पूरी हो गई। धन्यवाद।",
      en: "Trip completed. Thank you.",
    ));
  }

  void announceRideCompletedWithFare(String fareAmount) {
    speak(_t(
      hi: "यात्रा पूरी हुई। कुल किराया रुपये $fareAmount। धन्यवाद।",
      en: "Trip completed. Total fare rupees $fareAmount. Thank you.",
    ));
  }

  void announceStateChange(DriverState state) {
    if (state == DriverState.online) {
      speak(_t(
        hi: "आप अब ऑनलाइन हैं। नई सवारियाँ मिलती रहेंगी।",
        en: "You are now online. You will receive new ride requests.",
      ));
    } else {
      speak(_t(
        hi: "आप अब ऑफलाइन हैं। नई सवारी नहीं मिलेगी।",
        en: "You are now offline. No new rides will be assigned.",
      ));
    }
  }

  void announceGoingOffline() {
    speak(_t(
      hi: "ऑफलाइन हो रहे हैं।",
      en: "Going offline.",
    ));
  }

  void announceGeneral(String message) {
    speak(message);
  }

  void announceNegativeWallet() {
    speak(_t(
      hi: "खाते में पैसे कम हैं। कृपया वॉलेट रिचार्ज करें ताकि आप ऑनलाइन रह सकें।",
      en: "Wallet balance is low. Please recharge your wallet to stay online.",
    ));
  }

  void announceRideCancelled() {
    speak(_t(
      hi: "यात्री ने सवारी रद्द कर दी है।",
      en: "The rider has cancelled the ride.",
    ));
  }

  void announceOtpRequired() {
    speak(_t(
      hi: "यात्रा शुरू करने के लिए यात्री से ४ अंकों का ओटीपी मांगें।",
      en: "Please ask the rider for the 4-digit OTP to start the trip.",
    ));
  }
}
