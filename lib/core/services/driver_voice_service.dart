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
      _isEnabled = prefs.getBool('voice_announcements_enabled') ?? true;

      // Configure TTS
      await _tts.setLanguage("hi-IN"); // Hindi-English mix
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
          IosTextToSpeechAudioMode.defaultMode,
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
    await prefs.setBool('voice_announcements_enabled', enabled);
    
    if (!enabled) {
      await stop();
    }
  }

  /// Generic speak method
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (!_isEnabled) return;

    _announcementQueue.add(text);
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

  // =========================================================================
  // APP LAUNCH ANNOUNCEMENTS
  // =========================================================================

  void announceAppLaunch() {
    speak("Welcome to RURBOO Driver. Ready to drive and earn!");
  }

  // =========================================================================
  // AUTHENTICATION ANNOUNCEMENTS
  // =========================================================================

  void announceLoginScreen() {
    speak("Login screen. Please enter your phone number.");
  }

  void announcePhoneNumberField() {
    speak("Phone number");
  }

  void announceOTPScreen() {
    speak("OTP screen. Please enter the verification code sent to your mobile.");
  }

  void announceOTPField() {
    speak("Enter OTP");
  }

  void announceLoginSuccess() {
    speak("Login successful! Welcome back!");
  }

  void announceRegistrationScreen() {
    speak("Registration screen. Please fill in your details.");
  }

  void announceNameField() {
    speak("Full name");
  }

  void announceEmailField() {
    speak("Email address");
  }

  void announceVehicleTypeField() {
    speak("Vehicle type");
  }

  void announceVehicleNumberField() {
    speak("Vehicle registration number");
  }

  void announceDocumentUploadScreen() {
    speak("Document upload screen. Please upload required documents.");
  }

  void announceRegistrationSuccess() {
    speak("Your registration has been submitted successfully. Please wait for admin approval.");
  }

  // =========================================================================
  // HOME SCREEN ANNOUNCEMENTS
  // =========================================================================

  void announceHomeScreen() {
    speak("Home screen. You are currently offline. Turn on to accept rides.");
  }

  void announceGoingOnline() {
    speak("Going online. You can now accept ride requests.");
  }

  void announceGoingOffline() {
    speak("Going offline. You will not receive ride requests.");
  }

  void announceNegativeWallet() {
    speak("Your wallet balance is negative. Please recharge to go online.");
  }

  void announceIncomingRide(String pickup, String destination, String fare) {
    speak("New ride request. Pickup from $pickup to $destination. Fare rupees $fare. Accept or decline.");
  }

  void announceRideAccepted() {
    speak("Ride accepted! Navigate to pickup location.");
  }

  void announceRideDeclined() {
    speak("Ride declined.");
  }

  // =========================================================================
  // TRIP ANNOUNCEMENTS
  // =========================================================================

  void announceNavigatingToPickup() {
    speak("Navigating to pickup location.");
  }

  void announceArrivedAtPickup() {
    speak("You have arrived at pickup location. Call the customer.");
  }

  void announceTripStarted() {
    speak("Trip started. Navigate to destination.");
  }

  void announceNearingDestination() {
    speak("Approaching destination.");
  }

  void announceTripCompleted(String fare) {
    speak("Trip completed. Total fare rupees $fare. Thank you!");
  }

  void announceCustomerCancelled() {
    speak("Customer has cancelled the ride.");
  }

  // =========================================================================
  // WALLET ANNOUNCEMENTS
  // =========================================================================

  void announceWalletScreen() {
    speak("Wallet screen");
  }

  void announceWalletBalance(double balance) {
    final balanceText = balance < 0 ? "negative ${balance.abs()}" : balance.toStringAsFixed(0);
    speak("Your current wallet balance is rupees $balanceText");
  }

  void announceCommissionDue(double amount) {
    speak("Today's commission due is rupees ${amount.toStringAsFixed(0)}");
  }

  void announceRechargeAmount() {
    speak("Enter recharge amount");
  }

  void announceRechargeSuccess(double amount) {
    speak("Wallet recharged successfully with rupees ${amount.toStringAsFixed(0)}");
  }

  void announceRechargeFailure() {
    speak("Recharge failed. Please try again.");
  }

  // =========================================================================
  // EARNINGS ANNOUNCEMENTS
  // =========================================================================

  void announceEarningsScreen() {
    speak("Earnings screen");
  }

  void announceTodayEarnings(double amount) {
    speak("Today's earnings: rupees ${amount.toStringAsFixed(0)}");
  }

  void announceWeekEarnings(double amount) {
    speak("This week's earnings: rupees ${amount.toStringAsFixed(0)}");
  }

  void announceMonthEarnings(double amount) {
    speak("This month's earnings: rupees ${amount.toStringAsFixed(0)}");
  }

  void announceTotalRides(int count) {
    speak("Total rides completed: $count");
  }

  // =========================================================================
  // PROFILE ANNOUNCEMENTS
  // =========================================================================

  void announceProfileScreen() {
    speak("Profile screen");
  }

  void announceDocumentsSection() {
    speak("Documents section");
  }

  void announceSettingsSection() {
    speak("Settings section");
  }

  void announceLogout() {
    speak("Logging out. Goodbye!");
  }

  // =========================================================================
  // ERROR & NOTIFICATION ANNOUNCEMENTS
  // =========================================================================

  void announceError(String message) {
    speak("Error: $message");
  }

  void announceSuccess(String message) {
    speak(message);
  }

  void announceNoInternetConnection() {
    speak("No internet connection. Please check your network.");
  }

  void announceGPSDisabled() {
    speak("GPS is disabled. Please enable location services.");
  }

  // =========================================================================
  // FORM FIELD ANNOUNCEMENTS (Generic)
  // =========================================================================

  void announceTextField(String label) {
    speak(label);
  }

  void announceButton(String buttonText) {
    speak("$buttonText button");
  }

  void announceDropdown(String label) {
    speak("$label dropdown");
  }
}
