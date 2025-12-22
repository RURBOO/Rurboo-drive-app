import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubo_driver/features/profile/views/support_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'delete_account_screen.dart';
import 'driver_documents_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..fetchProfile(),
      child: const _ProfileScreenBody(),
    );
  }
}

class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody();

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open link")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.black,
                        backgroundImage:
                            (vm.profileImageBase64 != null &&
                                vm.profileImageBase64!.isNotEmpty)
                            ? MemoryImage(base64Decode(vm.profileImageBase64!))
                            : null,
                        child:
                            (vm.profileImageBase64 == null ||
                                vm.profileImageBase64!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        vm.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vm.joinDate,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            "Rating",
                            vm.rating,
                            Icons.star,
                            Colors.amber,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildStat(
                            "Rides",
                            vm.totalRides,
                            Icons.local_taxi,
                            Colors.blue,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          _buildStat(
                            "Earnings",
                            vm.earnings,
                            Icons.account_balance_wallet,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.directions_car,
                        title: 'Vehicle Details',
                        subtitle: vm.vehicle,
                        onTap: () {},
                      ),

                      const Divider(height: 1, indent: 60),

                      _buildMenuItem(
                        icon: Icons.document_scanner_outlined,
                        title: 'Documents',
                        subtitle: 'License, RC, Insurance',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverDocumentsScreen(
                                licenseBase64: vm.licenseImageBase64,
                                rcBase64: vm.rcImageBase64,
                              ),
                            ),
                          );
                        },
                      ),

                      const Divider(height: 1, indent: 60),

                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Contact us for assistance',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SupportScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => _launchURL(
                          context,
                          'https://www.yourdomain.com/privacy',
                        ),
                      ),
                      const Divider(height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        onTap: () => _launchURL(
                          context,
                          'https://www.yourdomain.com/terms',
                        ),
                      ),
                      const Divider(height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.delete_forever,
                        title: 'Delete Account',
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DeleteAccountScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: Colors.red,
                    onTap: () => vm.logout(context),
                  ),
                ),

                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "App Version 1.0.0",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color color = Colors.black87,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          : null,
      trailing: (title != 'Logout')
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
