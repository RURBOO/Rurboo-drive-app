import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/driver_preferences.dart';

class EarningsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the list of earnings for a specific date range
  Future<List<Map<String, dynamic>>> getEarnings(
    DateTime start,
    DateTime end,
  ) async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return [];

    final query = await _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('earnings')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => doc.data()).toList();
  }

  /// Fetches the ride history for the current driver
  Future<List<Map<String, dynamic>>> getRideHistory({int limit = 20}) async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return [];

    final query = await _firestore
        .collection('rideRequests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include Doc ID
      return data;
    }).toList();
  }

  /// Fetches today's total earnings
  Future<double> getTodayEarnings() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final earnings = await getEarnings(startOfDay, endOfDay);
    
    double total = 0;
    for (var e in earnings) {
      total += (e['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }
}
