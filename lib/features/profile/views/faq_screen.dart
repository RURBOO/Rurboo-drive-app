import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Driver FAQ', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Common Questions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _FAQItem(
            question: 'Why is my account blocked?',
            answer:
                'Your account may be blocked if your wallet balance is below -₹500 or if you have pending dues from yesterday. Please recharge to unblock.',
          ),
          _FAQItem(
            question: 'How do I pay the platform fee?',
            answer:
                'When you are blocked, a "Pay Now" button will appear. You can pay via UPI or Cash deposit.',
          ),
          _FAQItem(
            question: 'What is the 15-Day Free Trial?',
            answer:
                'For the first 15 days after joining, you pay ₹0 commission. You keep 100% of your earnings.',
          ),
          _FAQItem(
            question: 'How do I change my vehicle details?',
            answer:
                'You cannot change vehicle details in the app. Please contact support to update your RC or License.',
          ),
          _FAQItem(
            question: 'Does the app work in background?',
            answer:
                'Yes, you must allow "Allow all the time" location permission to receive rides while using other apps.',
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
