import 'package:ecommerceapp/screen/admin/adminscreen.dart';
import 'package:ecommerceapp/screen/splah.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'thme/notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyC1iNWbGLgT19BGEOYwMRRyb3zNICzAUns',
      storageBucket: 'ecommerce-464f6.firebasestorage.app',
      appId: '1:960660300016:android:170c2ac25f7744ed27a235',
      databaseURL: '',
      messagingSenderId: '',
      projectId: 'ecommerce-464f6',
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ecommerce App',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xffFF63A5), // Matches your app's pink accent
        colorScheme: const ColorScheme.light(
          primary: Color(0xffFF63A5),
          secondary: Colors.amber,
          surface: Colors.grey,
          onSurface: Colors.black87,
          error: Colors.red,
          onError: Colors.white,
          surfaceVariant: Color(0xffFFD0B6), // Matches your original container color
        ),
        cardColor: Colors.white, // Solid white for cards in light mode
        scaffoldBackgroundColor: Colors.grey[100], // Soft light background
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        dividerColor: Colors.grey,
        shadowColor: Colors.black26,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xffFF8AB7), // Softer pink for dark mode
        colorScheme: ColorScheme.dark(
          primary: const Color(0xffFF8AB7),
          secondary: Colors.amberAccent,
          surface: Colors.grey[900]!,
          onSurface: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          surfaceVariant: Colors.grey[800]!, // Darker variant for containers
        ),
        cardColor: Colors.grey[800], // Dark grey for cards in dark mode
        scaffoldBackgroundColor: Colors.grey[900], // Dark background
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        dividerColor: Colors.grey[700],
        shadowColor: Colors.black54,
      ),
      themeMode: themeNotifier.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(),
    );
  }
}