import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1A1F36); // Dark Blue from Login button/Header
  static const Color secondary = Color(0xFF6C6F80); // Greyish text color
  static const Color accent = Color(0xFF3B5998); // A lighter blue for accents if needed

  // Background Colors
  static const Color background = Color(0xFFF5F6FA); // Light greyish background
  static const Color surface = Colors.white;
  static const Color inputBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF8A8D9F);
  static const Color textInverse = Colors.white;

  // Border & Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFC4C6D0);

  // Overlays & Shadows
  static const Color overlay = Color(0x66000000);
  static const Color shadow = Color(0x1A1A1F36);

  // Status Colors (for Vitals/Labs)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Text-on-status colors
  static const Color onSuccess = Colors.white;
  static const Color onWarning = Color(0xFF1A1F36);
  static const Color onError = Colors.white;
  static const Color onInfo = Colors.white;
}
