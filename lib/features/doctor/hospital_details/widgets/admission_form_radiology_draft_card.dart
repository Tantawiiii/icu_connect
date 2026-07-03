import 'dart:io';

import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';

import 'admission_details_item_actions.dart';
import 'radiology_path_utils.dart';

class AdmissionFormRadiologyDraft {
  AdmissionFormRadiologyDraft({
    required this.id,
    required this.title,
    required this.report,
    this.localMediaPaths = const [],
  });

  final int id;
  final String title;
  final String report;
  final List<String> localMediaPaths;
}

class AdmissionFormRadiologyDraftCard extends StatelessWidget {
  const AdmissionFormRadiologyDraftCard({
    super.key,
    required this.draft,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });

  final AdmissionFormRadiologyDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  static const _compactWidth = 260.0;
  static const _compactMediaHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    final path = draft.localMediaPaths.isNotEmpty
        ? draft.localMediaPaths.first
        : null;
    final isVideo = path != null && isRadiologyPathVideo(path);
    final mediaHeight = compact ? _compactMediaHeight : 200.0;
    final mediaWidth = compact ? _compactWidth : double.infinity;

    return Container(
      width: compact ? _compactWidth : null,
      margin: EdgeInsets.only(
        bottom: compact ? 0 : 10,
        right: compact ? 12 : 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (path != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                width: mediaWidth,
                height: mediaHeight,
                child: isVideo
                    ? ColoredBox(
                        color: AppColors.background,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              size: 40,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              path.split(Platform.pathSeparator).last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Image.file(
                        File(path),
                        width: mediaWidth,
                        height: mediaHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: AppColors.background,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      path != null && isVideo
                          ? Icons.videocam_rounded
                          : Icons.image_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        draft.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    AdmissionDetailsItemActions(
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ],
                ),
                if (draft.report.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    draft.report,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (draft.localMediaPaths.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: draft.localMediaPaths.skip(1).map((p) {
                      return Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          p.split(Platform.pathSeparator).last,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
