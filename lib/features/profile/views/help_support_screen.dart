import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/driver_preferences.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedReasonIndex;
  File? _screenshotFile;
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  // English keys for Firestore storage (admin-friendly)
  final List<String> _reasonKeys = [
    "Payment Issue",
    "App Bug",
    "Ride Issue",
    "Account Issue",
    "Other"
  ];

  List<String> _getReasons(AppLocalizations l10n) => [
    l10n.helpReason1,
    l10n.helpReason2,
    l10n.helpReason3,
    l10n.helpReason4,
    l10n.helpReason5,
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _screenshotFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitTicket() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) throw Exception("Driver not found");

      String? imageUrl;
      if (_screenshotFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('support_tickets')
            .child('${DateTime.now().millisecondsSinceEpoch}_$driverId.jpg');
        await ref.putFile(_screenshotFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'driverId': driverId,
        'reason': _selectedReasonIndex != null ? _reasonKeys[_selectedReasonIndex!] : 'Other',
        'description': _descController.text.trim(),
        'imageUrl': imageUrl,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'userType': 'driver',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.ticketSubmitted)),
        );
        setState(() {
          _selectedReasonIndex = null;
          _descController.clear();
          _screenshotFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.ticketFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = _getReasons(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpAndSupport),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.helpHowCanWeHelp,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.helpSubheading,
              style: const TextStyle(fontSize: 16, ),
            ),
            const SizedBox(height: 30),

            // Submit a Ticket Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helpSubmitTicket,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: l10n.helpReason,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      initialValue: _selectedReasonIndex,
                      items: List.generate(
                        reasons.length,
                        (i) => DropdownMenuItem(value: i, child: Text(reasons[i])),
                      ),
                      onChanged: (val) => setState(() => _selectedReasonIndex = val),
                      validator: (val) => val == null ? l10n.helpSelectReason : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: l10n.helpDescription,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (val) => val == null || val.isEmpty ? l10n.helpDescRequired : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _screenshotFile == null
                                ? l10n.helpAttachFile
                                : l10n.helpImageAttached(_screenshotFile!.path.split('/').last),
                            style: TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.blue),
                          onPressed: _pickImage,
                        ),
                        if (_screenshotFile != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _screenshotFile = null),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSubmitting ? null : _submitTicket,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                l10n.submitTicket,
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                l10n.appVersion,
                style: TextStyle(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
