import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../cubit/labs_titles_cubit.dart';
import '../cubit/labs_titles_state.dart';
import '../models/lab_title_model.dart';
import 'labs_title_form_screen.dart';

class LabsTitlesListScreen extends StatelessWidget {
  const LabsTitlesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LabsTitlesCubit()..fetchLabsTitles(),
      child: const _LabsTitlesListView(),
    );
  }
}

class _LabsTitlesListView extends StatelessWidget {
  const _LabsTitlesListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.labsTitlesLabel,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () =>
                context.read<LabsTitlesCubit>().fetchLabsTitles(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_outlined),
        label: const Text(AppTexts.addLabTitle),
        onPressed: () => _openForm(context, lab: null),
      ),
      body: BlocConsumer<LabsTitlesCubit, LabsTitlesState>(
        listener: (context, state) {
          if (state is LabsTitlesActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is LabsTitlesActionFailure) {
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
          if (state is LabsTitlesLoading || state is LabsTitlesInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is LabsTitlesFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<LabsTitlesCubit>().fetchLabsTitles(),
            );
          }
          if (state is LabsTitlesActionLoading) {
            return Stack(
              children: [
                _LabsList(items: state.items),
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            );
          }
          if (state is LabsTitlesLoaded) {
            return _LabsList(items: state.items);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openForm(BuildContext context, {required LabTitleModel? lab}) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => LabsTitleFormScreen(lab: lab),
        ))
        .then((_) {
      if (context.mounted) {
        context.read<LabsTitlesCubit>().fetchLabsTitles();
      }
    });
  }
}

class _LabsList extends StatelessWidget {
  const _LabsList({required this.items});

  final List<LabTitleModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 56, color: AppColors.secondary),
            SizedBox(height: 12),
            Text('No labs titles found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<LabsTitlesCubit>().fetchLabsTitles(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _LabCard(lab: items[index]),
      ),
    );
  }
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.lab});

  final LabTitleModel lab;

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
                color: Colors.deepPurple.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.science_outlined,
                  color: Colors.deepPurple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lab.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lab.unit.isNotEmpty) ...[
                        Text(
                          lab.unit,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'Normal: ${lab.normalRangeMin} – ${lab.normalRangeMax}',
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
                  tooltip: AppTexts.editLabTitle,
                  onPressed: () => _openEdit(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  tooltip: AppTexts.deleteLabTitle,
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
          builder: (_) => LabsTitleFormScreen(lab: lab),
        ))
        .then((_) {
      if (context.mounted) {
        context.read<LabsTitlesCubit>().fetchLabsTitles();
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.deleteLabTitle),
        content: const Text(AppTexts.deleteLabTitleConfirmation),
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
              context.read<LabsTitlesCubit>().deleteLabTitle(lab.id);
            },
            child: const Text(AppTexts.deleteLabTitle),
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

