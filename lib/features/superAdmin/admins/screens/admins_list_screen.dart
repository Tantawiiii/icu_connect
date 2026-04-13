import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.superAdmins,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              final state = context.read<AdminsCubit>().state;
              final page =
                  state is AdminsLoaded ? state.pagination.currentPage : 1;
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Search admins',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
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
                  AdminsFailure(:final message) => _ErrorView(
                      message: message,
                      onRetry: () => context.read<AdminsCubit>().fetchAdmins(
                            page: 1,
                          ),
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
        .push(MaterialPageRoute(
      builder: (_) => AdminFormScreen(admin: admin),
    ))
        .then((_) {
      if (!context.mounted) return;
      final state = context.read<AdminsCubit>().state;
      final page = state is AdminsLoaded ? state.pagination.currentPage : 1;
      context.read<AdminsCubit>().fetchAdmins(
            page: page,
          );
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 56, color: AppColors.secondary),
            SizedBox(height: 12),
            Text('No admins found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context
          .read<AdminsCubit>()
          .fetchAdmins(page: pagination.currentPage),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Showing ${pagination.from}-${pagination.to} '
              'of ${pagination.total} admins',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          ..._filterAdmins(admins, searchQuery)
              .map((admin) => _AdminCard(admin: admin)),
          const SizedBox(height: 6),
          _PaginationControls(pagination: pagination),
        ],
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.pagination,
  });

  final PaginationModel pagination;

  @override
  Widget build(BuildContext context) {
    final isFirst = pagination.currentPage <= 1;
    final isLast = pagination.currentPage >= pagination.lastPage;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFirst
                  ? null
                  : () => context
                      .read<AdminsCubit>()
                      .fetchAdmins(page: pagination.currentPage - 1),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${pagination.currentPage}/${pagination.lastPage}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLast
                  ? null
                  : () => context
                      .read<AdminsCubit>()
                      .fetchAdmins(page: pagination.currentPage + 1),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ),
        ],
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
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    admin.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Badge(
                        label: admin.role.replaceAll('_', ' ').toUpperCase(),
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      _Badge(
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
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.accent, size: 20),
                  tooltip: AppTexts.editAdmin,
                  onPressed: () => _openEdit(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
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
        .push(MaterialPageRoute(
      builder: (_) => AdminFormScreen(admin: admin),
    ))
        .then((_) {
      if (!context.mounted) return;
      final state = context.read<AdminsCubit>().state;
      final page = state is AdminsLoaded ? state.pagination.currentPage : 1;
      context.read<AdminsCubit>().fetchAdmins(page: page);
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.deleteAdmin),
        content: const Text(AppTexts.deleteAdminConfirmation),
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
              context.read<AdminsCubit>().deleteAdmin(admin.id);
            },
            child: const Text(AppTexts.deleteAdmin),
          ),
        ],
      ),
    );
  }
}

// ── Reusable badge ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

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
