import 'package:flutter/material.dart';

import '../../../../core/constants/app_texts.dart';
import '../../../../core/utils/app_preferences.dart';
import '../../../../core/widgets/app_button.dart';
import '../data/onboarding_data.dart';
import '../models/onboarding_page_model.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = OnboardingData.pages;
  static const _animDuration = Duration(milliseconds: 400);
  static const _animCurve = Curves.easeInOutCubic;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: _animDuration, curve: _animCurve);
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await AppPreferences.setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip row ───────────────────────────────────────────────────
            _SkipRow(isLast: isLast, onSkip: _skip, color: page.accentColor),

            // ── Page view ──────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
              ),
            ),

            // ── Bottom navigation ──────────────────────────────────────────
            _BottomNav(
              currentPage: _currentPage,
              totalPages: _pages.length,
              isLast: isLast,
              accentColor: page.accentColor,
              onNext: _next,
              onSkip: _skip,
            ),
          ],
        ),
      ),
    );
  }
}


class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Illustration ───────────────────────────────────────────────────
        Expanded(
          flex: 5,
          child: _Illustration(page: page),
        ),

        // ── Text content ───────────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: page.lightColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: page.midColor),
                  ),
                  child: Text(
                    page.subtitle,
                    style: TextStyle(
                      color: page.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1F36),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  page.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C6F80),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class _Illustration extends StatelessWidget {
  const _Illustration({required this.page});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: page.lightColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.softColor,
            ),
          ),

          // Middle ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.midColor,
            ),
          ),

          // Icon circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.accentColor,
              boxShadow: [
                BoxShadow(
                  color: page.accentColor.withAlpha(80),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              color: Colors.white,
              size: 52,
            ),
          ),
          Positioned(
            top: 30,
            right: 50,
            child: _FloatingDot(color: page.midColor, size: 14),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: _FloatingDot(color: page.softColor, size: 20),
          ),
          Positioned(
            top: 60,
            left: 60,
            child: _FloatingDot(color: page.midColor, size: 10),
          ),
          Positioned(
            bottom: 30,
            right: 60,
            child: _FloatingDot(color: page.softColor, size: 16),
          ),

          // Medical cross accent
          Positioned(
            top: 28,
            left: 50,
            child: Icon(
              Icons.add,
              color: page.accentColor.withAlpha(60),
              size: 22,
            ),
          ),
          Positioned(
            bottom: 28,
            right: 40,
            child: Icon(
              Icons.add,
              color: page.accentColor.withAlpha(50),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingDot extends StatelessWidget {
  const _FloatingDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _SkipRow extends StatelessWidget {
  const _SkipRow({
    required this.isLast,
    required this.onSkip,
    required this.color,
  });

  final bool isLast;
  final VoidCallback onSkip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: isLast ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: isLast ? null : onSkip,
              child: Text(
                AppTexts.skip,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation (dots + buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentPage,
    required this.totalPages,
    required this.isLast,
    required this.accentColor,
    required this.onNext,
    required this.onSkip,
  });

  final int currentPage;
  final int totalPages;
  final bool isLast;
  final Color accentColor;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (i) => _Dot(isActive: i == currentPage, color: accentColor),
            ),
          ),
          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: isLast
                ? AppButton(
                    key: const ValueKey('get_started'),
                    label: AppTexts.getStarted,
                    onPressed: onNext,
                    color: accentColor,
                    fontSize: 16,
                    trailingIcon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                : Row(
                    key: const ValueKey('next'),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currentPage + 1} of $totalPages',
                        style: const TextStyle(
                          color: Color(0xFF8A8D9F),
                          fontSize: 13,
                        ),
                      ),

                      GestureDetector(
                        onTap: onNext,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withAlpha(80),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.isActive, required this.color});

  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? color : color.withAlpha(50),
      ),
    );
  }
}
