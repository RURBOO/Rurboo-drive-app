import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.privacyPolicy),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
      ),
      body: const Markdown(data: _privacyPolicyData),
    );
  }
}

const String _privacyPolicyData = """
# Privacy Policy for Rurboo Driver App

**Last Updated: February 2026**

Welcome to Rurboo! This Privacy Policy explains how Rurboo ("we," "us," or "our") collects, uses, and protects your information when you use our Driver Application.

## 1. Information We Collect
We collect the following types of information:
- **Personal Information:** Name, phone number, email address, vehicle details, and government-issued ID for verification.
- **Location Data:** We collect precise location data to match you with nearby riders and track rides. This data is collected when the app is running in the foreground or background (when you are online).
- **Transaction Data:** Details of trips, earnings, and payouts.

## 2. How We Use Your Information
- To provide ride-hailing services.
- To verify your identity and vehicle.
- To process payments and earnings.
- To enhance safety and security for both drivers and riders.
- To communicate with you regarding updates, support, and promotions.

## 3. Sharing Your Information
We may share your information with:
- **Riders:** Your name, photo, vehicle details, and real-time location during a trip.
- **Service Providers:** Third-party vendors for payments, background checks, and cloud services.
- **Legal Authorities:** If required by law or to protect user safety.

## 4. Data Security
We implement robust security measures to protect your data. However, no method of transmission over the internet is 100% secure.

## 5. Your Rights
You may request access to, correction of, or deletion of your personal data by contacting our support team.

## 6. Contact Us
For any privacy-related questions, please contact us at:
- **Email:** adarshpandey@rurboo.com
- **Phone:** +91 8810220691
""";
