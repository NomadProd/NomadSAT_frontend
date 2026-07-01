import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'package:flutter_web/Widgets/confirm_dialog.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _classService = ClassService();
  final _authService = AuthService();
  late Future<_UserListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_UserListData> _load() async {
    final currentUser = await _authService.fetchMe();
    final users = await _classService.fetchUsers();
    users.sort((a, b) {
      final roleCompare = a.role.compareTo(b.role);
      if (roleCompare != 0) return roleCompare;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return _UserListData(currentUser: currentUser, users: users);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _deleteUser(UserInfo user) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete user',
      body:
          'Delete «${user.name} ${user.surname}» (${user.email ?? 'no email'})? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    final result = await _classService.deleteUser(userId: user.userId);
    if (!mounted) return;

    if (result['success'] == true) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted')),
      );
      return;
    }

    final message = result['error'] == 'SELF_DELETE_FORBIDDEN'
        ? 'You cannot delete your own account'
        : result['message']?.toString() ?? 'Failed to delete user. Try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: FutureBuilder<_UserListData>(
        future: _future,
        builder: (context, snap) {
          final currentUser = snap.data?.currentUser;
          final isAdmin = currentUser?.role.toLowerCase() == 'admin';

          return Column(
            children: [
              TuranHeader(
                user: currentUser,
                title: 'Users',
                subtitle: 'Admin user management',
                pageLabel: 'Admin',
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  TuranHeaderAction(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    onTap: _reload,
                  ),
                ],
              ),
              Expanded(
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(color: TuranColors.primary),
                      )
                    : snap.hasError
                    ? Center(child: Text('Failed to load users: ${snap.error}'))
                    : !isAdmin
                    ? const Center(child: Text('Admin access required'))
                    : _UserListBody(
                        users: snap.data!.users,
                        currentUserId: currentUser!.userId,
                        onDelete: _deleteUser,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserListData {
  final UserInfo currentUser;
  final List<UserInfo> users;

  const _UserListData({required this.currentUser, required this.users});
}

class _UserListBody extends StatelessWidget {
  final List<UserInfo> users;
  final int currentUserId;
  final ValueChanged<UserInfo> onDelete;

  const _UserListBody({
    required this.users,
    required this.currentUserId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelf = user.userId == currentUserId;

        return Material(
          color: TuranColors.surface,
          borderRadius: BorderRadius.circular(TuranRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: TuranColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: TuranColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TuranTextStyles.title.copyWith(fontSize: 16),
                      ),
                      Text(
                        '${user.email ?? '—'} · ${user.role}',
                        style: TuranTextStyles.subtitle,
                      ),
                    ],
                  ),
                ),
                if (!isSelf)
                  IconButton(
                    tooltip: 'Delete user',
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: TuranColors.error,
                    onPressed: () => onDelete(user),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
