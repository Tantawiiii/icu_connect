import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/confirm_action_dialog.dart';
import '../../../../core/widgets/list_error_view.dart';
import '../../../../core/widgets/list_search_field.dart';
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

List<LabTitleModel> _filterLabsTitles(List<LabTitleModel> items, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((e) {
    return e.title.toLowerCase().contains(q) ||
        e.unit.toLowerCase().contains(q) ||
        e.normalRangeMin.toLowerCase().contains(q) ||
        e.normalRangeMax.toLowerCase().contains(q);
  }).toList();
}

class _LabsTitlesListView extends StatefulWidget {
  const _LabsTitlesListView();

  @override
  State<_LabsTitlesListView> createState() => _LabsTitlesListViewState();
}

class _LabsTitlesListViewState extends State<_LabsTitlesListView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = _searchController.text);
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _openForm(BuildContext context, {required LabTitleModel? lab}) {
    final cubit = context.read<LabsTitlesCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: LabsTitleFormScreen(lab: lab),
            ),
          ),
        )
        .then((_) {
          if (context.mounted) cubit.fetchLabsTitles();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(AppTexts.labsTitlesLabel),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () => context.read<LabsTitlesCubit>().fetchLabsTitles(),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              12,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: ListSearchField(
              controller: _searchController,
              hintText: AppTexts.searchLabsTitlesHint,
              onClear: () {
                _debounce?.cancel();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<LabsTitlesCubit, LabsTitlesState>(
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
                  return ListErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<LabsTitlesCubit>().fetchLabsTitles(),
                  );
                }
                if (state is LabsTitlesLoaded) {
                  final filtered = _filterLabsTitles(state.items, _query);
                  final searchActive = _query.trim().isNotEmpty;
                  final list = _LabsList(
                    items: filtered,
                    emptyFromSearch: searchActive && state.items.isNotEmpty,
                  );
                  if (state is LabsTitlesActionLoading) {
                    return Stack(
                      children: [
                        list,
                        const ColoredBox(
                          color: Color(0x55000000),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return list;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LabsList extends StatelessWidget {
  const _LabsList({required this.items, this.emptyFromSearch = false});

  final List<LabTitleModel> items;
  final bool emptyFromSearch;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              emptyFromSearch
                  ? Icons.search_off_outlined
                  : Icons.science_outlined,
              size: 56,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              emptyFromSearch
                  ? AppTexts.labsTitlesSearchEmpty
                  : 'No labs titles found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
        itemBuilder: (context, index) => _LabCard(lab: items[index]),
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
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Colors.deepPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lab.title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (lab.unit.isNotEmpty) ...[
                        Text(
                          lab.unit,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'Normal: ${lab.normalRangeMin} – ${lab.normalRangeMax}',
                        style: Theme.of(context).textTheme.bodySmall,
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
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  tooltip: AppTexts.editLabTitle,
                  onPressed: () => _openEdit(context),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
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
    final cubit = context.read<LabsTitlesCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: LabsTitleFormScreen(lab: lab),
            ),
          ),
        )
        .then((_) {
          if (context.mounted) cubit.fetchLabsTitles();
        });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deleteLabTitle,
      message: AppTexts.deleteLabTitleConfirmation,
      confirmLabel: AppTexts.deleteLabTitle,
    );
    if (confirmed && context.mounted) {
      context.read<LabsTitlesCubit>().deleteLabTitle(lab.id);
    }
  }
}
