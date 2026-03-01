import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../core/services/driver_voice_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../../state/app_state_viewmodel.dart';
import '../views/otp_screen.dart';
import '../../../navigation/views/auth_gate.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

class RegistrationViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController(); // 🆕 Added Age
  String? gender; // 🆕 Added Gender
  final TextEditingController emergencyPhoneController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();

  void setGender(String? value) {
    gender = value;
    notifyListeners();
  }

  String vehicleType = 'Bike taxi';
  File? licenseFile;
  File? registrationFile;
  File? profileFile;
  File? vehicleImageFile;

  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  final GlobalKey<FormState> personalInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> vehicleInfoFormKey = GlobalKey<FormState>();

  void setVehicleType(String? newType) {
    if (newType != null) {
      vehicleType = newType;
      notifyListeners();
    }
  }

  Future<void> pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    if (image != null) {
      if (type == 'license') {
        licenseFile = File(image.path);
      } else if (type == 'registration') {
        registrationFile = File(image.path);
      } else if (type == 'profile') {
        profileFile = File(image.path);
      } else if (type == 'vehicle') {
        vehicleImageFile = File(image.path);
      }
      notifyListeners();
    }
  }

  String? prefilledId;
  String? prefilledPhone;

  void initializePrefilled(String? id, String? phone) {
    if (id != null && phone != null) {
      prefilledId = id;
      prefilledPhone = phone;
      phoneController.text = phone;
      notifyListeners();
    }
  }

  Future<void> startRegistration(BuildContext context) async {
    if (licenseFile == null || registrationFile == null || profileFile == null || vehicleImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all documents including Vehicle Photo.")),
      );
      return;
    }

    // 🆕 SKIP OTP IF ARRIVED FROM LOGIN FLOW
    if (prefilledId != null) {
      await _completeRegistration(context, prefilledId!);
      return;
    }

    final String cleanPhone = phoneController.text.trim();
    if (cleanPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Phone Number")),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final String phone = "+91$cleanPhone";

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          if (context.mounted) {
            await _completeRegistration(context, userCred.user!.uid);
          }
        },
        verificationFailed: (e) {
          isLoading = false;
          notifyListeners();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        },
        codeSent: (verificationId, resendToken) {
          isLoading = false;
          notifyListeners();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                phoneNumber: cleanPhone,
                verificationId: verificationId,
                isRegistration: true,
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
      final String msg = e.toString().replaceAll("Exception:", "").trim();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> registerWithOtp(
    BuildContext context, 
    String verificationId, 
    String smsCode
  ) async {
    debugPrint("RegistrationViewModel: registerWithOtp started. SMS Code: $smsCode");
    isLoading = true;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      debugPrint("RegistrationViewModel: Signing in with credential...");
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint("RegistrationViewModel: Sign in success. UID: ${userCred.user?.uid}");
      if (context.mounted) {
        await _completeRegistration(context, userCred.user!.uid);
      }
    } catch (e) {
      debugPrint("RegistrationViewModel: Sign in failed with error: $e");
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _completeRegistration(BuildContext context, String uid) async {
    debugPrint("RegistrationViewModel: _completeRegistration started for UID: $uid");
    try {
      final String cleanPhone = phoneController.text.trim();
      
      final String? licenseBase64 = await ImageUtils.convertFileToBase64(licenseFile!);
      final String? rcBase64 = await ImageUtils.convertFileToBase64(registrationFile!);
      final String? profileBase64 = await ImageUtils.convertFileToBase64(profileFile!);
      final String? vehicleBase64 = vehicleImageFile != null 
          ? await ImageUtils.convertFileToBase64(vehicleImageFile!) 
          : null;

      if (licenseBase64 == null || rcBase64 == null || profileBase64 == null) {
        throw Exception("Failed to process images. Please try again.");
      }

      final newDriver = {
        'id': uid,
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 0, // 🆕 Added Age
        'gender': gender, // 🆕 Added Gender
        'emergencyContactPhone': emergencyPhoneController.text.trim(),
        'phone': cleanPhone,
        'vehicleType': vehicleType,
        'vehicleModel': vehicleModelController.text.trim(),
        'vehicleNumber': vehicleNumberController.text.trim().toUpperCase(),
        'licenseImage': licenseBase64,
        'rcImage': rcBase64,
        'profileImage': profileBase64,
        'vehicleImage': vehicleBase64,
        'isOnline': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 5.0,
        'ratingSum': 0.0,
        'ratingCount': 0,
        'totalRides': 0,
        'walletBalance': 0.0,
        'dailyCommissionDue': 0.0,
        'lastSettlementDate': null,
      };

      debugPrint("RegistrationViewModel: Writing to Firestore 'drivers' collection for UID: $uid");
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set(newDriver);
      debugPrint("RegistrationViewModel: Firestore write SUCCESS");

      await DriverPreferences.saveDriverId(uid);
      await DriverPreferences.saveVehicleType(vehicleType);

      if (context.mounted) {
        final appState = Provider.of<AppStateViewModel>(context, listen: false);
        appState.startSecurityCheck(uid);
        appState.setPending();
      }

      isLoading = false;
      notifyListeners();

      // VOICE ANNOUNCEMENT for success
      try {
        if (context.mounted) {
          final loc = AppLocalizations.of(context)!;
          DriverVoiceService().speak(loc.payment_success_voice); // Can reuse or create a specific key
        }
      } catch (_) {}

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e, stack) {
      debugPrint("RegistrationViewModel: FATAL ERROR during _completeRegistration: $e");
      debugPrintStack(stackTrace: stack);
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration Error: $e"), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }
}
