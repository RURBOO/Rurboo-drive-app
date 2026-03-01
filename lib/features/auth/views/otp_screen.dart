import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/driver_voice_service.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/registration_viewmodel.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

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
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final _voiceService = DriverVoiceService();

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  String _currentVerificationId = '';

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    debugPrint("OtpScreen: initState called. isRegistration: ${widget.isRegistration}");
    _initVoice();
    _startCooldownTimer();
  }

  Future<void> _initVoice() async {
    await _voiceService.init();
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    _voiceService.speak(loc.otp_screen_voice);
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    if (_isResending || _resendCooldown > 0) return;

    setState(() {
      _isResending = true;
      _pinController.clear(); 
    });
    _voiceService.speak("Resending OTP");

    final String phone = "+91${widget.phoneNumber}";

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          debugPrint("OTP Resend: Auto-verification triggered");
        },
        verificationFailed: (e) {
          if (!mounted) return;
          if (!mounted) return;
          final loc = AppLocalizations.of(context)!;
          setState(() => _isResending = false);
          _voiceService.speak(loc.otp_resend_failed);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Resend failed: ${e.message}"),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (newVerificationId, resendToken) {
          if (!mounted) return;
          if (!mounted) return;
          final loc = AppLocalizations.of(context)!;
          setState(() {
            _currentVerificationId = newVerificationId;
            _isResending = false;
          });
          _startCooldownTimer();
          _voiceService.speak(loc.otp_resend_success);
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
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      setState(() => _isResending = false);
      _voiceService.speak(loc.otp_send_error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _handleVerify() async {
    debugPrint("OtpScreen: _handleVerify TRIGGERED");
    setState(() => _isVerifying = true);

    final cleanOtp = _pinController.text.trim();
    debugPrint("Clean OTP: $cleanOtp (Length: ${cleanOtp.length})");

    if (cleanOtp.length != 6) {
      debugPrint("OTP Length Invalid");
      setState(() => _isVerifying = false);
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        _voiceService.speak(loc.otp_6_digit_error);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter 6 digit OTP")),
      );
      return;
    }

    try {
      if (widget.isRegistration) {
        debugPrint("RegistrationViewModel: Calling _completeRegistration...");
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
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 58,
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: theme.colorScheme.primary, width: 2),
      color: Colors.white.withValues(alpha: 0.1),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: theme.colorScheme.primary),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          size: 48, color: Colors.white),
                    ),
                  ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    "Verify Phone",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    "Enter the 6-digit code sent to\n+91 ${widget.phoneNumber}",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 48),

                  // ─── Pinput OTP ──────────────────────────────────────
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      autofocus: true,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      keyboardType: TextInputType.number,
                      closeKeyboardWhenCompleted: true,
                      onCompleted: (_) => _handleVerify(),
                      cursor: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            width: 22,
                            height: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 32),

                  // ─── Verify Button ───────────────────────────────────
                  _isVerifying
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor:
                                theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          onPressed: _handleVerify,
                          child: Text(
                            widget.isRegistration
                                ? "Verify & Register"
                                : "Verify & Login",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // ─── Resend ──────────────────────────────────────────
                  _isResending
                      ? const Center(
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)))
                      : TextButton(
                          onPressed: _resendCooldown > 0 ? null : _resendOTP,
                          child: Text(
                            _resendCooldown > 0
                                ? "Resend OTP in ${_resendCooldown}s"
                                : "Didn't receive code? Resend",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _resendCooldown > 0
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ).animate().fade(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
