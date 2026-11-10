import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_formatters.dart';
import 'admission_details_inline_media.dart';
import 'admission_details_item_actions.dart';
import 'radiology_path_utils.dart';

class AdmissionDetailsRadiologyCard extends StatelessWidget {
  const AdmissionDetailsRadiologyCard({
    super.key,
    required this.image,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });

  final RadiologyImageModel image;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  static const _compactWidth = 260.0;
  static const _compactMediaHeight = 150.0;

  static bool _isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi');
  }

  @override
  Widget build(BuildContext context) {
    final path = cleanRadiologyStoragePath(image.imagePath);
    final mediaUrl = resolveStorageMediaUrl(path);
    final isVideo = _isVideo(path);
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: isVideo
                ? AdmissionDetailsInlineVideoPlayer(
                    url: mediaUrl,
                    height: mediaHeight,
                  )
                : AdmissionDetailsInlineImage(
                    url: mediaUrl,
                    title: image.title,
                    width: mediaWidth,
                    height: mediaHeight,
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
                      isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        image.title,
                        maxLines: compact ? 1 : null,
                        overflow: compact ? TextOverflow.ellipsis : null,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    AdmissionDetailsItemActions(
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ],
                ),
                if (image.report.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    image.report,
                    maxLines: compact ? 2 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  admissionDetailsFormatDateTime(image.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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
