import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/driver_voice_service.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/registration_viewmodel.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final bool isRegistration;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.isRegistration = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final _voiceService = DriverVoiceService();
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  String _currentVerificationId = '';

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    debugPrint("OtpScreen: initState called. isRegistration: ${widget.isRegistration}");
    _initVoice();
  }

  Future<void> _initVoice() async {
    await _voiceService.init();
    _voiceService.announceOTPScreen();
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  Future<void> _resendOTP() async {
    if (_isResending || _resendCooldown > 0) return;

    setState(() => _isResending = true);
    _voiceService.speak("Resending OTP");

    final String phone = "+91${widget.phoneNumber}";

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          // Auto-retrieval scenario
          debugPrint("OTP Resend: Auto-verification triggered");
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _isResending = false);
          _voiceService.announceError("Failed to resend OTP. Please try again.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Resend failed: ${e.message}"),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (newVerificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _currentVerificationId = newVerificationId;
            _isResending = false;
          });
          _startCooldownTimer();
          _voiceService.announceSuccess("New OTP sent successfully!");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("New OTP sent successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          setState(() => _isResending = false);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      _voiceService.announceError("Error sending OTP");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _handleVerify() async {
    debugPrint("OtpScreen: _handleVerify TRIGGERED");
    setState(() => _isVerifying = true);

    final cleanOtp = otpController.text.replaceAll(' ', '');
    debugPrint("Clean OTP: $cleanOtp (Length: ${cleanOtp.length})");
    if (cleanOtp.length != 6) {
      debugPrint("OTP Length Invalid");
      setState(() => _isVerifying = false);
      _voiceService.announceError("Please enter 6 digit OTP");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter 6 digit OTP")),
      );
      return;
    }

    try {
      if (widget.isRegistration) {
        debugPrint("Calling RegistrationViewModel.registerWithOtp");
        await context.read<RegistrationViewModel>().registerWithOtp(
          context,
          _currentVerificationId,
          cleanOtp,
        );
      } else {
        debugPrint("Calling LoginViewModel.signInWithSms");
        await context.read<LoginViewModel>().signInWithSms(
          context,
          _currentVerificationId,
          cleanOtp,
        );
      }
    } catch (e) {
      debugPrint("OTP Verification Exception Caught: $e");
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    "Verify Phone",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Phone Number Display
                  Text(
                    "Enter the 6-digit code sent to\n+91 ${widget.phoneNumber}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade300,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // OTP Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onTap: () => _voiceService.announceOTPField(),
                      decoration: InputDecoration(
                        hintText: "_ _ _ _ _ _",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade600,
                          letterSpacing: 16,
                        ),
                        counterText: "",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Verify Button
                  _isVerifying
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.blue, 
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _handleVerify,
                          child: Text(
                            widget.isRegistration
                                ? "Verify & Register"
                                : "Verify & Login",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                  const SizedBox(height: 24),

                  // Resend Code Button
                  _isResending
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: _resendCooldown > 0 ? null : _resendOTP,
                          child: Text(
                            _resendCooldown > 0
                                ? "Resend OTP in ${_resendCooldown}s"
                                : "Didn't receive code? Resend",
                            style: TextStyle(
                              color: _resendCooldown > 0
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
