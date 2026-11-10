import 'dart:io';

import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';

/// Photo/video pickers plus a chip list of locally-selected files, used by
/// the "Add Radiology Record" form.
class AdmissionRadiologyMediaPicker extends StatelessWidget {
  const AdmissionRadiologyMediaPicker({
    super.key,
    required this.localPaths,
    required this.saving,
    required this.onPickImages,
    required this.onPickVideo,
    required this.onRemove,
  });

  final List<String> localPaths;
  final bool saving;
  final VoidCallback onPickImages;
  final VoidCallback onPickVideo;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images or video',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: saving ? null : onPickImages,
              icon: const Icon(
                Icons.photo_library_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              label: const Text('Photos'),
            ),
            TextButton.icon(
              onPressed: saving ? null : onPickVideo,
              icon: const Icon(
                Icons.video_library_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              label: const Text('Video'),
            ),
          ],
        ),
        if (localPaths.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: localPaths.map((path) {
                final name = path.split(Platform.pathSeparator).last;
                return InputChip(
                  label: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: saving ? null : () => onRemove(path),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
