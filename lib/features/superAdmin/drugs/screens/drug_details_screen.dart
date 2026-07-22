import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/network_exceptions.dart';
import '../cubit/drugs_cubit.dart';
import '../models/drug_model.dart';
import '../repository/drugs_repository.dart';
import 'drug_form_screen.dart';

class DrugDetailsScreen extends StatefulWidget {
  const DrugDetailsScreen({
    super.key,
    required this.drugId,
    this.initialDrug,
  });

  final int drugId;
  final DrugModel? initialDrug;

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen> {
  final _repo = const DrugsRepository();
  late DrugModel? _drug = widget.initialDrug;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drug = await _repo.fetchDrug(widget.drugId);
      if (!mounted) return;
      setState(() {
        _drug = drug;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred';
        _loading = false;
      });
    }
  }

  Future<void> _openEdit() async {
    final drug = _drug;
    if (drug == null) return;
    final cubit = context.read<DrugsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: DrugFormScreen(drug: drug),
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _archive() async {
    final drug = _drug;
    if (drug == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.archiveDrug),
        content: const Text(AppTexts.archiveDrugConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppTexts.archiveDrug),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<DrugsCubit>().archiveDrug(drug.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _restore() async {
    final drug = _drug;
    if (drug == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.restoreDrug),
        content: const Text(AppTexts.restoreDrugConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppTexts.restoreDrug),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<DrugsCubit>().restoreDrug(drug.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final drug = _drug;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          drug?.genericName.isNotEmpty == true
              ? drug!.genericName
              : AppTexts.drugDetails,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading && drug == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null && drug == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : drug == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          _HeaderCard(drug: drug),
                          const SizedBox(height: 12),
                          _StringListCard(
                            title: AppTexts.tradeNames,
                            items: drug.tradeNames,
                          ),
                          _StringListCard(
                            title: AppTexts.dosingGuidelines,
                            items: drug.dosingGuidelines,
                          ),
                          _StringListCard(
                            title: AppTexts.indications,
                            items: drug.indications,
                          ),
                          _StringListCard(
                            title: AppTexts.contraindications,
                            items: drug.contraindications,
                          ),
                          _StringListCard(
                            title: AppTexts.sideEffects,
                            items: drug.sideEffects,
                          ),
                          _StringListCard(
                            title: AppTexts.pregnancy,
                            items: drug.pregnancy,
                          ),
                          _TextCard(
                            title: AppTexts.renalDoseAdjustment,
                            value: drug.renalDoseAdjustment,
                          ),
                          _TextCard(
                            title: AppTexts.hepaticDoseAdjustment,
                            value: drug.hepaticDoseAdjustment,
                          ),
                          _TextCard(
                            title: AppTexts.notes,
                            value: drug.notes,
                          ),
                          const SizedBox(height: 8),
                          if (drug.isArchived)
                            FilledButton.icon(
                              onPressed: _restore,
                              icon: const Icon(Icons.restore_outlined),
                              label: const Text(AppTexts.restoreDrug),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            )
                          else ...[
                            FilledButton.icon(
                              onPressed: _openEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text(AppTexts.editDrug),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _archive,
                              icon: const Icon(Icons.archive_outlined),
                              label: const Text(AppTexts.archiveDrug),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.drug});

  final DrugModel drug;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            drug.genericName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: drug.isArchived
                    ? AppTexts.drugArchivedFilter
                    : drug.isActive
                        ? AppTexts.drugActive
                        : AppTexts.drugInactive,
                color: drug.isArchived
                    ? AppColors.error
                    : drug.isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
              ),
              if ((drug.createdBy?.displayName ?? '').isNotEmpty)
                _Chip(
                  label: 'Created by ${drug.createdBy!.displayName}',
                  color: AppColors.primary,
                ),
              if ((drug.updatedBy?.displayName ?? '').isNotEmpty)
                _Chip(
                  label: 'Updated by ${drug.updatedBy!.displayName}',
                  color: AppColors.accent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StringListCard extends StatelessWidget {
  const _StringListCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.4,
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
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
