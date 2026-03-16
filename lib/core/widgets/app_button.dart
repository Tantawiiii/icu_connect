import 'package:bounce/bounce.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A shared tappable button built with [Bounce] + [Container].
///
/// Shows a loading spinner in place of the label when [isLoading] is true.
/// Becomes non-interactive and visually dimmed when [onPressed] is null or
/// [isLoading] is true.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.color = AppColors.primary,
    this.textColor = Colors.white,
    this.width = double.infinity,
    this.height = 52.0,
    this.borderRadius = 30.0,
    this.leadingIcon,
    this.trailingIcon,
    this.fontSize = 15.0,
    this.letterSpacing = 0.5,
    this.fontWeight = FontWeight.bold,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  final Color color;
  final Color textColor;

  final double? width;
  final double height;
  final double borderRadius;

  /// Optional icon shown to the left of the label.
  final Widget? leadingIcon;

  /// Optional icon shown to the right of the label.
  final Widget? trailingIcon;

  final double fontSize;
  final double letterSpacing;
  final FontWeight fontWeight;

  bool get _interactive => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    return Bounce(
      onTap: _interactive ? () { onPressed?.call(); } : null,
      child: AnimatedOpacity(
        opacity: _interactive ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: _interactive
                ? [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leadingIcon != null) ...[
                        leadingIcon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          letterSpacing: letterSpacing,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        trailingIcon!,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
