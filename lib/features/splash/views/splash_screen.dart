import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../core/services/driver_voice_service.dart';
import '../../../navigation/views/auth_gate.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../auth/views/location_disclosure_screen.dart';
import '../../auth/views/login_screen.dart';
import '../../auth/views/pending_approval_screen.dart';
import '../../language/views/language_selection_screen.dart';
import '../../../state/language_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initVoice();
    _checkInternetAndStart();
  }

  Future<void> _initVoice() async {
    final voiceService = DriverVoiceService();
    await voiceService.init();
    // We removed announceAppLaunch. You can add a specific key for this if needed.
    // Assuming we just want it silent or use a generic welcome here for now.
    // voiceService.speak(loc.appLaunchVoice); // Or similar
  }

  Future<void> _checkInternetAndStart() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (!mounted) return;
      _showNoInternetDialog();
    } else {
      _checkSession();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Connection Error"),
        content: const Text(
          "No internet connection detected. Please verify your connection and try again.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkInternetAndStart();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSession() async {
    final langProvider = context.read<LanguageProvider>();

    // 0. Mandatory Language Selection
    if (!langProvider.isLanguageSelected) {
      if (mounted) _nav(const LanguageSelectionScreen());
      return;
    }

    final driverId = await DriverPreferences.getDriverId();

    // 1. Check Local Preference
    if (driverId == null) {
      if (mounted) _nav(const LoginScreen());
      return;
    }

    // 2. Check Firebase Auth (CRITICAL FIX)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != driverId) {
      debugPrint("❌ Auth Session Invalid or Mismatch. Forcing Login.");
      await DriverPreferences.clearDriverId(); // Clear stale data
      if (mounted) _nav(const LoginScreen());
      return;
    }

    try {
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      final status = driverDoc.data()?['status'];

      if (!driverDoc.exists || status != 'verified') {
        if (mounted) _nav(const PendingApprovalScreen());
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _nav(const LocationDisclosureScreen());
        return;
      }

      final activeRideQuery = await FirebaseFirestore.instance
          .collection('rideRequests')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['accepted', 'in_progress'])
          .limit(1)
          .get();

      if (activeRideQuery.docs.isNotEmpty) {
        final ride = activeRideQuery.docs.first;
        final rideId = ride.id;

        await DriverPreferences.saveCurrentRideId(rideId);

        if (mounted) {
          context.read<AppStateViewModel>().acceptRide(rideId);
          _nav(const AuthGate());
        }
      } else {
        await DriverPreferences.clearCurrentRideId();
        if (mounted) {
           context.read<AppStateViewModel>().endTrip();
           _nav(const AuthGate());
        }
      }
    } catch (e) {
      debugPrint("Session check failed: $e");
      if (mounted) _nav(const LoginScreen());
    }
  }

  void _nav(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Premium Dark Splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Branding
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_taxi_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Brand Name
            const Text(
              "RURBOO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              "DRIVER PARTNER",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            // Sleek Loader
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
