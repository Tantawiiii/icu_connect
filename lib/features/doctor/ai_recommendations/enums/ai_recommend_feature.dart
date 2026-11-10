import 'package:flutter/material.dart';

import 'package:icu_connect/core/network/api_constants.dart';

enum AiRecommendFeature {
  medication,
  labs,
  vitals,
  treatmentPlan,
  imaging,
  diagnosis,
  discharge;

  String get apiKey => switch (this) {
    AiRecommendFeature.medication => 'medication',
    AiRecommendFeature.labs => 'labs',
    AiRecommendFeature.vitals => 'vitals',
    AiRecommendFeature.treatmentPlan => 'treatment_plan',
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
    AiRecommendFeature.treatmentPlan => 'Treatment plan',
    AiRecommendFeature.imaging => 'Imaging',
    AiRecommendFeature.diagnosis => 'Diagnosis',
    AiRecommendFeature.discharge => 'Discharge',
  };

  String get subtitle => switch (this) {
    AiRecommendFeature.medication =>
      'Interactions, duplication, renal/hepatic dosing',
    AiRecommendFeature.labs => 'Trends, critical values, organ dysfunction',
    AiRecommendFeature.vitals => 'Hemodynamic & respiratory stability',
    AiRecommendFeature.treatmentPlan => 'Goals, alignment, care gaps',
    AiRecommendFeature.imaging => 'Radiology, echo & ultrasound review',
    AiRecommendFeature.diagnosis => 'Working impression from available data',
    AiRecommendFeature.discharge => 'Readiness, handoff & documentation',
  };

  IconData get icon => switch (this) {
    AiRecommendFeature.medication => Icons.medication_outlined,
    AiRecommendFeature.labs => Icons.science_outlined,
    AiRecommendFeature.vitals => Icons.monitor_heart_outlined,
    AiRecommendFeature.treatmentPlan => Icons.checklist_rtl_outlined,
    AiRecommendFeature.imaging => Icons.image_search_outlined,
    AiRecommendFeature.diagnosis => Icons.psychology_alt_outlined,
    AiRecommendFeature.discharge => Icons.logout_outlined,
  };
}
