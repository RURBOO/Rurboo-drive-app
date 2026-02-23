import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../../../l10n/app_localizations.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false;
  final _reasonController = TextEditingController();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();
      final double balance =
          (driverDoc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;

      if (balance < 0) {
        throw Exception(
          l10n.pendingDuesError(balance.abs().toStringAsFixed(0)),
        );
      }

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({
            'status': 'deleted',
            'fcmToken': FieldValue.delete(),
            'phone': '${driverDoc.data()?['phone']}_deleted',
            'deletedAt': FieldValue.serverTimestamp(),
            'deletionReason': _reasonController.text.trim(),
          });

      await user.delete();

      await DriverPreferences.clearDriver();
      if (mounted) {
        context.read<AppStateViewModel>().signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accountDeletedSuccess)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showReauthDialog();
      } else {
        _showError(e.message ?? "Error deleting account");
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showReauthDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.securityCheck),
        content: Text(l10n.reauthRequired),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppStateViewModel>().signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
            child: Text(l10n.logoutNow),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deleteAccount),
        backgroundColor: Colors.white,
        foregroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.deleteAccountConfirm,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.deleteAccountDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: l10n.reasonOptional,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _deleteAccount,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.permanentlyDelete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
