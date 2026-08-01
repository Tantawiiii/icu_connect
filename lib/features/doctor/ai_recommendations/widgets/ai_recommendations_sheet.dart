import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../enums/ai_recommend_feature.dart';
import '../models/ai_recommendation.dart';
import '../repository/ai_recommendations_repository.dart';
import '../services/ai_apply_service.dart';

Future<void> showAdmissionAiRecommendationsSheet({
  required BuildContext context,
  required int admissionId,
  String? patientName,
  AiRecommendFeature initialFeature = AiRecommendFeature.diagnosis,
  VoidCallback? onApplied,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AiRecommendationsSheet(
      admissionId: admissionId,
      patientName: patientName,
      initialFeature: initialFeature,
      onApplied: onApplied,
    ),
  );
}


typedef AdmissionAiRecommendationsSheet = AiRecommendationsSheet;

class AiRecommendationsSheet extends StatefulWidget {
  const AiRecommendationsSheet({
    super.key,
    required this.admissionId,
    this.patientName,
    this.initialFeature = AiRecommendFeature.diagnosis,
    this.onApplied,
  });

  final int admissionId;
  final String? patientName;
  final AiRecommendFeature initialFeature;
  final VoidCallback? onApplied;

  @override
  State<AiRecommendationsSheet> createState() => _AiRecommendationsSheetState();
}

