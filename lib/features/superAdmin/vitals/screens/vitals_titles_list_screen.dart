import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../cubit/vitals_titles_cubit.dart';
import '../cubit/vitals_titles_state.dart';
import '../models/vital_title_model.dart';
import 'vital_title_form_screen.dart';

class VitalsTitlesListScreen extends StatelessWidget {
  const VitalsTitlesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VitalsTitlesCubit()..fetchVitalsTitles(),
      child: const _VitalsTitlesListView(),
    );
  }
}

class _VitalsTitlesListView extends StatelessWidget {
  const _VitalsTitlesListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.vitalsTitlesLabel,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () =>
                context.read<VitalsTitlesCubit>().fetchVitalsTitles(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.monitor_heart_outlined),
        label: const Text(AppTexts.addVitalTitle),
        onPressed: () => _openForm(context, vital: null),
      ),
      body: BlocConsumer<VitalsTitlesCubit, VitalsTitlesState>(
        listener: (context, state) {
          if (state is VitalsTitlesActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is VitalsTitlesActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VitalsTitlesLoading || state is VitalsTitlesInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is VitalsTitlesFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<VitalsTitlesCubit>().fetchVitalsTitles(),
            );
          }
          if (state is VitalsTitlesActionLoading) {
            return Stack(
              children: [
                _VitalsList(items: state.items),
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            );
          }
          if (state is VitalsTitlesLoaded) {
            return _VitalsList(items: state.items);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openForm(BuildContext context, {required VitalTitleModel? vital}) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => VitalTitleFormScreen(vital: vital),
        ))
        .then((_) {
      if (context.mounted) {
        context.read<VitalsTitlesCubit>().fetchVitalsTitles();
      }
    });
  }
}

class _VitalsList extends StatelessWidget {
  const _VitalsList({required this.items});

  final List<VitalTitleModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_heart_outlined,
                size: 56, color: AppColors.secondary),
            SizedBox(height: 12),
            Text('No vitals titles found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<VitalsTitlesCubit>().fetchVitalsTitles(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _VitalCard(vital: items[index]),
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({required this.vital});

  final VitalTitleModel vital;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.monitor_heart_outlined,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vital.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (vital.unit.isNotEmpty) ...[
                        Text(
                          vital.unit,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'Normal: ${vital.normalRangeMin} – ${vital.normalRangeMax}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.accent, size: 20),
                  tooltip: AppTexts.editVitalTitle,
                  onPressed: () => _openEdit(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  tooltip: AppTexts.deleteVitalTitle,
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => VitalTitleFormScreen(vital: vital),
        ))
        .then((_) {
      if (context.mounted) {
        context.read<VitalsTitlesCubit>().fetchVitalsTitles();
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.deleteVitalTitle),
        content: const Text(AppTexts.deleteVitalTitleConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<VitalsTitlesCubit>().deleteVitalTitle(vital.id);
            },
            child: const Text(AppTexts.deleteVitalTitle),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

