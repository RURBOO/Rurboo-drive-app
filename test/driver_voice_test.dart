import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rubo_driver/core/services/driver_voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_tts');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return 1; // Return success code
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('DriverVoiceService', () {
    late DriverVoiceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'voice_announcements_enabled': true,
      });
      service = DriverVoiceService();
      // Reset singleton or recreate logic if needed, but since it's a singleton, 
      // repeated init calls are handled by _isInitialized check.
      // We can't easily reset the private singleton instance, 
      // but re-init shouldn't hurt with our mock handler.
      await service.init();
    });

    test('should be enabled by default', () {
      expect(service.isEnabled, true);
    });

    test('should toggle enabled state', () async {
      await service.setEnabled(false);
      expect(service.isEnabled, false);

      await service.setEnabled(true);
      expect(service.isEnabled, true);
    });

    test('should handle speak calls', () async {
      await service.setEnabled(true);
      await service.speak("Testing speak");
      // If no exception, test passes.
      // Mock returns 1 success.
    });
    
    test('should handle queue additions', () async {
       await service.speak("Message 1");
       await service.speak("Message 2");
    });
  });
}
