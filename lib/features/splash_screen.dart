import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_images.dart';
import 'package:icu_connect/core/network/api_client.dart';
import 'package:icu_connect/core/network/api_constants.dart';
import 'package:icu_connect/core/network/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icu_connect/features/doctor/home/screens/main_screen.dart';
import 'package:icu_connect/features/superAdmin/home/screens/super_admin_home_screen.dart';
import 'package:icu_connect/features/superAdmin/login/cubit/admin_login_cubit.dart';
import 'package:icu_connect/features/superAdmin/login/models/admin_model.dart';
import 'package:icu_connect/features/superAdmin/login/repository/admin_auth_repository.dart';
import 'package:icu_connect/features/doctor/onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final target = await _resolveNextScreen();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => target,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  Future<Widget> _resolveNextScreen() async {
    final accessToken = await TokenStorage.instance.getAccessToken();
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    final storedRole = await TokenStorage.instance.getUserRole();

    debugPrint(
      '[Splash] access token exists: ${accessToken != null && accessToken.isNotEmpty}',
    );
    debugPrint(
      '[Splash] refresh token exists: ${refreshToken != null && refreshToken.isNotEmpty}',
    );
    if (accessToken != null && accessToken.isNotEmpty) {
      debugPrint('[Splash] access token: $accessToken');
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      debugPrint('[Splash] refresh token: $refreshToken');
    }

    if ((accessToken?.isNotEmpty ?? false) &&
        (refreshToken?.isNotEmpty ?? false)) {
      debugPrint('[Splash] trying refresh token...');
      final refreshed = await _tryRefreshToken(
        storedRole: storedRole,
        refreshToken: refreshToken!,
      );
      debugPrint('[Splash] refresh result: $refreshed');
      if (refreshed) {
        final role = ApiClient.roleFromStoredValue(storedRole);
        final home = await _resolveHomeByRole(role);
        if (home != null) return home;
      }
    }

    debugPrint('[Splash] navigate -> OnboardingScreen (no session)');
    return const OnboardingScreen();
  }

  Future<Widget?> _resolveHomeByRole(UserRole role) async {
    try {
      final profileResponse = await ApiClient.client(
        role,
      ).get<Map<String, dynamic>>(ApiConstants.authProfile);
      final data = profileResponse.data?['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      final userRole = (data['role'] as String?)?.toLowerCase();
      debugPrint('[Splash] profile role: $userRole');

      if (role == UserRole.admin) {
        debugPrint('[Splash] navigate -> SuperAdminHomeScreen');
        return BlocProvider(
          create: (_) => AdminLoginCubit(const AdminAuthRepository()),
          child: SuperAdminHomeScreen(admin: AdminModel.fromJson(data)),
        );
      }

      if (userRole == 'doctor') {
        debugPrint('[Splash] navigate -> MainScreen (doctor)');
        return const MainScreen();
      }

      debugPrint('[Splash] unknown hospital user role, default -> MainScreen');
      return const MainScreen();
    } catch (e) {
      debugPrint('[Splash] failed to fetch profile for routing: $e');
      return null;
    }
  }

  Future<bool> _tryRefreshToken({
    required String? storedRole,
    required String refreshToken,
  }) async {
    try {
      final role = ApiClient.roleFromStoredValue(storedRole);
      debugPrint('[Splash] refresh using role: ${role.name}');
      debugPrint(
        '[Splash] refresh url: ${role.baseUrl}${ApiConstants.refreshToken}',
      );

      final response = await Dio().post<Map<String, dynamic>>(
        '${role.baseUrl}${ApiConstants.refreshToken}',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['access_token'] as String?;
      final newRefreshToken = data?['refresh_token'] as String?;

      debugPrint(
        '[Splash] new access token exists: '
        '${newAccessToken != null && newAccessToken.isNotEmpty}',
      );
      debugPrint(
        '[Splash] new refresh token exists: '
        '${newRefreshToken != null && newRefreshToken.isNotEmpty}',
      );

      if (newAccessToken == null || newAccessToken.isEmpty) {
        debugPrint('[Splash] refresh failed: empty access token');
        return false;
      }

      await TokenStorage.instance.saveAccessToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await TokenStorage.instance.saveRefreshToken(newRefreshToken);
      }
      await TokenStorage.instance.saveUserRole(role.name);
      debugPrint('[Splash] refresh success and tokens saved');
      return true;
    } catch (e) {
      debugPrint('[Splash] refresh failed with error: $e');
      await TokenStorage.instance.clearAll();
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              Color(0xFF2A3050),
              AppColors.accent,
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundGlow(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_controller, _pulseController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.0),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(
                                  0.35 * _pulseAnimation.value / 1.15,
                                ),
                                blurRadius: 40 * _pulseAnimation.value,
                                spreadRadius: 4 * _pulseAnimation.value,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  AppImages.logoWithoutBack,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.local_hospital,
                                      size: 70,
                                      color: AppColors.primary,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'ICU Connect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Care, connected in real time',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 60,
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned(
          top: -80 - (20 * _pulseAnimation.value),
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.15),
            ),
          ),
        );
      },
    );
  }
}
