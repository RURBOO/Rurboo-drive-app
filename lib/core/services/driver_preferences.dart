import 'package:shared_preferences/shared_preferences.dart';

class DriverPreferences {
  static const String _keyDriverId = 'driver_id';
  static const String _keyCurrentRideId = 'current_ride_id';
  static const String _keyVehicleType = 'vehicle_type';

  static Future<void> saveDriverId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDriverId, id);
  }

  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverId);
  }

  static Future<void> clearDriver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDriverId);
  }

  static Future<void> saveCurrentRideId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentRideId, id);
  }

  static Future<String?> getCurrentRideId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentRideId);
  }

  static Future<void> clearCurrentRideId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentRideId);
  }

  static Future<void> clearDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDriverId);
    await prefs.remove('currentRideId');
  }

  static Future<void> saveVehicleType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVehicleType, type);
  }

  static Future<String?> getVehicleType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVehicleType);
  }

  // Voice Preference
  static const String _keyVoiceEnabled = 'voice_enabled';

  static Future<void> saveVoiceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceEnabled, enabled);
  }

  static Future<bool> getVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVoiceEnabled) ?? true; // Default ON
  }
}
