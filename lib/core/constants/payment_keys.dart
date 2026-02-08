import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Payment Gateway Configuration
/// Keys are loaded from .env file for security
/// 
/// Setup:
/// 1. Copy .env.example to .env
/// 2. Add your Razorpay keys to .env
/// 3. Never commit .env to version control
class PaymentKeys {
  // ✅ Load from environment variables
  // Fallback to hardcoded test key if .env not configured
  static String get razorpayKeyId {
    final envKey = dotenv.env['RAZORPAY_KEY_ID'];
    if (envKey == null || envKey.isEmpty || envKey == 'your_razorpay_key_id_here') {
      // Fallback for backwards compatibility
      return "rzp_test_SDWbxSvEQvjsC7";
    }
    return envKey;
  }

  static const String appName = "RURBOO Driver";
  static const String description = "Wallet Recharge";
}
