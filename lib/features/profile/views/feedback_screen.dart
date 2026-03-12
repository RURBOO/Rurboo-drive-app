import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _isSubmitting = false;

  List<String> _getCategories(AppLocalizations l10n) => [
    l10n.feedbackCatSuggestion,
    l10n.feedbackCatAppIssue,
    l10n.feedbackCatPaymentIssue,
    l10n.feedbackCatSafetyConcern,
    l10n.feedbackCatOther,
  ];

  // English keys to store in Firestore regardless of UI locale
  final List<String> _categoryKeys = [
    'Suggestion', 'App Issue', 'Payment Issue', 'Safety Concern', 'Other'
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance.collection('feedback').add({
        'driverId': user.uid,
        'category': _categoryKeys[_selectedCategoryIndex],
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
        'platform': 'android',
        'appVersion': '1.0.0',
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.thankYou),
          content: Text(l10n.feedbackSubmitted),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorFeedback(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = _getCategories(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.feedbackAndSuggestions),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.feedbackHeading,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.feedbackSubheading,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.feedbackCategory,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCategoryIndex,
                    isExpanded: true,
                    items: List.generate(categories.length, (i) =>
                      DropdownMenuItem<int>(value: i, child: Text(categories[i]))
                    ),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedCategoryIndex = newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject Field
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: l10n.feedbackSubject,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.feedbackSubjectRequired;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Message Field
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.feedbackDescription,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: l10n.feedbackDescriptionHint,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.feedbackDescRequired;
                  if (value.length < 10) return l10n.feedbackDescMin;
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          l10n.feedbackSubmitBtn,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
