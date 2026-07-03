import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkStatusOverlay extends StatefulWidget {
  const NetworkStatusOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkStatusOverlay> createState() => _NetworkStatusOverlayState();
}

class _NetworkStatusOverlayState extends State<NetworkStatusOverlay>
    with SingleTickerProviderStateMixin {
  final InternetConnection _internetConnection = InternetConnection();

  StreamSubscription<InternetStatus>? _subscription;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _disconnectDebounce;
  Timer? _resumeRecheckDebounce;

  bool _isConnected = true;
  bool _isInitialized = false;
  bool _isChecking = false;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _lifecycleListener = AppLifecycleListener(
      onPause: _stopListening,
      onResume: _onAppResumed,
    );

    _startListening();
    _checkInitialConnection();
  }

  void _startListening() {
    _subscription?.cancel();
    _subscription = _internetConnection.onStatusChange.listen(_onStatusChanged);
  }

  void _stopListening() {
    _disconnectDebounce?.cancel();
    _disconnectDebounce = null;
    _subscription?.cancel();
    _subscription = null;
  }

  void _onAppResumed() {
    _resumeRecheckDebounce?.cancel();
    _resumeRecheckDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _startListening();
      _verifyConnection(maxAttempts: 5);
    });
  }

  void _onStatusChanged(InternetStatus status) {
    if (!_isInitialized) return;

    if (status == InternetStatus.connected) {
      _disconnectDebounce?.cancel();
      _disconnectDebounce = null;
      _verifyConnection(maxAttempts: 2, preferConnected: true);
      return;
    }

    _disconnectDebounce?.cancel();
    _disconnectDebounce = Timer(const Duration(milliseconds: 1200), () {
      _verifyConnection(maxAttempts: 3);
    });
  }

  Future<bool> _resolveConnectionStatus({int maxAttempts = 3}) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (await _internetConnection.hasInternetAccess) {
        return true;
      }

      if (attempt < maxAttempts - 1) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    return false;
  }

  Future<void> _verifyConnection({
    int maxAttempts = 3,
    bool preferConnected = false,
  }) async {
    final hasInternet = await _resolveConnectionStatus(maxAttempts: maxAttempts);
    if (!mounted) return;

    if (hasInternet) {
      if (!_isConnected) {
        setState(() => _isConnected = true);
      }
      return;
    }

    if (preferConnected) return;

    setState(() => _isConnected = false);
  }

  Future<void> _checkInitialConnection() async {
    final hasInternet = await _resolveConnectionStatus(maxAttempts: 4);

    if (mounted) {
      setState(() {
        _isConnected = hasInternet;
        _isInitialized = true;
      });
    }
  }

  Future<void> _checkConnectionManually() async {
    if (!mounted) return;
    setState(() => _isChecking = true);

    final hasInternet = await _resolveConnectionStatus(maxAttempts: 5);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isConnected = hasInternet;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _disconnectDebounce?.cancel();
    _resumeRecheckDebounce?.cancel();
    _subscription?.cancel();
    _lifecycleListener.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: !_isInitialized || _isConnected
              ? const SizedBox.shrink(key: ValueKey('connected'))
              : _buildFullScreenDisconnectUI(context),
        ),
      ],
    );
  }

  Widget _buildFullScreenDisconnectUI(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      key: const ValueKey('disconnected'),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorScheme.surface,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        color: colorScheme.error,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Text(
                'Whoops!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'No internet connection was found. Please check your network settings and try again.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkConnectionManually,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isChecking
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: _isChecking ? 0 : 8,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                  ),
                  child: _isChecking
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: isDark ? Colors.white70 : Colors.black54,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
