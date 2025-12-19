import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/driver_preferences.dart';

class EarningItem {
  final String date;
  final String pickup;
  final String drop;
  final double amount;
  final double commission;

  EarningItem({
    required this.date,
    required this.pickup,
    required this.drop,
    required this.amount,
    required this.commission,
  });
}

class EarningsViewModel extends ChangeNotifier {
  double todayGross = 0;
  double todayCommission = 0;
  double get todayNet => todayGross - todayCommission;
  int todayRides = 0;

  double weeklyGross = 0;
  double weeklyCommission = 0;
  double get weeklyNet => weeklyGross - weeklyCommission;

  List<EarningItem> rideHistory = [];
  bool isLoading = true;

  Future<void> fetchEarnings() async {
    isLoading = true;
    notifyListeners();

    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .get();

      rideHistory = [];
      todayGross = 0;
      todayCommission = 0;
      todayRides = 0;
      weeklyGross = 0;
      weeklyCommission = 0;

      final now = DateTime.now();

      for (var doc in query.docs) {
        final data = doc.data();

        final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final double comm = (data['commission'] as num?)?.toDouble() ?? 0.0;
        final Timestamp? ts = data['createdAt'];

        if (ts == null) continue;
        final DateTime date = ts.toDate();

        rideHistory.add(
          EarningItem(
            date: DateFormat('MMM d, hh:mm a').format(date),
            pickup: data['pickup'] ?? 'Unknown',
            drop: data['drop'] ?? 'Unknown',
            amount: amount,
            commission: comm,
          ),
        );

        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          todayGross += amount;
          todayCommission += comm;
          todayRides++;
        }

        if (now.difference(date).inDays < 7) {
          weeklyGross += amount;
          weeklyCommission += comm;
        }
      }
    } catch (e) {
      debugPrint("Error fetching earnings: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}
