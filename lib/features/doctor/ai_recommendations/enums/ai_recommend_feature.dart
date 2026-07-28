import 'package:flutter/material.dart';

import 'package:icu_connect/core/network/api_constants.dart';

enum AiRecommendFeature {
  medication,
  labs,
  vitals,
  progressNotes,
  consultations,
  treatmentPlan,
  microbiology,
  imaging,
  diagnosis,
  discharge;

  String get apiKey => switch (this) {
        AiRecommendFeature.medication => 'medication',
        AiRecommendFeature.labs => 'labs',
        AiRecommendFeature.vitals => 'vitals',
        AiRecommendFeature.progressNotes => 'progress_notes',
        AiRecommendFeature.consultations => 'consultations',
        AiRecommendFeature.treatmentPlan => 'treatment_plan',
        AiRecommendFeature.microbiology => 'microbiology',
        AiRecommendFeature.imaging => 'imaging',
        AiRecommendFeature.diagnosis => 'diagnosis',
        AiRecommendFeature.discharge => 'discharge',
      };

  /// Absolute shared URL: `/api/v1/ai/recommend/{feature}` (not under /hospital).
  String get path => ApiConstants.aiRecommend(apiKey);

  String get label => switch (this) {
        AiRecommendFeature.medication => 'Medications',
        AiRecommendFeature.labs => 'Labs',
        AiRecommendFeature.vitals => 'Vitals',
        AiRecommendFeature.progressNotes => 'Progress notes',
        AiRecommendFeature.consultations => 'Consultations',
        AiRecommendFeature.treatmentPlan => 'Treatment plan',
        AiRecommendFeature.microbiology => 'Microbiology',
        AiRecommendFeature.imaging => 'Imaging',
        AiRecommendFeature.diagnosis => 'Diagnosis',
        AiRecommendFeature.discharge => 'Discharge',
      };

  String get subtitle => switch (this) {
        AiRecommendFeature.medication =>
          'Interactions, duplication, renal/hepatic dosing',
        AiRecommendFeature.labs => 'Trends, critical values, organ dysfunction',
        AiRecommendFeature.vitals => 'Hemodynamic & respiratory stability',
        AiRecommendFeature.progressNotes => 'Course review & documentation gaps',
        AiRecommendFeature.consultations => 'Specialty input & pending actions',
        AiRecommendFeature.treatmentPlan => 'Goals, alignment, care gaps',
        AiRecommendFeature.microbiology => 'Cultures & antimicrobial stewardship',
        AiRecommendFeature.imaging => 'Radiology, echo & ultrasound review',
        AiRecommendFeature.diagnosis => 'Working impression from available data',
        AiRecommendFeature.discharge => 'Readiness, handoff & documentation',
      };

  IconData get icon => switch (this) {
        AiRecommendFeature.medication => Icons.medication_outlined,
        AiRecommendFeature.labs => Icons.science_outlined,
        AiRecommendFeature.vitals => Icons.monitor_heart_outlined,
        AiRecommendFeature.progressNotes => Icons.notes_outlined,
        AiRecommendFeature.consultations => Icons.groups_outlined,
        AiRecommendFeature.treatmentPlan => Icons.checklist_rtl_outlined,
        AiRecommendFeature.microbiology => Icons.biotech_outlined,
        AiRecommendFeature.imaging => Icons.image_search_outlined,
        AiRecommendFeature.diagnosis => Icons.psychology_alt_outlined,
        AiRecommendFeature.discharge => Icons.logout_outlined,
      };
}
