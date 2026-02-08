import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../state/app_state_viewmodel.dart';
import '../views/otp_screen.dart';
import '../views/pending_approval_screen.dart';

class LoginViewModel extends ChangeNotifier {
  final phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> login(BuildContext context, AppStateViewModel appState) async {
    if (phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Phone Number (10 digits required)")),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    final String phone = "+91${phoneController.text.trim()}";

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          // AUTO-RETRIEVAL or Instant Verification
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          if (context.mounted) {
            await _handlePostLogin(context, userCred.user!.uid, appState);
          }
        },
        verificationFailed: (e) {
          isLoading = false;
          notifyListeners();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Verification Failed: ${e.message}")),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          isLoading = false;
          notifyListeners();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                phoneNumber: phoneController.text.trim(),
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> signInWithSms(
    BuildContext context, 
    String verificationId, 
    String smsCode
  ) async {
    debugPrint("LoginViewModel: signInWithSms started. SMS Code: $smsCode");
    isLoading = true;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      debugPrint("LoginViewModel: Signing in with credential...");
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint("LoginViewModel: Sign in success. UID: ${userCred.user?.uid}");
      if (context.mounted) {
        final appState = Provider.of<AppStateViewModel>(context, listen: false);
        await _handlePostLogin(context, userCred.user!.uid, appState);
      }
    } catch (e) {
      debugPrint("LoginViewModel: Sign in failed with error: $e");
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP")),
        );
      }
    }
  }

  Future<void> _handlePostLogin(
    BuildContext context, 
    String uid, 
    AppStateViewModel appState
  ) async {
    debugPrint("LoginViewModel: _handlePostLogin started for UID: $uid");
    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .get();

    debugPrint("LoginViewModel: Driver doc exists: ${doc.exists}");
    if (!doc.exists) {
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No driver account found. Please register.")),
        );
      }
      return;
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
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        (route) => false,
      );
    }
  }
}
