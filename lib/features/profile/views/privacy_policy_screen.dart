import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: January 2025',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 24),
            _PolicySection(
              title: '1. Information We Collect',
              content:
                  'We collect your name, phone number, vehicle details, and government-issued documents (License, RC) for verification purposes.',
            ),
            _PolicySection(
              title: '2. Background Location Data',
              content:
                  'Rubo Driver collects location data to enable "Ride Allocation" and "Trip Tracking" even when the app is closed or not in use. This is essential to find passengers near you.',
            ),
            _PolicySection(
              title: '3. Data Sharing',
              content:
                  'We share your live location and vehicle details with the passenger who booked the ride. We also share data with legal authorities if required by law.',
            ),
            _PolicySection(
              title: '4. Earnings & Payments',
              content:
                  'We securely store your earnings history and transaction details. We do not store full bank account details directly on our servers.',
            ),
            _PolicySection(
              title: '5. Account Deletion',
              content:
                  'You can delete your account from the Settings menu. Note: You must clear any pending platform dues before deletion.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
