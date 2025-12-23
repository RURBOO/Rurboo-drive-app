import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
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
              'Driver Terms of Service',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _TermSection(
              title: '1. Platform Fees',
              content:
                  'Rubo charges a 15% platform fee on every ride. New drivers enjoy a 15-day free trial with 0% commission.',
            ),
            _TermSection(
              title: '2. Wallet & Settlement',
              content:
                  'Drivers must maintain a wallet balance above -₹500. If the limit is crossed, the account will be temporarily blocked until dues are cleared.',
            ),
            _TermSection(
              title: '3. Daily Settlement',
              content:
                  'Drivers are required to settle any negative wallet balance daily to continue receiving rides the next day.',
            ),
            _TermSection(
              title: '4. Zero Tolerance',
              content:
                  'Any driver found using fake GPS, harassing passengers, or violating safety norms will be permanently banned.',
            ),
            _TermSection(
              title: '5. Documents',
              content:
                  'You declare that all documents uploaded (License, RC, Insurance) are valid and belong to you.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  final String title;
  final String content;
  const _TermSection({required this.title, required this.content});

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
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
