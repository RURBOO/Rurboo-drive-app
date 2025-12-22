import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cannot open app")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Support")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Contact Us",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text("Emergency / Helpline"),
            subtitle: const Text("+91 98765 43210"),
            onTap: () =>
                _launch(context, Uri(scheme: 'tel', path: '+919876543210')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text("Email Support"),
            subtitle: const Text("drivers@rubo.com"),
            onTap: () => _launch(
              context,
              Uri(scheme: 'mailto', path: 'drivers@rubo.com'),
            ),
          ),
        ],
      ),
    );
  }
}
