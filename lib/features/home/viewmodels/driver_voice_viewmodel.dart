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
      speak("Voice announcements enabled.");
    }
  }

  Future<void> speak(String text) async {
    if (!_isVoiceEnabled) return;
    await _voiceService.speak(text);
  }

  // --- SPECIFIC ANNOUNCEMENTS ---

  void announceNewRide(String pickupLocation, String distance) {
    if (!_isVoiceEnabled) return;
    // Clear queue to prioritize new ride
    _voiceService.stop(); 
    
    // "New ride request. Pickup [Location], distance [X] km."
    // Hindi-English mix logic can be added here
    speak("New ride request. Pickup $pickupLocation. Distance $distance.");
  }

  void announceRideAccepted() {
    speak("Ride accept ho gayi hai.");
  }

  void announceArrived() {
    speak("Aap pickup location par pahuch gaye hain.");
  }

  void announceRideStarted() {
    speak("Ride start ho chuki hai.");
  }

  void announceRideCompleted() {
    speak("Ride complete ho gayi hai. Shukriya.");
  }

  void announceStateChange(DriverState state) {
    if (state == DriverState.online) {
      speak("You are now Online.");
    } else {
      speak("You are now Offline.");
    }
  }

  void announceGoingOffline() {
    speak("Going offline.");
  }

  void announceGeneral(String message) {
    speak(message);
  }

  void announceNegativeWallet() {
    speak("Insufficient balance. Please recharge.");
  }
}
