import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/driver_preferences.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../auth/views/login_screen.dart';

class ProfileViewModel extends ChangeNotifier {
  bool isLoading = true;

  String? profileImageBase64;
  String? licenseImageBase64;
  String? rcImageBase64;

  String name = "";
  String phone = "";
  String vehicle = "";
  String vehicleModel = "";
  String vehicleNumber = "";
  String rating = "5.0";
  String totalRides = "0";
  String earnings = "0";
  String joinDate = "";
  String driverId = "";

  Future<void> fetchProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final did = await DriverPreferences.getDriverId();
      if (did == null) return;
      driverId = did;

      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(did)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        name = data['name'] ?? "Driver";
        phone = data['phone'] ?? data['phoneNumber'] ?? '';
        vehicleModel = data['vehicleModel'] ?? '';
        vehicleNumber = data['vehicleNumber'] ?? '';
        vehicle = "$vehicleModel • $vehicleNumber".trim().replaceAll(RegExp(r'^•\s*|\s*•$'), '');

        final double r = (data['rating'] as num?)?.toDouble() ?? 5.0;
        rating = r.toStringAsFixed(1);

        totalRides = (data['totalRides'] ?? 0).toString();

        // Dynamic ride fetch fallback
        try {
          final query = await FirebaseFirestore.instance
              .collection('rideRequests')
              .where('driverId', isEqualTo: did)
              .get();
          int currentRides = 0;
          for (var doc in query.docs) {
            final status = doc.data()['status'];
            if (status == 'completed' || status == 'closed') {
              currentRides++;
            }
          }
          if (currentRides > (data['totalRides'] ?? 0)) {
            totalRides = currentRides.toString();
          }
        } catch (_) {}

        final double bal = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
        earnings = "₹${bal.toStringAsFixed(0)}";

        profileImageBase64 = data['profileImage'];
        licenseImageBase64 = data['licenseImage'];
        rcImageBase64 = data['rcImage'];

        if (data['createdAt'] != null) {
          final DateTime date = (data['createdAt'] as Timestamp).toDate();
          joinDate = "Joined ${_getMonth(date.month)} ${date.year}";
        }
      }
    } catch (e) {
      debugPrint("Profile Error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> logout(BuildContext context) async {
    // 1. Clear Local Data
    await DriverPreferences.clearDriver();
    
    // 2. Sign out from Firebase (CRITICAL)
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      context.read<AppStateViewModel>().signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
