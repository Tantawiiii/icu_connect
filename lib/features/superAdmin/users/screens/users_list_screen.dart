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
import '../../admins/models/pagination_model.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';
import '../models/user_model.dart';
import 'user_form_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit()..fetchUsers(),
      child: const _UsersListView(),
    );
  }
}

List<UserModel> _filterUsers(List<UserModel> users, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return users;
  return users.where((u) {
    if (u.name.toLowerCase().contains(q)) return true;
    if (u.email.toLowerCase().contains(q)) return true;
    if (u.phone.toLowerCase().contains(q)) return true;
    if (u.role.toLowerCase().contains(q)) return true;
    return false;
  }).toList();
}

class _UsersListView extends StatefulWidget {
  const _UsersListView();

  @override
  State<_UsersListView> createState() => _UsersListViewState();
}

class _UsersListViewState extends State<_UsersListView> {
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
        title: const Text(AppTexts.usersLabel),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              final state = context.read<UsersCubit>().state;
              final page = state is UsersLoaded
                  ? state.pagination.currentPage
                  : 1;
              context.read<UsersCubit>().fetchUsers(page: page);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text(AppTexts.addUser),
        onPressed: () => _openForm(context, user: null),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: ListSearchField(
              controller: _searchController,
              hintText: 'Search users',
              onSubmitted: (_) => _applySearch(),
              onClear: _applySearch,
            ),
          ),
          Expanded(
            child: BlocConsumer<UsersCubit, UsersState>(
              listener: (context, state) {
                if (state is UsersActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                if (state is UsersActionFailure) {
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
                if (state is UsersLoading || state is UsersInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is UsersFailure) {
                  return ListErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<UsersCubit>().fetchUsers(page: 1),
                  );
                }
                if (state is UsersActionLoading) {
                  return Stack(
                    children: [
                      _UsersList(
                        users: state.users,
                        pagination: state.pagination,
                        searchQuery: _searchQuery,
                      ),
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
                if (state is UsersLoaded) {
                  return _UsersList(
                    users: state.users,
                    pagination: state.pagination,
                    searchQuery: _searchQuery,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {required UserModel? user}) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => UserFormScreen(user: user)))
        .then((_) {
          if (!context.mounted) return;
          final state = context.read<UsersCubit>().state;
          final page = state is UsersLoaded ? state.pagination.currentPage : 1;
          context.read<UsersCubit>().fetchUsers(page: page);
        });
  }
}

// ── List ─────────────────────────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.pagination,
    required this.searchQuery,
  });

  final List<UserModel> users;
  final PaginationModel pagination;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
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
            Text('No users found', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    final filtered = _filterUsers(users, searchQuery);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          context.read<UsersCubit>().fetchUsers(page: pagination.currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: filtered.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Showing ${pagination.from}-${pagination.to} '
                'of ${pagination.total} users',
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
                    : () => context.read<UsersCubit>().fetchUsers(
                        page: pagination.currentPage - 1,
                      ),
                onNext: isLast
                    ? null
                    : () => context.read<UsersCubit>().fetchUsers(
                        page: pagination.currentPage + 1,
                      ),
              ),
            );
          }
          return _UserCard(user: filtered[index - 1]);
        },
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final bool deleted = user.isDeleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: deleted
                          ? AppColors.error.withAlpha(25)
                          : AppColors.primary.withAlpha(20),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: deleted ? AppColors.error : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: deleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: deleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (user.phone.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              user.phone,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (deleted)
                      const StatusBadge(
                        label: AppTexts.deleted,
                        color: AppColors.error,
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Badges ─────────────────────────────────────────────────
                Row(
                  children: [
                    StatusBadge(
                      label: user.role.replaceAll('_', ' ').toUpperCase(),
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: user.isActive
                          ? AppTexts.active
                          : AppTexts.inactive,
                      color: user.isActive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),

                // ── Hospital assignments ────────────────────────────────────
                if (user.hospitals.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final h in user.hospitals.take(3))
                        _HospitalChip(hospital: h),
                      if (user.hospitals.length > 3)
                        StatusBadge(
                          label: '+${user.hospitals.length - 3} more',
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // ── Actions ─────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: deleted
                      ? [
                          _ActionButton(
                            icon: Icons.restore_outlined,
                            label: AppTexts.restoreUser,
                            color: AppColors.success,
                            onTap: () => _confirmRestore(context),
                          ),
                        ]
                      : [
                          _ActionButton(
                            icon: Icons.edit_outlined,
                            label: AppTexts.editUser,
                            color: AppColors.accent,
                            onTap: () => _openEdit(context),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.delete_outline,
                            label: AppTexts.deleteUser,
                            color: AppColors.error,
                            onTap: () => _confirmDelete(context),
                          ),
                        ],
                ),
              ],
            ),
          ),

          if (deleted)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: AppColors.error.withAlpha(10)),
              ),
            ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => UserFormScreen(user: user)))
        .then((_) {
          if (!context.mounted) return;
          final state = context.read<UsersCubit>().state;
          final page = state is UsersLoaded ? state.pagination.currentPage : 1;
          context.read<UsersCubit>().fetchUsers(page: page);
        });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.deleteUser,
      message: AppTexts.deleteUserConfirmation,
      confirmLabel: AppTexts.deleteUser,
    );
    if (confirmed && context.mounted) {
      context.read<UsersCubit>().deleteUser(user.id);
    }
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: AppTexts.restoreUser,
      message: AppTexts.restoreUserConfirmation,
      confirmLabel: AppTexts.restoreUser,
      isDestructive: false,
    );
    if (confirmed && context.mounted) {
      context.read<UsersCubit>().restoreUser(user.id);
    }
  }
}

// ── Hospital assignment chip ──────────────────────────────────────────────────

class _HospitalChip extends StatelessWidget {
  const _HospitalChip({required this.hospital});

  final UserHospitalModel hospital;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_hospital_outlined,
            size: 11,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            hospital.name,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '•',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 4),
          Text(
            hospital.pivot.roleInHospital,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
