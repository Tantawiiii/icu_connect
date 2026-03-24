import 'package:flutter/material.dart';
import 'package:icu_connect/core/theme/app_theme.dart';
import 'features/splash_screen.dart';

void main() {
  runApp(const ICUConnectApp());
}

class ICUConnectApp extends StatelessWidget {
  const ICUConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ICU Connect',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
