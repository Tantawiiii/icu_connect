import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_texts.dart';

/// Shared centered error state (icon + message + retry button) used across
/// list and detail screens when a fetch fails.
///
/// Consolidates what used to be many identical `_ErrorView` private widgets
/// duplicated across admin/list screens.
class ListErrorView extends StatelessWidget {
  const ListErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = AppTexts.retry,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
