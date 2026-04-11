import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_formatters.dart';
import 'admission_details_inline_media.dart';
import 'radiology_path_utils.dart';

class AdmissionDetailsRadiologyCard extends StatelessWidget {
  const AdmissionDetailsRadiologyCard({
    super.key,
    required this.image,
    required this.onDelete,
  });

  final RadiologyImageModel image;
  final VoidCallback onDelete;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: isVideo
                ? AdmissionDetailsInlineVideoPlayer(url: mediaUrl)
                : AdmissionDetailsInlineImage(url: mediaUrl, title: image.title),
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
                    Flexible(
                      child: Text(
                        image.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (image.report.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    image.report,
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
