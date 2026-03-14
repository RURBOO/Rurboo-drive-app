import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/driver_preferences.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../../../core/utils/safe_parser.dart';

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
      if (did == null) {
        debugPrint("📍 DriverApp: Profile fetch failed. Driver ID is NULL.");
        isLoading = false;
        notifyListeners();
        return;
      }
      driverId = did;
      debugPrint("📍 DriverApp: Fetching profile for ID: $did");

      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(did)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        name = SafeParser.toStr(data['name'], fallback: "Driver");
        phone = SafeParser.toStr(data['phone'] ?? data['phoneNumber']);
        vehicleModel = SafeParser.toStr(data['vehicleModel']);
        vehicleNumber = SafeParser.toStr(data['vehicleNumber']);
        vehicle = "$vehicleModel • $vehicleNumber".trim().replaceAll(RegExp(r'^•\s*|\s*•$'), '');

        final double r = SafeParser.toDouble(data['rating'], fallback: 5.0);
        rating = r.toStringAsFixed(1);

        totalRides = SafeParser.toStr(data['totalRides'], fallback: "0");

        // Dynamic ride fetch fallback - Throttled/Safe
        try {
          final query = await FirebaseFirestore.instance
              .collection('rideRequests')
              .where('driverId', isEqualTo: did)
              .get()
              .timeout(const Duration(seconds: 5));
          
          final completedDocs = query.docs.where((d) => 
            ['completed', 'closed'].contains(d.data()['status'])
          ).length;

          if (completedDocs > SafeParser.toDouble(totalRides).toInt()) {
            totalRides = completedDocs.toString();
          }
        } catch (e) {
          debugPrint("📍 DriverApp: Extra rides fetch skipped: $e");
        }

        // Calculate today's earnings from completed rides
        try {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          final earningsQuery = await FirebaseFirestore.instance
              .collection('rideRequests')
              .where('driverId', isEqualTo: did)
              .limit(50)
              .get();

          // In-memory sort
          final List<QueryDocumentSnapshot> sortedDocs = earningsQuery.docs.toList();
          sortedDocs.sort((a, b) {
            final tsA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final tsB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (tsA == null || tsB == null) return 0;
            return tsB.compareTo(tsA);
          });

          double totalToday = 0;
          for (var rideDoc in sortedDocs) {
            final rideData = rideDoc.data() as Map<String, dynamic>;
            final rideStatus = (rideData['status'] as String? ?? '').toLowerCase();
            final isOngoing = ['pending', 'accepted', 'in_progress', 'arrived', 'started'].contains(rideStatus);
            
            if (!isOngoing) {
               final ts = rideData['createdAt'] as Timestamp?;
               if (ts != null) {
                 final rideDate = ts.toDate();
                 final dayOnly = DateTime(rideDate.year, rideDate.month, rideDate.day);
                 if (dayOnly.isAtSameMomentAs(today)) {
                   final fare = (rideData['finalFare'] as num?)?.toDouble() 
                               ?? (rideData['fare'] as num?)?.toDouble() 
                               ?? 0.0;
                   totalToday += fare;
                 }
               }
            }
          }
          earnings = "₹${totalToday.toStringAsFixed(0)}";
          
          // Count all rides that have a fare (regardless of exact status string)
          final completedRides = sortedDocs.where((d) {
            final rideStatus = ((d.data() as Map<String, dynamic>)['status'] as String? ?? '').toLowerCase();
            return !['pending', 'accepted', 'in_progress', 'arrived', 'started'].contains(rideStatus);
          }).length;
          if (completedRides > SafeParser.toDouble(totalRides).toInt()) {
            totalRides = completedRides.toString();
          }
        } catch (e) {
          debugPrint("📍 DriverApp: Today's earnings calculation failed: $e");
          earnings = "₹0";
        }

        SafeParser.toDouble(data['walletBalance']);
        // walletBalance is already handled by the Wallet section if needed, 
        // but here we keep earnings as today's gross income.

        profileImageBase64 = data['profileImage'];
        licenseImageBase64 = data['licenseImage'];
        rcImageBase64 = data['rcImage'];

        if (data['createdAt'] != null) {
          try {
             final dynamic createdAt = data['createdAt'];
             if (createdAt is Timestamp) {
               final DateTime date = createdAt.toDate();
               joinDate = "${_getMonth(date.month)} ${date.year}";
             } else {
               joinDate = "Member";
             }
          } catch (e) {
            joinDate = "Member";
            debugPrint("📍 DriverApp: Date parse error: $e");
          }
        }
        debugPrint("📍 DriverApp: Profile loaded for $name");
      } else {
        debugPrint("📍 DriverApp: Driver document NOT found in Firestore.");
      }
    } catch (e) {
      debugPrint("📍 DriverApp: Profile Fetch Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
