import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final String? currentName;
  final String? currentPhone;
  final String? currentVehicleModel;
  final String? currentVehicleNumber;

  const EditProfileScreen({
    super.key,
    this.currentName,
    this.currentPhone,
    this.currentVehicleModel,
    this.currentVehicleNumber,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _vehicleModelCtrl;
  late final TextEditingController _vehicleNumberCtrl;

  bool _saving = false;
  File? _newProfileImage;
  final _picker = ImagePicker();
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _driverId = FirebaseAuth.instance.currentUser?.uid;
    _nameCtrl = TextEditingController(text: widget.currentName ?? '');
    _vehicleModelCtrl = TextEditingController(text: widget.currentVehicleModel ?? '');
    _vehicleNumberCtrl = TextEditingController(text: widget.currentVehicleNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _newProfileImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_driverId == null) return;

    setState(() => _saving = true);

    try {
      final Map<String, dynamic> updateData = {
        'name': _nameCtrl.text.trim(),
        'vehicleModel': _vehicleModelCtrl.text.trim(),
        'vehicleNumber': _vehicleNumberCtrl.text.trim().toUpperCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If new profile photo was selected, convert to Base64
      if (_newProfileImage != null) {
        final bytes = await _newProfileImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        updateData['profileImage'] = base64Image;
      }

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_driverId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // return true = refreshed
      }
    } catch (e) {
      debugPrint('Save profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.ok,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo picker
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppTheme.backgroundLight,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!)
                            : null,
                        child: _newProfileImage == null
                            ? Icon(Icons.person,
                                size: 56, color: AppTheme.textSecondary)
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.surfaceWhite, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  l10n.tapToUpload,
                  style: theme.textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 32),
              Text(l10n.personalDetailsTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppTheme.textSecondary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.nameRequired;
                  if (v.trim().length < 3) return l10n.nameLengthError;
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                enabled: false,
                initialValue: widget.currentPhone ?? '(Not available)',
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppTheme.textSecondary),
                  helperText: l10n.phoneCannotBeChanged,
                ),
              ),

              const SizedBox(height: 32),
              Text(l10n.vehicleDetailsTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vehicleModelCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.vehicleMakeModel,
                  hintText: 'e.g. Maruti Swift DZire',
                  prefixIcon: const Icon(Icons.directions_car_outlined,
                      color: AppTheme.textSecondary),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _vehicleNumberCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  labelText: l10n.vehicleNumberLabel,
                  hintText: 'e.g. MH12AB1234',
                  prefixIcon: const Icon(Icons.tag,
                      color: AppTheme.textSecondary),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'Invalid vehicle number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(l10n.saveChanges),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
