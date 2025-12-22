import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/driver_preferences.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../auth/views/login_screen.dart';

class ProfileViewModel extends ChangeNotifier {
  bool isLoading = true;

  String? profileImageBase64;
  String? licenseImageBase64;
  String? rcImageBase64;

  String name = "";
  String vehicle = "";
  String rating = "5.0";
  String totalRides = "0";
  String earnings = "0";
  String joinDate = "";

  Future<void> fetchProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        name = data['name'] ?? "Driver";
        vehicle = "${data['vehicleModel']} • ${data['vehicleNumber']}";

        final double r = (data['rating'] as num?)?.toDouble() ?? 5.0;
        rating = r.toStringAsFixed(1);

        totalRides = (data['totalRides'] ?? 0).toString();

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
    await DriverPreferences.clearDriver();
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
