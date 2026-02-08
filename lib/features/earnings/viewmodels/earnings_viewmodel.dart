import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/earnings_repository.dart';

class EarningItem {
  final String date;
  final double amount;
  final double commission;
  final String pickup;
  final String drop;

  EarningItem({
    required this.date,
    required this.amount,
    required this.commission,
    required this.pickup,
    required this.drop,
  });
}

class EarningsViewModel extends ChangeNotifier {
  final EarningsRepository _repository = EarningsRepository();

  bool isLoading = false;

  // Today's Stats
  double todayGross = 0.0;
  double todayCommission = 0.0;
  double get todayNet => todayGross - todayCommission;
  int todayRides = 0;

  // Weekly Stats
  double weeklyGross = 0.0;
  double weeklyCommission = 0.0;
  double get weeklyNet => weeklyGross - weeklyCommission;
  
  // For Chart
  List<double> dailyEarnings = [];
  List<String> dailyLabels = [];

  List<EarningItem> rideHistory = [];

  Future<void> fetchEarnings() async {
    isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      
      // 1. Today's Data
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayDocs = await _repository.getEarnings(startOfDay, endOfDay);
      
      todayGross = 0;
      todayCommission = 0;
      todayRides = todayDocs.length;
      
      for (var doc in todayDocs) {
        todayGross += (doc['amount'] as num?)?.toDouble() ?? 0.0;
        todayCommission += (doc['commission'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Weekly Data
      final startOfWeek = now.subtract(const Duration(days: 7));
      final weeklyDocs = await _repository.getEarnings(startOfWeek, now);
      
      
      // Initialize daily earnings for the chart (last 7 days)
      dailyEarnings = List.filled(7, 0.0);
      dailyLabels = [];
      
      // Generate labels (e.g., M, T, W)
      for (int i = 0; i < 7; i++) {
        // startOfWeek is now - 7 days. So today is day 7.
        // Let's align 0 -> 6 days ago, 6 -> Today.
        // Actually, startOfWeek = now - 7d. 
        // day 0 = now - 6d.
        // day 6 = now.
        final day = now.subtract(Duration(days: 6 - i));
        dailyLabels.add(DateFormat('E').format(day)[0]); // First letter of Day
      }

      weeklyGross = 0;
      weeklyCommission = 0;
      
      for (var doc in weeklyDocs) {
        final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
        final commission = (doc['commission'] as num?)?.toDouble() ?? 0.0;
        final timestamp = (doc['completedAt'] as Timestamp).toDate();
        
        weeklyGross += amount;
        weeklyCommission += commission;

        // Find which day bucket this falls into (0..6)
        // 0 is 6 days ago, 6 is today.
        final diff = now.difference(timestamp).inDays;
        // diff = 0 (today) -> index 6
        // diff = 6 (7 days ago) -> index 0
        if (diff >= 0 && diff < 7) {
          int index = 6 - diff;
          dailyEarnings[index] += amount;
        }
      }

      // 3. Recent Rides History
      final historyDocs = await _repository.getRideHistory(limit: 10);
      rideHistory = historyDocs.map((data) {
        final ts = data['completedAt'] as Timestamp?;
        final dateStr = ts != null 
            ? DateFormat('dd MMM, hh:mm a').format(ts.toDate()) 
            : 'Unknown Date';
            
        return EarningItem(
          date: dateStr,
          amount: (data['finalFare'] as num?)?.toDouble() ?? 0.0,
          commission: (data['commission'] as num?)?.toDouble() ?? 0.0,
          pickup: data['pickupAddress'] ?? 'Unknown Pickup',
          drop: data['destinationAddress'] ?? 'Unknown Drop',
        );
      }).toList();
      
    } catch (e) {
      debugPrint("Error loading earnings: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
