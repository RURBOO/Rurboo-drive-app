import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../l10n/app_localizations.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsAndConditions),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Markdown(data: isHindi ? _termsHindi : _termsEnglish),
    );
  }
}

const String _termsHindi = """
# रूरबू ड्राइवर ऐप — नियम और शर्तें

**अंतिम अपडेट: फ़रवरी २०२६**

रूरबू ड्राइवर ऐप का उपयोग करके आप इन नियमों और शर्तों से सहमत होते हैं। कृपया इन्हें ध्यान से पढ़ें।

## १. नियमों की स्वीकृति
ड्राइवर के रूप में पंजीकरण करके आप इन शर्तों, हमारी गोपनीयता नीति और सभी लागू कानूनों का पालन करने के लिए सहमत होते हैं।

## २. ड्राइवर पात्रता
- आपके पास वैध ड्राइविंग लाइसेंस होना चाहिए।
- आपके पास पंजीकृत और बीमाकृत वाहन होना चाहिए।
- आपकी आयु कम से कम १८ वर्ष होनी चाहिए।
- आवश्यक बैकग्राउंड चेक पास करना होगा।

## ३. प्लेटफ़ॉर्म का उपयोग
- सुरक्षित और विश्वसनीय परिवहन सेवाएं प्रदान करें।
- यात्रियों के साथ सम्मानजनक व्यवहार करें।
- वाहन को सुरक्षित और साफ रखें।
- धोखाधड़ी के लिए ऐप का दुरुपयोग न करें।

## ४. कमीशन और शुल्क
**रूरबू प्रत्येक सवारी के कुल किराए पर २०% सेवा शुल्क लेता है।**

- यह २०% कमीशन आपकी कमाई से स्वतः कट जाता है।
- शेष ८०% आपकी शुद्ध कमाई है।
- भुगतान ऐप में परिभाषित शेड्यूल के अनुसार किया जाता है।

## ५. रद्दीकरण
- अत्यधिक रद्दीकरण से खाता निलंबित हो सकता है।

## ६. दायित्व
रूरबू एक तकनीकी प्लेटफ़ॉर्म है जो ड्राइवरों और यात्रियों को जोड़ता है। हम परिवहन वाहक नहीं हैं और ड्राइवरों को नियोजित नहीं करते।

## ७. समाप्ति
हम किसी भी समय इन शर्तों के उल्लंघन पर आपका खाता निलंबित या समाप्त करने का अधिकार रखते हैं।

## ८. संशोधन
हम समय-समय पर इन शर्तों को अपडेट कर सकते हैं।

## ९. शासी कानून
ये शर्तें भारत के कानूनों द्वारा नियंत्रित हैं।

## १०. संपर्क करें
- **ईमेल:** adarshpandey@rurboo.com
- **फ़ोन:** +91 8810220691
""";

const String _termsEnglish = """
# Terms and Conditions for Rurboo Driver App

**Last Updated: February 2026**

By using the Rurboo Driver App, you agree to these Terms and Conditions. Please read them carefully.

## 1. Acceptance of Terms
By registering as a driver, you agree to comply with these terms, our Privacy Policy, and all applicable laws and regulations.

## 2. Driver Eligibility
- You must hold a valid driver's license.
- You must have a registered and insured vehicle.
- You must be at least 18 years old.
- You must pass any required background checks.

## 3. Usage of the Platform
- Provide safe and reliable transportation services.
- Treat all riders with respect.
- Maintain your vehicle in a safe and clean condition.
- Do not misuse the app for fraudulent activities.

## 4. Commission and Fees
**Rurboo charges a standard service fee (commission) of 20% on the total fare for each ride.**

- This 20% commission is deducted automatically from your ride earnings.
- The remaining 80% is your net earning.
- Payouts are processed according to the payment schedule defined in the app.

## 5. Cancellations and No-Shows
- Excessive cancellations may lead to account suspension.

## 6. Liability
Rurboo is a technology platform connecting drivers and riders. We are not a transportation carrier and do not employ drivers.

## 7. Termination
We reserve the right to suspend or terminate your account at any time for violation of these terms.

## 8. Amendments
We may update these terms from time to time.

## 9. Governing Law
These terms are governed by the laws of India.

## 10. Contact Us
- **Email:** adarshpandey@rurboo.com
- **Phone:** +91 8810220691
""";
