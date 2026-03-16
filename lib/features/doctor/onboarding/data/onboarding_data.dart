import 'package:flutter/material.dart';

import '../models/onboarding_page_model.dart';

class OnboardingData {
  OnboardingData._();

  static const List<OnboardingPageModel> pages = [
    // ── Screen 1 – Introduction ───────────────────────────────────────────
    OnboardingPageModel(
      title: 'Welcome to\nICU Connect',
      subtitle: 'Smarter ICU handovers for safer patient care.',
      description:
          'Organize, share, and track critical patient updates in one place.',
      icon: Icons.health_and_safety_outlined,
      accentColor: Color(0xFF1A1F36),
    ),

    // ── Screen 2 – Easy Handover ──────────────────────────────────────────
    OnboardingPageModel(
      title: 'Seamless ICU\nHandover',
      subtitle: 'Transfer patient cases with clarity and accuracy.',
      description:
          'Quickly document and transfer patient cases between doctors with clarity and accuracy.',
      icon: Icons.compare_arrows_rounded,
      accentColor: Color(0xFF1565C0),
    ),

    // ── Screen 3 – Stay Updated ───────────────────────────────────────────
    OnboardingPageModel(
      title: 'Real-Time Patient\nUpdates',
      subtitle: 'Stay informed about every change.',
      description:
          'Stay informed about every change in your patients\' condition anytime, anywhere.',
      icon: Icons.notifications_active_outlined,
      accentColor: Color(0xFF00695C),
    ),

    // ── Screen 4 – Structured Cases ───────────────────────────────────────
    OnboardingPageModel(
      title: 'Structured Case\nSummaries',
      subtitle: 'Everything in a clear standardized format.',
      description:
          'Record vitals, investigations, treatment plans, and notes in a clear standardized format.',
      icon: Icons.article_outlined,
      accentColor: Color(0xFF4527A0),
    ),

    // ── Screen 5 – Team Collaboration ─────────────────────────────────────
    OnboardingPageModel(
      title: 'Better ICU Team\nCommunication',
      subtitle: 'Keep your entire ICU team aligned.',
      description:
          'Keep your entire ICU team aligned and reduce missed information during shifts.',
      icon: Icons.groups_outlined,
      accentColor: Color(0xFF00695C),
    ),
  ];
}
