import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/driver_voice_service.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'driver_documents_screen.dart';
import 'my_vehicles_screen.dart';
import '../../../state/language_provider.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';
import 'package:rubo_driver/features/profile/views/privacy_policy_screen.dart';
import 'package:rubo_driver/features/profile/views/terms_conditions_screen.dart';
import 'package:rubo_driver/features/profile/views/help_support_screen.dart';
import 'package:rubo_driver/features/profile/views/faq_screen.dart';
import 'package:rubo_driver/features/profile/views/feedback_screen.dart';
import 'delete_account_screen.dart';

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

class _ProfileScreenBody extends StatefulWidget {
  const _ProfileScreenBody();

  @override
  State<_ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends State<_ProfileScreenBody> {
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadVoicePreference();
  }

  Future<void> _loadVoicePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceEnabled = prefs.getBool('voice_announcements_enabled') ?? true;
    });
  }

  Future<void> _toggleVoice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_announcements_enabled', value);
    setState(() {
      _voiceEnabled = value;
    });
    
    final voiceService = DriverVoiceService();
    if (value) {
      voiceService.announceSuccess("Voice announcements enabled");
    } else {
      voiceService.announceSuccess("Voice announcements disabled");
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Header Background
                Container(
                  height: 280,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1a1a1a), Color(0xFF000000)],
                    ),
                  ),
                ),
                
                SafeArea(
                  child: Column(
                    children: [
                      // App Bar Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                             Text(
                               "My Profile",
                               style: TextStyle(
                                 color: Colors.white,
                                 fontSize: 18,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Profile Info
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[800],
                              backgroundImage:
                                  (vm.profileImageBase64 != null &&
                                      vm.profileImageBase64!.isNotEmpty)
                                  ? MemoryImage(base64Decode(vm.profileImageBase64!))
                                  : null,
                              child: (vm.profileImageBase64 == null)
                                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            vm.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Joined ${vm.joinDate}",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content (DraggableScrollableSheet or just positioned list)
                // We'll use a Positioned/Expanded approach for simplicity
                Positioned.fill(
                  top: 260,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.grey, // Placeholder, usually white
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // Background for list
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                        child: Column(
                          children: [
                            // Stats Row
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat("Rating", vm.rating, Icons.star, Colors.amber),
                                  Container(width: 1, height: 40, color: Colors.grey[200]),
                                  _buildStat("Rides", vm.totalRides, Icons.local_taxi, Colors.blue),
                                  Container(width: 1, height: 40, color: Colors.grey[200]),
                                  _buildStat("Wallet", vm.earnings, Icons.account_balance_wallet, Colors.green),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),

                            // Menu Groups
                            _buildSectionHeader("Account"),
                            _buildMenuCard([
                              _buildMenuItem(
                                icon: Icons.document_scanner_rounded,
                                title: 'My Documents',
                                subtitle: 'License, RC & Profile',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DriverDocumentsScreen(
                                      licenseBase64: vm.licenseImageBase64,
                                      rcBase64: vm.rcImageBase64,
                                    ),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.directions_car_filled_outlined,
                                title: 'My Vehicles',
                                subtitle: 'Manage Vehicles',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MyVehiclesScreen()),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.language,
                                title: 'App Language / भाषा',
                                subtitle: 'Change Language / भाषा बदलें',
                                onTap: () => _showLanguageDialog(context),
                              ),
                            ]),

                            const SizedBox(height: 24),
                            _buildSectionHeader("Preferences"),
                            _buildMenuCard([
                              _buildSwitchMenuItem(
                                icon: Icons.record_voice_over_rounded,
                                title: 'Voice Announcements',
                                subtitle: 'Turn on/off app voice',
                                value: _voiceEnabled,
                                onChanged: _toggleVoice,
                                color: Colors.deepPurple,
                              ),
                            ]),

                            const SizedBox(height: 24),
                            _buildSectionHeader("Support & Legal"),
                            _buildMenuCard([
                              _buildMenuItem(
                                icon: Icons.feedback_outlined,
                                title: AppLocalizations.of(context)!.feedbackAndSuggestions,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.help_outline_rounded,
                                title: AppLocalizations.of(context)!.helpAndSupport,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.question_answer_outlined,
                                title: AppLocalizations.of(context)!.faqs,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.privacy_tip_outlined,
                                title: AppLocalizations.of(context)!.privacyPolicy,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.description_outlined,
                                title: AppLocalizations.of(context)!.termsAndConditions,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                                ),
                              ),
                            ]),

                            const SizedBox(height: 24),
                            _buildMenuCard([
                              _buildMenuItem(
                                icon: Icons.delete_forever,
                                title: 'Delete Account',
                                color: Colors.red,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.logout,
                                title: 'Logout',
                                color: Colors.red,
                                onTap: () => vm.logout(context),
                              ),
                            ]),
                            
                            const SizedBox(height: 30),
                            Text(
                              "Rubo Driver v1.0.0",
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Language / भाषा चुनें"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("English"),
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                onTap: () {
                  context.read<LanguageProvider>().changeLanguage(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text("हिंदी (Hindi)"),
                leading: const Text("🇮🇳", style: TextStyle(fontSize: 24)),
                onTap: () {
                  context.read<LanguageProvider>().changeLanguage(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
  
  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEEEEEE));
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color color = Colors.black87,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      activeThumbColor: Colors.green, // Replaced activeColor
      activeTrackColor: Colors.green.withValues(alpha: 0.4),
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}
