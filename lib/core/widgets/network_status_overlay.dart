import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkStatusOverlay extends StatefulWidget {
  final Widget child;

  const NetworkStatusOverlay({super.key, required this.child});

  @override
  State<NetworkStatusOverlay> createState() => _NetworkStatusOverlayState();
}

class _NetworkStatusOverlayState extends State<NetworkStatusOverlay>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<InternetStatus> _subscription;
  bool _isConnected = true;
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

    _subscription = InternetConnection().onStatusChange.listen((status) {
      final isConnectedNow = status == InternetStatus.connected;
      if (_isConnected != isConnectedNow) {
        if (mounted) {
          setState(() {
            _isConnected = isConnectedNow;
          });
        }
      }
    });

    // Initial check
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final hasInternet = await InternetConnection().hasInternetAccess;
    if (mounted) {
      setState(() {
        _isConnected = hasInternet;
      });
    }
  }

  Future<void> _checkConnectionManually() async {
    if (!mounted) return;
    setState(() {
      _isChecking = true;
    });
    
    final hasInternet = await InternetConnection().hasInternetAccess;
    await Future.delayed(const Duration(milliseconds: 800)); // Smooth UX delay
    
    if (mounted) {
      setState(() {
        _isConnected = hasInternet;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The rest of the app
        widget.child,
        
        // Full screen interactive overlay
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
          child: _isConnected
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
                "Whoops!",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "No internet connection was found. Please check your network settings and try again.",
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
                    backgroundColor: _isChecking ? colorScheme.surfaceContainerHighest : colorScheme.primary,
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
                          "Try Again",
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
