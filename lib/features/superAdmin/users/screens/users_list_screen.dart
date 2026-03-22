import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
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

class _UsersListView extends StatelessWidget {
  const _UsersListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.usersLabel,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () => context.read<UsersCubit>().fetchUsers(),
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
      body: BlocConsumer<UsersCubit, UsersState>(
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
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<UsersCubit>().fetchUsers(),
            );
          }
          if (state is UsersActionLoading) {
            return Stack(
              children: [
                _UsersList(users: state.users),
                const ColoredBox(
                  color: Color(0x55000000),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            );
          }
          if (state is UsersLoaded) {
            return _UsersList(users: state.users);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openForm(BuildContext context, {required UserModel? user}) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => UserFormScreen(user: user),
        ))
        .then((_) {
      if (context.mounted) context.read<UsersCubit>().fetchUsers();
    });
  }
}

// ── List ─────────────────────────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  const _UsersList({required this.users});

  final List<UserModel> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 56, color: AppColors.secondary),
            SizedBox(height: 12),
            Text('No users found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<UsersCubit>().fetchUsers(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${users.length} ${users.length == 1 ? 'user' : 'users'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          ...users.map((u) => _UserCard(user: u)),
        ],
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
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: deleted
                              ? AppColors.error
                              : AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (user.phone.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              user.phone,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (deleted)
                      const _Chip(
                          label: AppTexts.deleted,
                          color: AppColors.error),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Badges ─────────────────────────────────────────────────
                Row(
                  children: [
                    _Chip(
                      label: user.role.replaceAll('_', ' ').toUpperCase(),
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    _Chip(
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
                        _Chip(
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
                child: ColoredBox(
                  color: AppColors.error.withAlpha(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => UserFormScreen(user: user),
        ))
        .then((_) {
      if (context.mounted) context.read<UsersCubit>().fetchUsers();
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.deleteUser),
        content: const Text(AppTexts.deleteUserConfirmation),
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
              context.read<UsersCubit>().deleteUser(user.id);
            },
            child: const Text(AppTexts.deleteUser),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppTexts.restoreUser),
        content: const Text(AppTexts.restoreUserConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<UsersCubit>().restoreUser(user.id);
            },
            child: const Text(AppTexts.restoreUser),
          ),
        ],
      ),
    );
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
          const Icon(Icons.local_hospital_outlined,
              size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            hospital.name,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Text('•',
              style:
                  TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          Text(
            hospital.pivot.roleInHospital,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

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
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
