import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/theme/app_theme.dart';
import 'package:icu_connect/core/widgets/network_status_overlay.dart';
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
      title: AppTexts.appName,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return NetworkStatusOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
