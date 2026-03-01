import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  bool _isLanguageSelected = false;

  Locale get currentLocale => _currentLocale;
  bool get isLanguageSelected => _isLanguageSelected;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('language_code');
    _isLanguageSelected = prefs.getBool('is_language_selected') ?? false;
    
    if (langCode != null) {
      _currentLocale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> changeLanguage(Locale newLocale) async {
    _currentLocale = newLocale;
    _isLanguageSelected = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
    await prefs.setBool('is_language_selected', true);
  }
}
