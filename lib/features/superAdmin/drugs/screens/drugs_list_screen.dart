import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../admins/models/pagination_model.dart';
import '../cubit/drugs_cubit.dart';
import '../cubit/drugs_state.dart';
import '../models/drug_model.dart';
import 'drug_details_screen.dart';
import 'drug_form_screen.dart';

class DrugsListScreen extends StatelessWidget {
  const DrugsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DrugsCubit()..fetchDrugs(),
      child: const _DrugsListView(),
    );
  }
}

class _DrugsListView extends StatefulWidget {
  const _DrugsListView();

  @override
  State<_DrugsListView> createState() => _DrugsListViewState();
}

class _DrugsListViewState extends State<_DrugsListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm(BuildContext context, {DrugModel? drug}) async {
    final cubit = context.read<DrugsCubit>();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: DrugFormScreen(drug: drug),
        ),
      ),
    );
    if (!context.mounted) return;
    final state = cubit.state;
    final page = state is DrugsLoaded ? state.pagination.currentPage : 1;
    cubit.fetchDrugs(page: page);
  }

  Future<void> _openDetails(BuildContext context, DrugModel drug) async {
    final cubit = context.read<DrugsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: DrugDetailsScreen(drugId: drug.id, initialDrug: drug),
        ),
      ),
    );
    if (!context.mounted) return;
    final state = cubit.state;
    final page = state is DrugsLoaded ? state.pagination.currentPage : 1;
    cubit.fetchDrugs(page: page);
  }

  void _submitSearch() {
    context.read<DrugsCubit>().search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.drugsLabel,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              final cubit = context.read<DrugsCubit>();
              final state = cubit.state;
              final page = state is DrugsLoaded
                  ? state.pagination.currentPage
                  : 1;
              cubit.fetchDrugs(page: page);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.medication_outlined),
        label: const Text(AppTexts.addDrug),
        onPressed: () => _openForm(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submitSearch(),
                  decoration: InputDecoration(
                    hintText: AppTexts.searchDrugsHint,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (value.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<DrugsCubit>().search('');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _submitSearch,
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          BlocBuilder<DrugsCubit, DrugsState>(
            builder: (context, state) {
              final filter = state is DrugsLoaded
                  ? state.filter
                  : DrugsListFilter.all;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: AppTexts.drugAllFilter,
                      selected: filter == DrugsListFilter.all,
                      onTap: () => context.read<DrugsCubit>().setFilter(
                        DrugsListFilter.all,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppTexts.drugActive,
                      selected: filter == DrugsListFilter.active,
                      onTap: () => context.read<DrugsCubit>().setFilter(
                        DrugsListFilter.active,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppTexts.drugInactive,
                      selected: filter == DrugsListFilter.inactive,
                      onTap: () => context.read<DrugsCubit>().setFilter(
                        DrugsListFilter.inactive,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppTexts.drugArchivedFilter,
                      selected: filter == DrugsListFilter.archived,
                      onTap: () => context.read<DrugsCubit>().setFilter(
                        DrugsListFilter.archived,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocConsumer<DrugsCubit, DrugsState>(
              listener: (context, state) {
                if (state is DrugsActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                if (state is DrugsActionFailure) {
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
                if (state is DrugsLoading || state is DrugsInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is DrugsFailure) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<DrugsCubit>().fetchDrugs(page: 1),
                  );
                }
                if (state is DrugsLoaded) {
                  final list = _DrugsList(
                    items: state.items,
                    pagination: state.pagination,
                    searchActive: state.search.isNotEmpty,
                    onOpen: (drug) => _openDetails(context, drug),
                    onEdit: (drug) => _openForm(context, drug: drug),
                  );
                  if (state is DrugsActionLoading) {
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      backgroundColor: Colors.white,
    );
  }
}

class _DrugsList extends StatelessWidget {
  const _DrugsList({
    required this.items,
    required this.pagination,
    required this.searchActive,
    required this.onOpen,
    required this.onEdit,
  });

  final List<DrugModel> items;
  final PaginationModel pagination;
  final bool searchActive;
  final ValueChanged<DrugModel> onOpen;
  final ValueChanged<DrugModel> onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searchActive
                  ? Icons.search_off_outlined
                  : Icons.medication_outlined,
              size: 56,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              searchActive ? AppTexts.drugsSearchEmpty : 'No drugs found',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          context.read<DrugsCubit>().fetchDrugs(page: pagination.currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: items.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Showing ${pagination.from}-${pagination.to} of ${pagination.total}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            );
          }
          if (index == items.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _PaginationControls(pagination: pagination),
            );
          }
          final drug = items[index - 1];
          return _DrugCard(
            drug: drug,
            onTap: () => onOpen(drug),
            onEdit: () => onEdit(drug),
          );
        },
      ),
    );
  }
}

class _DrugCard extends StatelessWidget {
  const _DrugCard({
    required this.drug,
    required this.onTap,
    required this.onEdit,
  });

  final DrugModel drug;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final archived = drug.isArchived;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      drug.genericName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: archived
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: archived
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  _StatusBadge(drug: drug),
                ],
              ),
              if (drug.tradeNames.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  drug.tradeNames.join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (archived)
                    TextButton.icon(
                      onPressed: () => _confirmRestore(context, drug),
                      icon: const Icon(Icons.restore_outlined, size: 18),
                      label: const Text(AppTexts.restoreDrug),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                      ),
                    )
                  else ...[
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(AppTexts.editDrug),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmArchive(context, drug),
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: const Text(AppTexts.archiveDrug),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, DrugModel drug) async {
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
    if (confirmed == true && context.mounted) {
      context.read<DrugsCubit>().archiveDrug(drug.id);
    }
  }

  Future<void> _confirmRestore(BuildContext context, DrugModel drug) async {
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
    if (confirmed == true && context.mounted) {
      context.read<DrugsCubit>().restoreDrug(drug.id);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.drug});

  final DrugModel drug;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (drug.isArchived) {
      color = AppColors.error;
      label = AppTexts.drugArchivedFilter;
    } else if (drug.isActive) {
      color = AppColors.success;
      label = AppTexts.drugActive;
    } else {
      color = AppColors.textSecondary;
      label = AppTexts.drugInactive;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({required this.pagination});

  final PaginationModel pagination;

  @override
  Widget build(BuildContext context) {
    if (pagination.lastPage <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: pagination.currentPage > 1
              ? () => context.read<DrugsCubit>().fetchDrugs(
                  page: pagination.currentPage - 1,
                )
              : null,
          child: const Text('Prev'),
        ),
        Text(
          '${pagination.currentPage} / ${pagination.lastPage}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: pagination.hasNextPage
              ? () => context.read<DrugsCubit>().fetchDrugs(
                  page: pagination.currentPage + 1,
                )
              : null,
          child: const Text('Next'),
        ),
      ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
