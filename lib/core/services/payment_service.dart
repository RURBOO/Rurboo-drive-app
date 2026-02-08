import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/payment_keys.dart';

class PaymentService {
  late Razorpay _razorpay;

  final Function(String paymentId) onSuccess;
  final Function(String errorMsg) onFailure;

  PaymentService({required this.onSuccess, required this.onFailure}) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String phone,
    required String email,
  }) {
    var options = {
      'key': PaymentKeys.razorpayKeyId,
      'amount': (amount * 100).toInt(),
      'name': PaymentKeys.appName,
      'description': PaymentKeys.description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': phone, 'email': email},
      'theme': {'color': '#000000'},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onFailure("Startup Error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (response.paymentId != null) {
      onSuccess(response.paymentId!);
    } else {
      onFailure("Payment successful but ID missing.");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    String msg = "Payment Failed";
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      msg = "Payment Cancelled";
    } else if (response.code == Razorpay.NETWORK_ERROR) {
      msg = "Network Issue";
    }
    onFailure(msg);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onFailure("External Wallet Selected: ${response.walletName}");
  }

  void dispose() {
    _razorpay.clear();
  }
}
