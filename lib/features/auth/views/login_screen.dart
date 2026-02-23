import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/driver_voice_service.dart';
import '../../../state/app_state_viewmodel.dart';
import '../viewmodels/login_viewmodel.dart';
import 'registration_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _voiceService = DriverVoiceService();

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    await _voiceService.init();
    _voiceService.announceLoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return _LoginScreenBody(voiceService: _voiceService);
  }
}

class _LoginScreenBody extends StatelessWidget {
  final DriverVoiceService voiceService;
  
  const _LoginScreenBody({required this.voiceService});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final appState = context.read<AppStateViewModel>();
    final theme = Theme.of(context);

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
                  // Logo Section
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.local_taxi_rounded, size: 48, color: Colors.white),
                    ),
                  ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    AppLocalizations.of(context)!.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    AppLocalizations.of(context)!.driveEarnGrow,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade400,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 48),

                  // Phone Number Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: TextField(
                      controller: vm.phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      cursorColor: Colors.white,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white, 
                        letterSpacing: 2,
                      ),
                      onTap: () => voiceService.announcePhoneNumberField(),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.phoneNumber,
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                        prefixText: "+91 ",
                        prefixStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white, letterSpacing: 2),
                        counterText: "",
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: const Icon(Icons.phone_android_rounded, color: Colors.white70),
                      ),
                    ),
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 32),

                  // Login Button
                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: theme.colorScheme.primary, // Electric Blue
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          onPressed: () => vm.login(context, appState),
                          child: Text(
                            AppLocalizations.of(context)!.sendOtp,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 32),

                  // Registration Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.newDriver} ",
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen()));
                        },
                        child: Text(
                          AppLocalizations.of(context)!.registerHere,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 600.ms),

                  const SizedBox(height: 24),

                  // Terms & Privacy
                  Text(
                    AppLocalizations.of(context)!.termsPrivacyLogin,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ).animate().fade(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
