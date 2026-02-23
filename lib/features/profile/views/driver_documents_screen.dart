import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class DriverDocumentsScreen extends StatefulWidget {
  // Legacy params kept for backward compat but no longer primary data source
  final String? licenseBase64;
  final String? rcBase64;

  const DriverDocumentsScreen({
    super.key,
    this.licenseBase64,
    this.rcBase64,
  });

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _driverId;

  final Map<String, String?> _docUrls = {
    'dl': null,
    'rc': null,
    'insurance': null,
    'vehicle_front': null,
  };

  final Map<String, bool> _uploading = {
    'dl': false,
    'rc': false,
    'insurance': false,
    'vehicle_front': false,
  };

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    _driverId = FirebaseAuth.instance.currentUser?.uid;
    if (_driverId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('drivers').doc(_driverId).get();
      final data = doc.data() ?? {};
      final docs = data['documents'] as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          _docUrls['dl'] = docs['dl'] as String?;
          _docUrls['rc'] = docs['rc'] as String?;
          _docUrls['insurance'] = docs['insurance'] as String?;
          _docUrls['vehicle_front'] = docs['vehicle_front'] as String?;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Load docs error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload(String docKey) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _uploading[docKey] = true);

    try {
      final file = File(image.path);
      final ref = _storage.ref('driver_docs/$_driverId/$docKey.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _firestore.collection('drivers').doc(_driverId).update({
        'documents.$docKey': url,
      });

      if (mounted) {
        setState(() {
          _docUrls[docKey] = url;
          _uploading[docKey] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_docLabel(docKey)} uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        setState(() => _uploading[docKey] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _docLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'dl':
        return l10n.drivingLicense;
      case 'rc':
        return l10n.rc;
      case 'insurance':
        return l10n.insurance;
      case 'vehicle_front':
        return l10n.vehicleFront;
      default:
        return key.toUpperCase();
    }
  }

  String _docHint(String key) {
    switch (key) {
      case 'dl':
        return 'Driving Licence';
      case 'rc':
        return 'Registration Certificate';
      case 'insurance':
        return 'Vehicle Insurance';
      case 'vehicle_front':
        return 'Front photo showing plate';
      default:
        return '';
    }
  }

  IconData _docIcon(String key) {
    switch (key) {
      case 'dl':
        return Icons.badge_outlined;
      case 'rc':
        return Icons.app_registration;
      case 'insurance':
        return Icons.shield_outlined;
      case 'vehicle_front':
        return Icons.directions_car_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.myDocuments),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myDocuments,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.numberPlateHint,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Document cards in 2x2 grid for the first 4 docs
                  ...['dl', 'rc', 'insurance', 'vehicle_front'].map(
                    (key) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDocCard(key, theme),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDocCard(String key, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final url = _docUrls[key];
    final isUploading = _uploading[key] ?? false;
    final hasDoc = url != null && url.isNotEmpty;

    return GestureDetector(
      onTap: isUploading ? null : () => _pickAndUpload(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasDoc
              ? Colors.green.withValues(alpha: 0.05)
              : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDoc ? Colors.green.withValues(alpha: 0.4) : AppTheme.dividerColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview or placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                width: double.infinity,
                height: 160,
                child: isUploading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Uploading...'),
                          ],
                        ),
                      )
                    : hasDoc
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                _docIcon(key),
                                size: 48,
                                color: Colors.green,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF4F7F6),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _docIcon(key),
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.tapToUpload,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ),

            // Label row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docLabel(key),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _docHint(key),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasDoc
                          ? Colors.green.withValues(alpha: 0.1)
                          : AppTheme.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasDoc ? Icons.check_circle : Icons.upload_rounded,
                      size: 20,
                      color: hasDoc ? Colors.green : AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            if (hasDoc)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: TextButton.icon(
                  onPressed: () => _pickAndUpload(key),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.ok), // Re-upload or Replace
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppTheme.primaryBlue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
