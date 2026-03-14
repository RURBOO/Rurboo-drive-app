import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/driver_preferences.dart';

class EarningsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the list of earnings for a specific date range from rideRequests
  Future<List<Map<String, dynamic>>> getEarnings(
    DateTime start,
    DateTime end,
  ) async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return [];

    // Remove orderBy and range filters to avoid index requirement
    final query = await _firestore
        .collection('rideRequests')
        .where('driverId', isEqualTo: driverId)
        .get();

    return query.docs
        .map((doc) => doc.data())
        .where((data) {
          final ts = data['createdAt'] as Timestamp?;
          if (ts == null) return false;
          final date = ts.toDate();
          return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
                 date.isBefore(end.add(const Duration(seconds: 1)));
        })
        .map((data) {
          data['amount'] = (data['finalFare'] as num?)?.toDouble() 
                         ?? (data['fare'] as num?)?.toDouble() 
                         ?? 0.0;
          data['commission'] = (data['commission'] as num?)?.toDouble() ?? (data['amount'] * 0.20);
          return data;
        })
        .toList();
  }

  /// Fetches the ride history for the current driver
  Future<List<Map<String, dynamic>>> getRideHistory({int limit = 20}) async {
    final docs = await getRideHistoryDocs(limit: limit);
    
    // In-memory sort since we can't use Firestore orderBy without index
    final List<QueryDocumentSnapshot> sortedDocs = docs.toList();
    sortedDocs.sort((a, b) {
      final tsA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      final tsB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      if (tsA == null || tsB == null) return 0;
      return tsB.compareTo(tsA); // Descending
    });

    return sortedDocs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Fetches the ride history for the current driver - Lower level to allow custom sorting
  Future<List<QueryDocumentSnapshot>> getRideHistoryDocs({int limit = 50}) async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return [];

    final query = await _firestore
        .collection('rideRequests')
        .where('driverId', isEqualTo: driverId)
        .limit(limit)
        .get();

    return query.docs;
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
