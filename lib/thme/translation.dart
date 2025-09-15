import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeTranslations() async {
  final translations = {
    'en': {
      'settings': 'Settings',
      'languagePreferences': 'Language Preferences',
      'themeDarkLight': 'Theme (Dark/Light Mode)',
      'notificationSettings': 'Notification Settings',
      'privacySettings': 'Privacy Settings',
      'home': 'Home',
      'favorites': 'Favorites',
      'cart': 'Cart',
      'profile': 'Profile',
      'orders': 'Order & Shopping Info',
      'payment': 'Payment & Wallet',
      'helpSupport': 'Help & Support',
      'logout': 'Logout',
      'collections': 'Collections',
      'search': 'Search',
    },
    'ur': {
      'settings': 'ترتیبات',
      'languagePreferences': 'زبان کی ترجیحات',
      'themeDarkLight': 'تھیم (ڈارک/لائٹ موڈ)',
      'notificationSettings': 'اطلاعات کی ترتیبات',
      'privacySettings': 'رازداری کی ترتیبات',
      'home': 'ہوم',
      'favorites': 'پسندیدہ',
      'cart': 'کارٹ',
      'profile': 'پروفائل',
      'orders': 'آرڈر اور خریداری کی معلومات',
      'payment': 'ادائیگی اور والٹ',
      'helpSupport': 'مدد اور سپورٹ',
      'logout': 'لاگ آؤٹ',
      'collections': 'مجموعے',
      'search': 'تلاش',
    },
    'pa': {
      'settings': 'ਸੈਟਿੰਗਜ਼',
      'languagePreferences': 'ਭਾਸ਼ਾ ਦੀਆਂ ਤਰਜੀਹਾਂ',
      'themeDarkLight': 'ਥੀਮ (ਡਾਰਕ/ਲਾਈਟ ਮੋਡ)',
      'notificationSettings': 'ਸੂਚਨਾ ਸੈਟਿੰਗਜ਼',
      'privacySettings': 'ਪ੍ਰਾਈਵੇਸੀ ਸੈਟਿੰਗਜ਼',
      'home': 'ਹੋਮ',
      'favorites': 'ਪਸੰਦੀਦا',
      'cart': 'ਕਾਰਟ',
      'profile': 'ਪ੍ਰੋਫਾਈਲ',
      'orders': 'ਆਰਡਰ ਅਤੇ ਖਰੀਦਦਾਰੀ ਜਾਣਕਾਰੀ',
      'payment': 'ਭੁਗਤਾਨ ਅਤੇ ਵਾਲਿਟ',
      'helpSupport': 'ਮਦਦ ਅਤੇ ਸਹਾਇਤਾ',
      'logout': 'ਲੌਗਆਊਟ',
      'collections': 'ਸੰਗ੍ਰਹਿ',
      'search': 'ਖੋਜ',
    },
  };

  final firestore = FirebaseFirestore.instance;
  for (var lang in translations.keys) {
    await firestore.collection('translations').doc(lang).set(translations[lang]!);
  }
}