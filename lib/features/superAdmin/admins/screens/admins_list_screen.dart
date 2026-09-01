import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/confirm_action_dialog.dart';
import '../../../../core/widgets/list_error_view.dart';
import '../../../../core/widgets/list_search_field.dart';
import '../../../../core/widgets/paginated_list_footer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../login/models/admin_model.dart';
import '../cubit/admins_cubit.dart';
import '../cubit/admins_state.dart';
import '../models/pagination_model.dart';
import '../repository/admins_repository.dart';
import 'admin_form_screen.dart';

class AdminsListScreen extends StatelessWidget {
  const AdminsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminsCubit(AdminsRepository())..fetchAdmins(),
      child: const _AdminsListView(),
    );
  }
}

List<AdminModel> _filterAdmins(List<AdminModel> admins, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return admins;
  return admins.where((a) {
    if (a.name.toLowerCase().contains(q)) return true;
    if (a.email.toLowerCase().contains(q)) return true;
    if (a.phone.toLowerCase().contains(q)) return true;
    if (a.role.toLowerCase().contains(q)) return true;
    return false;
  }).toList();
}

class _AdminsListView extends StatefulWidget {
  const _AdminsListView();

  @override
  State<_AdminsListView> createState() => _AdminsListViewState();
}

class _AdminsListViewState extends State<_AdminsListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() => _searchQuery = _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(AppTexts.superAdmins),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              final state = context.read<AdminsCubit>().state;
              final page = state is AdminsLoaded
                  ? state.pagination.currentPage
                  : 1;
              context.read<AdminsCubit>().fetchAdmins(page: page);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text(AppTexts.addAdmin),
        onPressed: () => _openForm(context, admin: null),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: ListSearchField(
              controller: _searchController,
              hintText: 'Search admins',
              onSubmitted: (_) => _applySearch(),
              onClear: _applySearch,
            ),
          ),
          Expanded(
            child: BlocConsumer<AdminsCubit, AdminsState>(
              listener: (context, state) {
                if (state is AdminsActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                if (state is AdminsActionFailure) {
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
                return switch (state) {
                  AdminsLoading() || AdminsInitial() => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  AdminsFailure(:final message) => ListErrorView(
                    message: message,
                    onRetry: () =>
                        context.read<AdminsCubit>().fetchAdmins(page: 1),
                  ),
                  AdminsLoaded(:final admins, :final pagination) => _AdminsList(
                    admins: admins,
                    pagination: pagination,
                    searchQuery: _searchQuery,
                  ),
                  AdminsActionLoading() => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {required AdminModel? admin}) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AdminFormScreen(admin: admin)))
        .then((_) {
          if (!context.mounted) return;
          final state = context.read<AdminsCubit>().state;
          final page = state is AdminsLoaded ? state.pagination.currentPage : 1;
          context.read<AdminsCubit>().fetchAdmins(page: page);
        });
  }
}

// ── List ─────────────────────────────────────────────────────────────────────

class _AdminsList extends StatelessWidget {
  const _AdminsList({
    required this.admins,
    required this.pagination,
    required this.searchQuery,
  });

  final List<AdminModel> admins;
  final PaginationModel pagination;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    if (admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 56,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('No admins found', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    final filtered = _filterAdmins(admins, searchQuery);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          context.read<AdminsCubit>().fetchAdmins(page: pagination.currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: filtered.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Showing ${pagination.from}-${pagination.to} '
                'of ${pagination.total} admins',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          if (index == filtered.length + 1) {
            final isFirst = pagination.currentPage <= 1;
            final isLast = pagination.currentPage >= pagination.lastPage;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: PaginatedListFooter(
                currentPage: pagination.currentPage,
                lastPage: pagination.lastPage,
                onPrevious: isFirst
                    ? null
                    : () => context.read<AdminsCubit>().fetchAdmins(
                        page: pagination.currentPage - 1,
                      ),
                onNext: isLast
                    ? null
                    : () => context.read<AdminsCubit>().fetchAdmins(
                        page: pagination.currentPage + 1,
                      ),
              ),
            );
          }
          return _AdminCard(admin: filtered[index - 1]);
        },
      ),
    );
  }
}

// ── Admin card ────────────────────────────────────────────────────────────────

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.admin});

  final AdminModel admin;

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
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withAlpha(20),
              child: Text(
                admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(admin.name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(admin.email, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      StatusBadge(
                        label: admin.role.replaceAll('_', ' ').toUpperCase(),
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: admin.isActive
                            ? AppTexts.active
                            : AppTexts.inactive,
                        color: admin.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  tooltip: AppTexts.editAdmin,
                  onPressed: () => _openEdit(context),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  tooltip: AppTexts.deleteAdmin,
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
        .push(MaterialPageRoute(builder: (_) => AdminFormScreen(admin: admin)))
        .then((_) {
          if (!context.mounted) return;
          final state = context.read<AdminsCubit>().state;
          final page = state is AdminsLoaded ? state.pagination.currentPage : 1;
          context.read<AdminsCubit>().fetchAdmins(page: page);
        });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deleteAdmin,
      message: AppTexts.deleteAdminConfirmation,
      confirmLabel: AppTexts.deleteAdmin,
    );
    if (confirmed && context.mounted) {
      context.read<AdminsCubit>().deleteAdmin(admin.id);
    }
  }
}
