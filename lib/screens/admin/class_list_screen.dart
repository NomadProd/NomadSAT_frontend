import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/screens/admin/class_detail_screen.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'package:flutter_web/widgets/confirm_dialog.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final _classService = ClassService();
  final _authService = AuthService();
  late Future<_ClassListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClassListData> _load() async {
    final user = await _authService.fetchMe();
    final classes = await _classService.fetchClasses();
    classes.sort((a, b) => a.className.compareTo(b.className));
    return _ClassListData(user: user, classes: classes);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _deleteClass(ClassInfo classInfo) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete class',
      body:
          'Delete «${classInfo.className}»? All sessions, assignments, and results for this class will be permanently deleted.',
    );
    if (!confirmed || !mounted) return;

    final result = await _classService.deleteClass(classId: classInfo.classId);
    if (!mounted) return;

    if (result['success'] == true) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class deleted')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Failed to delete class. Try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: FutureBuilder<_ClassListData>(
        future: _future,
        builder: (context, snap) {
          final user = snap.data?.user;
          final isAdmin = user?.role.toLowerCase() == 'admin';

          return Column(
            children: [
              TuranHeader(
                user: user,
                title: 'Classes',
                subtitle: 'Admin class management',
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
                    ? Center(child: Text('Failed to load classes: ${snap.error}'))
                    : _ClassListBody(
                        classes: snap.data!.classes,
                        isAdmin: isAdmin,
                        onOpen: (classInfo) async {
                          final deleted = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ClassDetailScreen(
                                classId: classInfo.classId,
                                isAdmin: isAdmin,
                              ),
                            ),
                          );
                          if (deleted == true) {
                            _reload();
                          }
                        },
                        onDelete: isAdmin ? _deleteClass : null,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassListData {
  final UserInfo user;
  final List<ClassInfo> classes;

  const _ClassListData({required this.user, required this.classes});
}

class _ClassListBody extends StatelessWidget {
  final List<ClassInfo> classes;
  final bool isAdmin;
  final ValueChanged<ClassInfo> onOpen;
  final ValueChanged<ClassInfo>? onDelete;

  const _ClassListBody({
    required this.classes,
    required this.isAdmin,
    required this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(child: Text('No classes found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final classInfo = classes[index];
        return Material(
          color: TuranColors.surface,
          borderRadius: BorderRadius.circular(TuranRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(TuranRadius.lg),
            onTap: () => onOpen(classInfo),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.class_rounded, color: TuranColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      classInfo.className,
                      style: TuranTextStyles.title.copyWith(fontSize: 16),
                    ),
                  ),
                  if (isAdmin && onDelete != null)
                    IconButton(
                      tooltip: 'Delete class',
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: TuranColors.error,
                      onPressed: () => onDelete!(classInfo),
                    ),
                  const Icon(Icons.chevron_right_rounded, color: TuranColors.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
