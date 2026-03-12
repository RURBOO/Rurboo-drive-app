import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Markdown(data: isHindi ? _privacyPolicyHindi : _privacyPolicyEnglish),
    );
  }
}

const String _privacyPolicyHindi = """
# रूरबू ड्राइवर ऐप — गोपनीयता नीति

**अंतिम अपडेट: फ़रवरी २०२६**

रूरबू में आपका स्वागत है! यह गोपनीयता नीति बताती है कि जब आप हमारे ड्राइवर ऐप का उपयोग करते हैं तो रूरबू ("हम", "हमारा") आपकी जानकारी कैसे एकत्र, उपयोग और सुरक्षित करता है।

## १. हम क्या जानकारी एकत्र करते हैं
- **व्यक्तिगत जानकारी:** नाम, फ़ोन नंबर, ईमेल, वाहन विवरण, और पहचान दस्तावेज़।
- **स्थान डेटा:** ऐप चलते समय आपकी सटीक लोकेशन ली जाती है ताकि पास के यात्रियों से मिलान हो सके।
- **लेनदेन डेटा:** यात्राएं, कमाई और भुगतान विवरण।

## २. हम आपकी जानकारी का उपयोग कैसे करते हैं
- राइड-हेलिंग सेवाएं प्रदान करने के लिए।
- आपकी पहचान और वाहन सत्यापित करने के लिए।
- भुगतान और कमाई प्रोसेस करने के लिए।
- ड्राइवर और यात्री दोनों की सुरक्षा सुनिश्चित करने के लिए।

## ३. जानकारी साझा करना
हम आपकी जानकारी निम्नलिखित से साझा कर सकते हैं:
- **यात्री:** यात्रा के दौरान आपका नाम, फ़ोटो, वाहन विवरण और लोकेशन।
- **सेवा प्रदाता:** भुगतान, बैकग्राउंड चेक और क्लाउड सेवाओं के लिए।
- **कानूनी अधिकारी:** यदि कानून की आवश्यकता हो।

## ४. डेटा सुरक्षा
हम आपके डेटा की सुरक्षा के लिए मजबूत उपाय लागू करते हैं।

## ५. आपके अधिकार
आप हमारी सपोर्ट टीम से संपर्क करके अपनी जानकारी तक पहुंच, सुधार या हटाने का अनुरोध कर सकते हैं।

## ६. संपर्क करें
- **ईमेल:** adarshpandey@rurboo.com
- **फ़ोन:** +91 8810220691
""";

const String _privacyPolicyEnglish = """
# Privacy Policy for Rurboo Driver App

**Last Updated: February 2026**

Welcome to Rurboo! This Privacy Policy explains how Rurboo ("we," "us," or "our") collects, uses, and protects your information when you use our Driver Application.

## 1. Information We Collect
- **Personal Information:** Name, phone number, email address, vehicle details, and government-issued ID for verification.
- **Location Data:** We collect precise location data to match you with nearby riders and track rides.
- **Transaction Data:** Details of trips, earnings, and payouts.

## 2. How We Use Your Information
- To provide ride-hailing services.
- To verify your identity and vehicle.
- To process payments and earnings.
- To enhance safety and security for both drivers and riders.

## 3. Sharing Your Information
We may share your information with:
- **Riders:** Your name, photo, vehicle details, and real-time location during a trip.
- **Service Providers:** Third-party vendors for payments, background checks, and cloud services.
- **Legal Authorities:** If required by law or to protect user safety.

## 4. Data Security
We implement robust security measures to protect your data.

## 5. Your Rights
You may request access to, correction of, or deletion of your personal data by contacting our support team.

## 6. Contact Us
- **Email:** adarshpandey@rurboo.com
- **Phone:** +91 8810220691
""";