class _AiRecommendationsSheetState extends State<AiRecommendationsSheet>
    with TickerProviderStateMixin {
  final _repo = const AiRecommendationsRepository();
  final _applyService = AiApplyService();
  final _cache = <String, AiRecommendationResult>{};
  final _selected = <String>{};

  late AiRecommendFeature _feature;
  String _language = 'en';
  bool _loading = false;
  bool _refreshing = false;
  bool _applying = false;
  String? _error;
  AiRecommendationResult? _result;

  late final AnimationController _pulseCtrl;
  late final AnimationController _revealCtrl;

  @override
  void initState() {
    super.initState();
    _feature = widget.initialFeature;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  String _cacheKey(AiRecommendFeature feature, String language) =>
      '${feature.name}_$language';

  Future<void> _load({bool refresh = false}) async {
    final key = _cacheKey(_feature, _language);
    if (!refresh && _cache.containsKey(key)) {
      setState(() {
        _result = _cache[key];
        _error = null;
        _loading = false;
        _refreshing = false;
        _selected.clear();
      });
      _revealCtrl.forward(from: 0);
      return;
    }

    setState(() {
      _loading = true;
      _refreshing = refresh;
      _error = null;
      if (!refresh) _result = null;
      _selected.clear();
    });

    try {
      final result = await _repo.recommend(
        feature: _feature,
        admissionId: widget.admissionId,
        language: _language,
        refresh: refresh,
      );
      if (!mounted) return;
      _cache[key] = result;
      setState(() {
        _result = result;
        _loading = false;
        _refreshing = false;
      });
      _revealCtrl.forward(from: 0);
      HapticFeedback.lightImpact();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _refreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppTexts.aiLoadFailed;
        _loading = false;
        _refreshing = false;
      });
    }
  }

  void _selectFeature(AiRecommendFeature feature) {
    if (feature == _feature) return;
    HapticFeedback.selectionClick();
    setState(() => _feature = feature);
    _load();
  }

  void _setLanguage(String language) {
    if (language == _language) return;
    HapticFeedback.selectionClick();
    setState(() => _language = language);
    _load();
  }

  void _toggleItem(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  Future<void> _openApplySheet() async {
    if (_selected.isEmpty || _applying) return;

    final target = await showModalBottomSheet<AiApplyTarget>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final suggested = AiApplyService.defaultTargetFor(_feature);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppTexts.aiApplyToAdmission,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTexts.aiApplyPickDestination,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                for (final t in AiApplyTarget.values) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      t == AiApplyTarget.timelineNote
                          ? Icons.forum_outlined
                          : t == AiApplyTarget.progressNote
                              ? Icons.notes_outlined
                              : Icons.checklist_rtl_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      t.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(t.hint),
                    trailing: t == suggested
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppTexts.aiSuggested,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => Navigator.pop(ctx, t),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (target == null || !mounted) return;
    await _applySelected(target);
  }

  Future<void> _applySelected(AiApplyTarget target) async {
    setState(() => _applying = true);
    try {
      await _applyService.apply(
        admissionId: widget.admissionId,
        feature: _feature,
        target: target,
        items: _selected.toList(),
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _selected.clear());
      widget.onApplied?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTexts.aiAppliedSuccess(target.label)),
          backgroundColor: AppColors.success,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppTexts.aiApplyFailed),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.94;
    final name = widget.patientName?.trim();

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1F36), Color(0xFF3D4A73)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppTexts.aiRecommendationsTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name == null || name.isEmpty
                            ? AppTexts.aiRecommendationsSubtitle
                            : 'For $name · ICU decision support',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppTexts.aiRefresh,
                  onPressed: _loading ? null : () => _load(refresh: true),
                  icon: AnimatedRotation(
                    turns: _refreshing ? 1 : 0,
                    duration: const Duration(milliseconds: 700),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: _loading
                          ? AppColors.textSecondary.withValues(alpha: 0.4)
                          : AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                // Expanded(
                //   child: _LanguageToggle(
                //     language: _language,
                //     enabled: !_loading,
                //     onChanged: _setLanguage,
                //   ),
                // ),
                // const SizedBox(width: 10),
                _ConfidencePill(confidence: _result?.recommendation.confidence),
              ],
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: AiRecommendFeature.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final feature = AiRecommendFeature.values[index];
                return _FeatureChip(
                  feature: feature,
                  selected: feature == _feature,
                  onTap: () => _selectFeature(feature),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _feature.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _buildBody(),
            ),
          ),
          if (_selected.isNotEmpty)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppTexts.aiSelectedCount(_selected.length),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _applying
                          ? null
                          : () => setState(_selected.clear),
                      child: Text(AppTexts.aiClearSelection),
                    ),
                    const SizedBox(width: 6),
                    AppButton(
                      label: _applying
                          ? AppTexts.aiApplying
                          : AppTexts.aiApplySelected,
                      onPressed: _applying ? null : _openApplySheet,
                      width: 110,
                      height: 42,
                      fontSize: 13,
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        AppTexts.aiDisclaimer,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _result == null) {
      return _AiLoadingState(
        key: ValueKey('loading_${_feature.name}'),
        pulse: _pulseCtrl,
        refreshing: _refreshing,
        feature: _feature,
      );
    }

    if (_error != null && _result == null) {
      return _AiErrorState(
        key: ValueKey('error_${_feature.name}'),
        message: _error!,
        onRetry: () => _load(),
      );
    }

    final result = _result;
    if (result == null) {
      return const Center(
        key: ValueKey('empty'),
        child: Text(
          AppTexts.aiEmptyFeature,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Stack(
      key: ValueKey('result_${_feature.name}_$_language'),
      children: [
        FadeTransition(
          opacity: CurvedAnimation(
            parent: _revealCtrl,
            curve: Curves.easeOut,
          ),
          child: _AiResultView(
            result: result,
            language: _language,
            selected: _selected,
            onToggle: _toggleItem,
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.background.withValues(alpha: 0.55),
              child: Center(
                child: _AiLoadingState(
                  pulse: _pulseCtrl,
                  refreshing: true,
                  feature: _feature,
                  compact: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.language,
    required this.enabled,
    required this.onChanged,
  });

  final String language;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _langBtn('EN', 'en'),
          _langBtn('AR', 'ar'),
        ],
      ),
    );
  }

  Widget _langBtn(String label, String code) {
    final selected = language == code;
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: enabled ? () => onChanged(code) : null,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  const _ConfidencePill({required this.confidence});

  final AiConfidence? confidence;

  @override
  Widget build(BuildContext context) {
    final c = confidence ?? AiConfidence.unknown;
    final (Color bg, Color fg) = switch (c) {
      AiConfidence.high => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      AiConfidence.medium => (const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      AiConfidence.low => (const Color(0xFFFFEBEE), const Color(0xFFC62828)),
      AiConfidence.unknown => (
          const Color(0xFFF2F3F5),
          AppColors.textSecondary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            '${AppTexts.aiConfidence}: ${c.label}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  final AiRecommendFeature feature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 118,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.border.withValues(alpha: 0.9),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  feature.icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.primary,
                ),
                const Spacer(),
                Text(
                  feature.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiLoadingState extends StatelessWidget {
  const _AiLoadingState({
    super.key,
    required this.pulse,
    required this.feature,
    this.refreshing = false,
    this.compact = false,
  });

  final Animation<double> pulse;
  final AiRecommendFeature feature;
  final bool refreshing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        return Padding(
          padding: EdgeInsets.all(compact ? 16 : 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 0.94 + (t * 0.08),
                child: Container(
                  width: compact ? 56 : 72,
                  height: compact ? 56 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08 + t * 0.08),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: compact ? 26 : 32,
                    color: AppColors.primary.withValues(alpha: 0.75 + t * 0.25),
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 18),
              Text(
                refreshing ? AppTexts.aiRefreshing : AppTexts.aiAnalyzing,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                feature.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AiErrorState extends StatelessWidget {
  const _AiErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final notConfigured = message.toLowerCase().contains('not_configured') ||
        message.toLowerCase().contains('not configured') ||
        message.toLowerCase().contains('ai_api_key');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notConfigured
                  ? Icons.settings_suggest_outlined
                  : Icons.error_outline,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              notConfigured ? AppTexts.aiNotConfigured : message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 160,
              child: AppButton(label: AppTexts.retry, onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiResultView extends StatelessWidget {
  const _AiResultView({
    required this.result,
    required this.language,
    required this.selected,
    required this.onToggle,
  });

  final AiRecommendationResult result;
  final String language;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final rec = result.recommendation;
    final isRtl = language == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          _SummaryCard(summary: rec.summary),
          const SizedBox(height: 10),
          Text(
            AppTexts.aiSelectToApplyHint,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.95),
            ),
          ),
          if (rec.safetyFlags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _BulletSection(
              title: AppTexts.aiSafetyFlags,
              items: rec.safetyFlags,
              icon: Icons.warning_amber_rounded,
              accent: const Color(0xFFC62828),
              background: const Color(0xFFFFEBEE),
              selectable: true,
              selected: selected,
              onToggle: onToggle,
            ),
          ],
          if (rec.priorityConcerns.isNotEmpty) ...[
            const SizedBox(height: 12),
            _BulletSection(
              title: AppTexts.aiPriorityConcerns,
              items: rec.priorityConcerns,
              icon: Icons.priority_high_rounded,
              accent: const Color(0xFFE65100),
              background: const Color(0xFFFFF3E0),
              selectable: true,
              selected: selected,
              onToggle: onToggle,
            ),
          ],
          if (rec.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _BulletSection(
              title: AppTexts.aiRecommendations,
              items: rec.recommendations,
              icon: Icons.lightbulb_outline,
              accent: const Color(0xFF2E7D32),
              background: const Color(0xFFE8F5E9),
              selectable: true,
              selected: selected,
              onToggle: onToggle,
            ),
          ],
          if (rec.missingData.isNotEmpty) ...[
            const SizedBox(height: 12),
            _BulletSection(
              title: AppTexts.aiMissingData,
              items: rec.missingData,
              icon: Icons.playlist_add_check_outlined,
              accent: const Color(0xFF455A64),
              background: const Color(0xFFECEFF1),
              selectable: true,
              selected: selected,
              onToggle: onToggle,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            AppTexts.aiCachedHint,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F36), Color(0xFF2C3555)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  AppTexts.aiSummary,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary.isEmpty ? '—' : summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.accent,
    required this.background,
    required this.selectable,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color accent;
  final Color background;
  final bool selectable;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final isOn = selected.contains(item);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: isOn
                    ? accent.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: selectable ? () => onToggle(item) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectable)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              isOn
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 20,
                              color: isOn ? accent : AppColors.textSecondary,
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(top: 6, left: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
