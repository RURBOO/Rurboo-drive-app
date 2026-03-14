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
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(const Duration(days: 6));

      // Fetch a larger batch of ride history to cover today and weekly stats
      // Removed orderBy to avoid index requirement, sorting in-memory below
      final historyDocs = await _repository.getRideHistoryDocs(limit: 50);

      todayGross = 0;
      todayCommission = 0;
      todayRides = 0;
      weeklyGross = 0;
      weeklyCommission = 0;

      // Initialize daily earnings for the chart (last 7 days)
      dailyEarnings = List.filled(7, 0.0);
      dailyLabels = [];
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        dailyLabels.add(DateFormat('E').format(day)[0]);
      }

      rideHistory = [];

      // In-memory sort since we can't use Firestore orderBy without index
      final List<QueryDocumentSnapshot> sortedDocs = historyDocs;
      sortedDocs.sort((a, b) {
        final tsA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        final tsB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        if (tsA == null || tsB == null) return 0;
        return tsB.compareTo(tsA); // Descending
      });

      for (var doc in sortedDocs) {
        final data = doc.data() as Map<String, dynamic>;
        // Map raw data for history view
        final ts = (data['completedAt'] ?? data['createdAt']) as Timestamp?;
        final timestamp = ts != null ? ts.toDate() : DateTime.now();
        final rideDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

        final double gross = (data['finalFare'] as num?)?.toDouble() 
                           ?? (data['fare'] as num?)?.toDouble() 
                           ?? 0.0;
        final double comm = (data['commission'] as num?)?.toDouble() ?? (gross * 0.20);

        // Add to history list regardless of status (show all rides)
        if (rideHistory.length < 10 && gross > 0) {
          final dateStr = ts != null
              ? DateFormat('dd MMM, hh:mm a').format(ts.toDate())
              : 'Unknown Date';
          rideHistory.add(EarningItem(
            date: dateStr,
            amount: gross,
            commission: comm,
            pickup: data['pickupAddress'] ?? 'Unknown Pickup',
            drop: data['destinationAddress'] ?? 'Unknown Drop',
          ));
        }

        // Aggregate stats: count any ride that has a fare (completed/closed/done etc.)
        // Exclude actively ongoing rides (pending/accepted/in_progress/arrived)
        final status = (data['status'] as String? ?? '').toLowerCase();
        final isOngoing = ['pending', 'accepted', 'in_progress', 'arrived', 'started'].contains(status);
        
        if (!isOngoing && gross > 0) {
          // Today's stats
          if (rideDate.isAtSameMomentAs(today)) {
            todayGross += gross;
            todayCommission += comm;
            todayRides++;
          }

          // Weekly stats & Chart
          if (rideDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) && rideDate.isBefore(today.add(const Duration(days: 1)))) {
            weeklyGross += gross;
            weeklyCommission += comm;

            final diff = today.difference(rideDate).inDays;
            if (diff >= 0 && diff < 7) {
              int index = 6 - diff;
              dailyEarnings[index] += gross;
            }
          }
        }
      }

    } catch (e) {
      debugPrint("Error loading earnings: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
