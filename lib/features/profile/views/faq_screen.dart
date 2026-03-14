import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.faqs),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _FaqItem(
            question: l10n.faqQ1,
            answer: l10n.faqA1,
          ),
          _FaqItem(
            question: l10n.faqQ2,
            answer: l10n.faqA2,
          ),
          _FaqItem(
            question: l10n.faqQ3,
            answer: l10n.faqA3,
          ),
          _FaqItem(
            question: l10n.faqQ4,
            answer: l10n.faqA4,
          ),
          _FaqItem(
            question: l10n.faqQ5,
            answer: l10n.faqA5,
          ),
          _FaqItem(
            question: l10n.faqQ6,
            answer: l10n.faqA6,
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
