import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../navigation/views/main_navigator.dart';

class DriverRideSummaryScreen extends StatefulWidget {
  final String rideId;
  final double fare;
  final String passengerName;
  final String passengerId;

  const DriverRideSummaryScreen({
    super.key,
    required this.rideId,
    required this.fare,
    required this.passengerName,
    required this.passengerId,
  });

  @override
  State<DriverRideSummaryScreen> createState() => _DriverRideSummaryScreenState();
}

class _DriverRideSummaryScreenState extends State<DriverRideSummaryScreen> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.passengerId);

      final rideRef = FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId);

      final userSnapshot = await userRef.get();
      
      if (userSnapshot.exists) {
        final data = userSnapshot.data()!;
        final double ratingSum = (data['ratingSum'] as num?)?.toDouble() ?? 0.0;
        final int ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

        final newSum = ratingSum + _rating;
        final newCount = ratingCount + 1;

        try {
          await userRef.update({
            'rating': newSum / newCount,
            'ratingSum': newSum,
            'ratingCount': newCount,
          });
        } catch (e) {
          throw Exception("Failed to update passenger profile: $e");
        }
      }
      
      try {
        await rideRef.update({
          'driverRating': _rating,
          'driverReview': _commentController.text.trim(),
        });
      } catch (e) {
        throw Exception("Failed to update ride request: $e");
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigator()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting review: $e")),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _skipRating() async {
    setState(() => _isSubmitting = true);

    try {
      final rideRef = FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(widget.rideId);

      await rideRef.update({
        'status': 'closed', 
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigator()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error skipping review: $e")),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showReportDialog(BuildContext context) {
    final reportController = TextEditingController();
    bool isSubmittingReport = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Report Issue'),
              content: TextField(
                controller: reportController,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmittingReport
                      ? null
                      : () async {
                          if (reportController.text.trim().isEmpty) return;

                          setDialogState(() => isSubmittingReport = true);
                          try {
                            final userId = FirebaseAuth.instance.currentUser?.uid;
                            if (userId == null) throw Exception("User not authenticated");
                            
                            await FirebaseFirestore.instance
                                .collection('support_tickets')
                                .add({
                              'rideId': widget.rideId,
                              'passengerName': widget.passengerName,
                              'userId': userId,
                              'issue': reportController.text.trim(),
                              'createdAt': FieldValue.serverTimestamp(),
                              'status': 'open',
                            });

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Report submitted successfully!')),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmittingReport = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  child: isSubmittingReport
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ride Completed", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.flag, color: Colors.red),
            label: const Text("Report Issue", style: TextStyle(color: Colors.red)),
            onPressed: () {
              _showReportDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text(
                "Trip Completed",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "You successfully dropped off ${widget.passengerName}.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Amount to Collect / Final Fare",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${widget.fare.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Payment Mode"),
                        Row(
                          children: const [
                            Icon(Icons.money, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Cash",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              const Text(
                "Rate Passenger",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, index) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (r) => setState(() => _rating = r),
              ),

              const SizedBox(height: 24),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Add a comment about the passenger...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit Review & Exit",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _skipRating,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
