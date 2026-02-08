import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../repositories/earnings_repository.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final EarningsRepository _repo = EarningsRepository();
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getRideHistory(limit: 50);
      if (mounted) {
        setState(() {
          _rides = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.history),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rides.isEmpty
              ? Center(child: Text(AppLocalizations.of(context)!.noHistory))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rides.length,
                  itemBuilder: (context, index) {
                    final ride = _rides[index];
                    return _buildHistoryCard(ride);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ride) {
    final ts = ride['completedAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
        : AppLocalizations.of(context)!.unknown;
    final amount = (ride['finalFare'] as num?)?.toDouble() ?? 0.0;

    // final commission = (ride['commission'] as num?)?.toDouble() ?? 0.0;
    final pickup = ride['pickupAddress'] ?? AppLocalizations.of(context)!.unknown;
    final drop = ride['destinationAddress'] ?? AppLocalizations.of(context)!.unknown;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLocationRow(Icons.circle, Colors.green, pickup),
            const SizedBox(height: 8),
            _buildLocationRow(Icons.square, Colors.red, drop),
            const Divider(height: 24),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(AppLocalizations.of(context)!.status, style: const TextStyle(color: Colors.grey)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: Colors.green.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(4),
                   ),
                   child: Text(AppLocalizations.of(context)!.completed, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                 )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, color: color, size: 10),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
