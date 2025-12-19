import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../splash/views/splash_screen.dart';

class LoginViewModel extends ChangeNotifier {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login(BuildContext context, AppStateViewModel appState) async {
    if (phoneController.text.length != 10 || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Phone or Password")),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final String dummyEmail = "${phoneController.text.trim()}@rubodriver.com";

      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: dummyEmail,
        password: passwordController.text.trim(),
      );

      final String uid = userCred.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw Exception("No driver account found.");
      }

      final data = doc.data()!;

      await DriverPreferences.saveDriverId(uid);
      if (data['vehicleType'] != null) {
        await DriverPreferences.saveVehicleType(data['vehicleType']);
      }

      appState.signIn();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        String msg = "Login Failed";
        if (e.toString().contains("invalid-credential")) {
          msg = "Incorrect Phone Number or Password";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    isLoading = false;
    notifyListeners();
  }
}
