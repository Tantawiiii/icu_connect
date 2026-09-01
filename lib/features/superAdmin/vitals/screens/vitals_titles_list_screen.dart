import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/confirm_action_dialog.dart';
import '../../../../core/widgets/list_error_view.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/paginated_list_footer.dart';
import '../../admins/models/pagination_model.dart';
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

List<VitalTitleModel> _filterVitalsTitles(
  List<VitalTitleModel> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((e) {
    return e.title.toLowerCase().contains(q) ||
        e.unit.toLowerCase().contains(q) ||
        e.normalRangeMin.toLowerCase().contains(q) ||
        e.normalRangeMax.toLowerCase().contains(q);
  }).toList();
}

class _VitalsTitlesListView extends StatefulWidget {
  const _VitalsTitlesListView();

  @override
  State<_VitalsTitlesListView> createState() => _VitalsTitlesListViewState();
}

class _VitalsTitlesListViewState extends State<_VitalsTitlesListView> {
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

  void _openForm(BuildContext context, {required VitalTitleModel? vital}) {
    final cubit = context.read<VitalsTitlesCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: VitalTitleFormScreen(vital: vital),
            ),
          ),
        )
        .then((_) {
          if (!context.mounted) return;
          final state = cubit.state;
          final page = state is VitalsTitlesLoaded
              ? state.pagination.currentPage
              : 1;
          cubit.fetchVitalsTitles(page: page);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(AppTexts.vitalsTitlesLabel),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              final cubit = context.read<VitalsTitlesCubit>();
              final state = cubit.state;
              final page = state is VitalsTitlesLoaded
                  ? state.pagination.currentPage
                  : 1;
              cubit.fetchVitalsTitles(page: page);
            },
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
              hintText: AppTexts.searchVitalsTitlesHint,
              onClear: () {
                _debounce?.cancel();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<VitalsTitlesCubit, VitalsTitlesState>(
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
                if (state is VitalsTitlesLoading ||
                    state is VitalsTitlesInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is VitalsTitlesFailure) {
                  return ListErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<VitalsTitlesCubit>()
                        .fetchVitalsTitles(page: 1),
                  );
                }
                if (state is VitalsTitlesLoaded) {
                  final filtered = _filterVitalsTitles(state.items, _query);
                  final searchActive = _query.trim().isNotEmpty;
                  final list = _VitalsList(
                    items: filtered,
                    allItemsCount: state.items.length,
                    pagination: state.pagination,
                    emptyFromSearch: searchActive && state.items.isNotEmpty,
                  );
                  if (state is VitalsTitlesActionLoading) {
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

class _VitalsList extends StatelessWidget {
  const _VitalsList({
    required this.items,
    required this.allItemsCount,
    required this.pagination,
    this.emptyFromSearch = false,
  });

  final List<VitalTitleModel> items;
  final int allItemsCount;
  final PaginationModel pagination;
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
                  : Icons.monitor_heart_outlined,
              size: 56,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              emptyFromSearch
                  ? AppTexts.vitalsTitlesSearchEmpty
                  : 'No vitals titles found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final showFooter = !emptyFromSearch || allItemsCount == 0;
    final itemCount = items.length + 1 + (showFooter ? 1 : 0);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<VitalsTitlesCubit>().fetchVitalsTitles(
        page: pagination.currentPage,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Showing ${pagination.from}-${pagination.to} '
                'of ${pagination.total} vitals titles',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          if (showFooter && index == itemCount - 1) {
            final isFirst = pagination.currentPage <= 1;
            final isLast = pagination.currentPage >= pagination.lastPage;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: PaginatedListFooter(
                currentPage: pagination.currentPage,
                lastPage: pagination.lastPage,
                onPrevious: isFirst
                    ? null
                    : () => context.read<VitalsTitlesCubit>().fetchVitalsTitles(
                        page: pagination.currentPage - 1,
                      ),
                onNext: isLast
                    ? null
                    : () => context.read<VitalsTitlesCubit>().fetchVitalsTitles(
                        page: pagination.currentPage + 1,
                      ),
              ),
            );
          }
          return _VitalCard(vital: items[index - 1]);
        },
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
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: Colors.redAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vital.title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (vital.unit.isNotEmpty) ...[
                        Text(
                          vital.unit,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'Normal: ${vital.normalRangeMin} – ${vital.normalRangeMax}',
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
                  tooltip: AppTexts.editVitalTitle,
                  onPressed: () => _openEdit(context),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
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
    final cubit = context.read<VitalsTitlesCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: VitalTitleFormScreen(vital: vital),
            ),
          ),
        )
        .then((_) {
          if (!context.mounted) return;
          final state = cubit.state;
          final page = state is VitalsTitlesLoaded
              ? state.pagination.currentPage
              : 1;
          cubit.fetchVitalsTitles(page: page);
        });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deleteVitalTitle,
      message: AppTexts.deleteVitalTitleConfirmation,
      confirmLabel: AppTexts.deleteVitalTitle,
    );
    if (confirmed && context.mounted) {
      context.read<VitalsTitlesCubit>().deleteVitalTitle(vital.id);
    }
  }
}
