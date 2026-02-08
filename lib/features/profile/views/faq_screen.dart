import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.faqs),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _FaqItem(
            question: "How much commission does Rurboo charge?",
            answer: "Rurboo charges a standard commission of 20% on the total fare for each completed ride. This helps us maintain the platform, market to riders, and provide support to you.",
          ),
          _FaqItem(
            question: "How do I get paid?",
            answer: "Your earnings (minus the 20% commission) are accumulated in your driver wallet. Payouts are processed weekly to your registered bank account or UPI ID.",
          ),
          _FaqItem(
            question: "What if a rider cancels?",
            answer: "If a rider cancels after you have already traveled a significant distance towards the pickup location, you may be eligible for a cancellation fee.",
          ),
          _FaqItem(
            question: "How can I improve my rating?",
            answer: "Keep your vehicle clean, be polite to riders, drive safely, and follow the navigation route. Good service leads to higher ratings and potentially more ride requests.",
          ),
           _FaqItem(
            question: "Is there a penalty for declining rides?",
            answer: "We understand you may not be able to accept every ride. However, maintaining a high acceptance rate helps ensure a reliable service for riders and may unlock special incentives for you.",
          ),
           _FaqItem(
            question: "How do I contact support?",
            answer: "You can contact support via the 'Help & Support' section in the app. We are available via email at adarshpandey@rurboo.com or by phone at +91 8810220691.",
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
