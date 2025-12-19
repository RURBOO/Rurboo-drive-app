import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/driver_preferences.dart';
import '../views/pending_approval_screen.dart';

class RegistrationViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();

  String vehicleType = 'Car';
  File? licenseFile;
  File? registrationFile;
  File? profileFile;

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
      } else if (type == 'registration')
        registrationFile = File(image.path);
      else if (type == 'profile')
        profileFile = File(image.path);
      notifyListeners();
    }
  }

  Future<void> submitApplication(BuildContext context) async {
    if (licenseFile == null ||
        registrationFile == null ||
        profileFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all documents first.")),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final String cleanPhone = phoneController.text.trim();
      final String dummyEmail = "$cleanPhone@rubodriver.com";

      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: dummyEmail,
              password: passwordController.text.trim(),
            );
      } catch (e) {
        throw Exception("Registration failed: ${e.toString()}");
      }

      final String uid = userCredential.user!.uid;

      final newDriver = {
        'id': uid,
        'name': nameController.text.trim(),
        'phone': cleanPhone,
        'email': dummyEmail,
        'vehicleType': vehicleType,
        'vehicleModel': vehicleModelController.text.trim(),
        'vehicleNumber': vehicleNumberController.text.trim().toUpperCase(),

        'licenseUrl': "",
        'rcUrl': "",
        'profileUrl': "",

        'isOnline': false,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 5.0,
        'totalRides': 0,
        'walletBalance': 0.0,
        'ratingSum': 0.0,
        'ratingCount': 0,
      };

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .set(newDriver);

      await DriverPreferences.saveDriverId(uid);
      await DriverPreferences.saveVehicleType(vehicleType);

      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();

      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.currentUser!.delete();
      }

      String errorMsg = "Error: $e";
      if (e.toString().contains("email-already-in-use")) {
        errorMsg = "This Phone Number is already registered. Please Login.";
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }
}
