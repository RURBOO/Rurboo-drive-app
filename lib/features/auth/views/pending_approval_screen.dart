import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../../core/services/driver_preferences.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => isChecking = true);

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) return;

      debugPrint("Checking status for Driver ID: $driverId");
      
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      debugPrint("Firestore Data: ${doc.data()}");
      final status = doc.data()?['status'];
      debugPrint("Current Status: '$status'");

      if (doc.exists && status == 'verified') {
        debugPrint("PendingApproval: Manual check found 'verified'. State will update reactively.");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Still Pending. Please wait for Admin approval."),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Status check error: $e");
    } finally {
      if (mounted) setState(() => isChecking = false);
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    await DriverPreferences.clearDriverId();

    if (context.mounted) {
      context.read<AppStateViewModel>().signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Animated Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2), width: 2),
                    ),
                    child: const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 64,
                      color: Colors.orange,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                const Text(
                  "Application Pending",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                
                const SizedBox(height: 20),

                const Text(
                  "Your docs approval is pending now",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.orange, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),

                Text(
                  "Your profile is currently under review by the Admin Team.\n\nOnce approved, you will be able to accept rides and start earning.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.grey.shade400, 
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Status Check Button
                TextButton.icon(
                  onPressed: isChecking ? null : _checkStatus,
                  icon: isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                        )
                      : const Icon(Icons.refresh, color: Colors.blue),
                  label: Text(
                    isChecking ? "Checking Status..." : "Refresh Status",
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 24),

                // Secondary Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _handleSignOut(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      "Sign Out / Go Back",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
