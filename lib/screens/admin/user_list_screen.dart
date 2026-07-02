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

  bool _isAdmin(UserInfo user) => user.role.toLowerCase() == 'admin';

  bool _isMentor(UserInfo user) => user.role.toLowerCase() == 'mentor';

  bool _canAccess(UserInfo user) => _isAdmin(user) || _isMentor(user);

  bool _canManageTarget(UserInfo actor, UserInfo target) {
    if (_isAdmin(actor)) return actor.userId != target.userId;
    if (_isMentor(actor)) return target.role.toLowerCase() == 'student';
    return false;
  }

  List<UserInfo> _visibleUsers(UserInfo actor, List<UserInfo> users) {
    if (_isAdmin(actor)) return users;
    return users.where((u) => u.role.toLowerCase() == 'student').toList();
  }

  Future<void> _showCreateDialog(UserInfo actor) async {
    final isAdmin = _isAdmin(actor);
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var selectedRole = 'student';
    final roleOptions = isAdmin
        ? ['student', 'teacher', 'mentor', 'admin']
        : ['student'];

    final createdRole = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create user'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _UserFormField(
                    width: 240,
                    controller: nameController,
                    label: 'First name',
                  ),
                  _UserFormField(
                    width: 240,
                    controller: surnameController,
                    label: 'Last name',
                  ),
                  _UserFormField(
                    width: 490,
                    controller: emailController,
                    label: 'Email',
                  ),
                  _UserFormField(
                    width: 240,
                    controller: passwordController,
                    label: 'Password',
                    obscureText: true,
                  ),
                  if (isAdmin)
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: roleOptions
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(_capitalizeRole(role)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedRole = value);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final result = await _classService.createUser(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  name: nameController.text.trim(),
                  surname: surnameController.text.trim(),
                  role: selectedRole,
                );
                if (!context.mounted) return;
                if (result['success'] == true) {
                  Navigator.of(dialogContext).pop(selectedRole);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message']?.toString() ?? 'Failed to create user',
                    ),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    if (createdRole != null && mounted) {
      _reload();
      await _showUserCreatedDialog(createdRole);
    }
  }

  Future<void> _showUserCreatedDialog(String role) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: TuranColors.success),
        title: const Text('Success'),
        content: Text(_userCreatedMessage(role)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(UserInfo actor, UserInfo user) async {
    final isAdmin = _isAdmin(actor);
    final nameController = TextEditingController(text: user.name);
    final surnameController = TextEditingController(text: user.surname);
    final emailController = TextEditingController(text: user.email ?? '');
    final passwordController = TextEditingController();
    var selectedRole = user.role.toLowerCase();
    final roleOptions = ['student', 'teacher', 'mentor', 'admin'];

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${user.fullName}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _UserFormField(
                    width: 240,
                    controller: nameController,
                    label: 'First name',
                  ),
                  _UserFormField(
                    width: 240,
                    controller: surnameController,
                    label: 'Last name',
                  ),
                  _UserFormField(
                    width: 490,
                    controller: emailController,
                    label: 'Email',
                  ),
                  _UserFormField(
                    width: 490,
                    controller: passwordController,
                    label: 'New password (optional)',
                    obscureText: true,
                  ),
                  if (isAdmin)
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: roleOptions
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(_capitalizeRole(role)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedRole = value);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final result = await _classService.updateUser(
                  userId: user.userId,
                  name: nameController.text.trim(),
                  surname: surnameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim().isEmpty
                      ? null
                      : passwordController.text.trim(),
                  role: isAdmin ? selectedRole : null,
                );
                if (!context.mounted) return;
                if (result['success'] == true) {
                  Navigator.of(dialogContext).pop(true);
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message']?.toString() ?? 'Failed to update user',
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    if (saved == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated')),
      );
    }
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
          final canAccess = currentUser != null && _canAccess(currentUser);
          final isAdmin = currentUser != null && _isAdmin(currentUser);
          final isMentor = currentUser != null && _isMentor(currentUser);

          return Column(
            children: [
              TuranHeader(
                user: currentUser,
                title: 'Users',
                subtitle: isAdmin
                    ? 'Admin user management'
                    : isMentor
                    ? 'Manage students'
                    : 'User management',
                pageLabel: isAdmin ? 'Admin' : 'Mentor',
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  if (canAccess)
                    TuranHeaderAction(
                      icon: Icons.person_add_rounded,
                      label: 'Create user',
                      onTap: () => _showCreateDialog(currentUser!),
                    ),
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
                        child: CircularProgressIndicator(
                          color: TuranColors.primary,
                        ),
                      )
                    : snap.hasError
                    ? Center(child: Text('Failed to load users: ${snap.error}'))
                    : !canAccess
                    ? const Center(child: Text('Access denied'))
                    : _UserListBody(
                        users: _visibleUsers(currentUser!, snap.data!.users),
                        currentUser: currentUser,
                        canManage: (target) =>
                            _canManageTarget(currentUser, target),
                        onEdit: (user) => _showEditDialog(currentUser, user),
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
  final UserInfo currentUser;
  final bool Function(UserInfo target) canManage;
  final ValueChanged<UserInfo> onEdit;
  final ValueChanged<UserInfo> onDelete;

  const _UserListBody({
    required this.users,
    required this.currentUser,
    required this.canManage,
    required this.onEdit,
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
        final manageable = canManage(user);

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
                if (manageable) ...[
                  IconButton(
                    tooltip: 'Edit user',
                    icon: const Icon(Icons.edit_outlined),
                    color: TuranColors.primary,
                    onPressed: () => onEdit(user),
                  ),
                  IconButton(
                    tooltip: 'Delete user',
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: TuranColors.error,
                    onPressed: () => onDelete(user),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserFormField extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final String label;
  final bool obscureText;

  const _UserFormField({
    required this.width,
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

String _capitalizeRole(String role) {
  if (role.isEmpty) return role;
  return role[0].toUpperCase() + role.substring(1);
}

String _userCreatedMessage(String role) {
  switch (role.toLowerCase()) {
    case 'mentor':
      return 'Mentor has been successfully added.';
    case 'student':
      return 'Student has been successfully added.';
    case 'teacher':
      return 'Teacher has been successfully added.';
    case 'admin':
      return 'Admin has been successfully added.';
    default:
      return 'User has been successfully added.';
  }
}
