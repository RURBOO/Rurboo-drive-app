import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../l10n/app_localizations.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.termsAndConditions),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Markdown(data: _termsData),
    );
  }
}

const String _termsData = """
# Terms and Conditions for Rurboo Driver App

**Last Updated: February 2026**

By using the Rurboo Driver App, you agree to these Terms and Conditions. Please read them carefully.

## 1. Acceptance of Terms
By registering as a driver, you agree to comply with these terms, our Privacy Policy, and all applicable laws and regulations.

## 2. Driver Eligibility
- You must hold a valid driver's license.
- You must have a registered and insured vehicle.
- You must be at least 18 years of old (or the legal age in your jurisdiction).
- You must pass any required background checks.

## 3. Usage of the Platform
- You agree to provide safe and reliable transportation services.
- You must treat all riders with respect and not engage in any discriminatory or harmful behavior.
- You must maintain your vehicle in a safe and clean condition.
- You must not misuse the app for fraudulent activities.

## 4. Commission and Fees
**Rurboo charges a standard service fee (commission) of 20% on the total fare for each ride completed through the platform.**

- This 20% commission is deducted automatically from your ride earnings.
- The remaining 80% is your net earning.
- Additional incentives or bonuses may be offered at Rurboo's discretion and are subject to specific terms.
- Payouts are processed according to the payment schedule defined in the app.

## 5. Cancellations and No-Shows
- Excessive cancellations may lead to account suspension.
- You may be charged a fee for rider cancellations if you are not making progress towards the pickup location.

## 6. Liability
Rurboo is a technology platform connecting drivers and riders. We are not a transportation carrier and do not employ drivers. We are not liable for any damages, injuries, or losses arising from your use of the services.

## 7. Termination
We reserve the right to suspend or terminate your account at any time for violation of these terms, low ratings, or any other reason deemed necessary to protect the platform.

## 8. Amendments
We may update these terms from time to time. Continued use of the app constitutes acceptance of the new terms.

## 9. Governing Law
These terms are governed by the laws of India.

## 10. Contact Us
For any questions regarding these terms, please contact us at:
- **Email:** adarshpandey@rurboo.com
- **Phone:** +91 8810220691
""";
