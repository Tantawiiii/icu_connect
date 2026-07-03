import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../enums/admission_activity_subject_type.dart';
import '../models/admission_activity.dart';
import '../utils/admission_activity_formatter.dart';
import 'admission_details_empty_hint.dart';
import 'admission_details_formatters.dart';
import 'admission_details_section_container.dart';

class AdmissionDetailsActivitySection extends StatelessWidget {
  const AdmissionDetailsActivitySection({
    super.key,
    required this.activitiesFuture,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onRetry,
    this.showSectionTitle = true,
  });

  final Future<List<AdmissionActivity>> activitiesFuture;
  final AdmissionActivitySubjectType? selectedFilter;
  final ValueChanged<AdmissionActivitySubjectType?> onFilterChanged;
  final VoidCallback onRetry;
  final bool showSectionTitle;

  static const _filters = AdmissionActivitySubjectType.values;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _FilterChip(
                  label: AppTexts.activityFilterAll,
                  selected: selectedFilter == null,
                  onSelected: () => onFilterChanged(null),
                );
              }
              final filter = _filters[index - 1];
              return _FilterChip(
                label: filter.label,
                selected: selectedFilter == filter,
                onSelected: () => onFilterChanged(filter),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AdmissionActivity>>(
          future: activitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(
                    AppTexts.activityLoadFailed,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: AppTexts.retry,
                    height: 40,
                    width: 140,
                    onPressed: onRetry,
                  ),
                ],
              );
            }

            final activities = snapshot.data ?? const [];
            if (activities.isEmpty) {
              return const AdmissionDetailsEmptyHint(AppTexts.noActivityYet);
            }

            return Column(
              children: activities
                  .map((activity) => _ActivityTile(activity: activity))
                  .toList(),
            );
          },
        ),
      ],
    );

    if (!showSectionTitle) return content;

    return AdmissionDetailsSectionContainer(
      title: AppTexts.activityHistorySection,
      child: content,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
      side: const BorderSide(color: AppColors.border),
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final AdmissionActivity activity;

  IconData _iconForType(AdmissionActivitySubjectType? type) {
    switch (type) {
      case AdmissionActivitySubjectType.admission:
        return Icons.local_hospital_outlined;
      case AdmissionActivitySubjectType.patient:
        return Icons.person_outline;
      case AdmissionActivitySubjectType.clinicalNote:
        return Icons.note_alt_outlined;
      case AdmissionActivitySubjectType.radiologyImage:
        return Icons.image_outlined;
      case AdmissionActivitySubjectType.treatmentPlan:
        return Icons.medical_information_outlined;
      case AdmissionActivitySubjectType.vital:
        return Icons.monitor_heart_outlined;
      case AdmissionActivitySubjectType.lab:
        return Icons.science_outlined;
      case AdmissionActivitySubjectType.medication:
        return Icons.medication_outlined;
      case AdmissionActivitySubjectType.echo:
        return Icons.favorite_outline;
      case AdmissionActivitySubjectType.ultrasound:
        return Icons.waves_outlined;
      case AdmissionActivitySubjectType.culture:
        return Icons.biotech_outlined;
      case null:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = activity.subjectTypeEnum;
    final changeLines = admissionActivityChangeLines(activity);
    final title = admissionActivityTitle(activity);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForType(type),
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (changeLines.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...changeLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ] else if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (activity.createdAt.isNotEmpty)
                  Text(
                    admissionDetailsFormatDateTime(activity.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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
