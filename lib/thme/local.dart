import 'package:flutter/material.dart';

class LocaleNotifier with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(String languageCode) {
    switch (languageCode) {
      case 'English':
        _locale = const Locale('en');
        break;
      case 'Urdu':
        _locale = const Locale('ur');
        break;
      case 'Punjabi':
        _locale = const Locale('pa');
        break;
      default:
        _locale = const Locale('en');
    }
    notifyListeners();
  }
}