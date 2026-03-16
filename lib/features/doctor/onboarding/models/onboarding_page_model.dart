import 'package:flutter/material.dart';

class OnboardingPageModel {
  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;

  Color get lightColor => accentColor.withAlpha(20);
  Color get softColor => accentColor.withAlpha(40);
  Color get midColor => accentColor.withAlpha(70);
}
