import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/screens/admin/class_detail_screen.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'package:flutter_web/Widgets/confirm_dialog.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final _classService = ClassService();
  final _authService = AuthService();
  bool _showArchived = false;

  late Future<_ClassListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClassListData> _load() async {
    final user = await _authService.fetchMe();
    final isAdmin = user.role.toLowerCase() == 'admin';
    final classes = await _classService.fetchClasses(
      archived: isAdmin ? _showArchived : null,
    );
    classes.sort((a, b) => a.className.compareTo(b.className));
    return _ClassListData(user: user, classes: classes);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _setArchivedTab(bool archived) {
    if (_showArchived == archived) return;
    setState(() {
      _showArchived = archived;
      _future = _load();
    });
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

  Future<void> _setClassArchived(ClassInfo classInfo, {required bool archived}) async {
    final confirmed = await showConfirmDialog(
      context,
      title: archived ? 'Archive class' : 'Restore class',
      body: archived
          ? 'Archive «${classInfo.className}»? Teachers and students will no longer see it.'
          : 'Restore «${classInfo.className}» to active classes?',
      confirmLabel: archived ? 'Archive' : 'Restore',
      confirmColor: archived ? TuranColors.warning : TuranColors.primary,
    );
    if (!confirmed || !mounted) return;

    final result = await _classService.updateClass(
      classId: classInfo.classId,
      archived: archived,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(archived ? 'Class archived' : 'Class restored'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Failed to update class. Try again.',
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
                subtitle: isAdmin
                    ? (_showArchived ? 'Archived classes' : 'Active classes')
                    : 'Admin class management',
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
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Active'),
                        icon: Icon(Icons.play_circle_outline_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Archived'),
                        icon: Icon(Icons.inventory_2_outlined, size: 18),
                      ),
                    ],
                    selected: {_showArchived},
                    onSelectionChanged: (selection) {
                      _setArchivedTab(selection.first);
                    },
                  ),
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
                        showArchived: _showArchived,
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
                        onArchive: isAdmin && !_showArchived
                            ? (classInfo) =>
                                  _setClassArchived(classInfo, archived: true)
                            : null,
                        onRestore: isAdmin && _showArchived
                            ? (classInfo) =>
                                  _setClassArchived(classInfo, archived: false)
                            : null,
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
  final bool showArchived;
  final ValueChanged<ClassInfo> onOpen;
  final ValueChanged<ClassInfo>? onDelete;
  final ValueChanged<ClassInfo>? onArchive;
  final ValueChanged<ClassInfo>? onRestore;

  const _ClassListBody({
    required this.classes,
    required this.isAdmin,
    required this.showArchived,
    required this.onOpen,
    this.onDelete,
    this.onArchive,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return Center(
        child: Text(
          showArchived ? 'No archived classes' : 'No active classes found',
        ),
      );
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
                  Icon(
                    showArchived
                        ? Icons.inventory_2_outlined
                        : Icons.class_rounded,
                    color: showArchived
                        ? TuranColors.textMid
                        : TuranColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classInfo.className,
                          style: TuranTextStyles.title.copyWith(fontSize: 16),
                        ),
                        if (showArchived)
                          Text(
                            'Archived',
                            style: TuranTextStyles.subtitle.copyWith(
                              color: TuranColors.warning,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isAdmin && onRestore != null)
                    IconButton(
                      tooltip: 'Restore class',
                      icon: const Icon(Icons.unarchive_rounded),
                      color: TuranColors.primary,
                      onPressed: () => onRestore!(classInfo),
                    ),
                  if (isAdmin && onArchive != null)
                    IconButton(
                      tooltip: 'Archive class',
                      icon: const Icon(Icons.archive_outlined),
                      color: TuranColors.warning,
                      onPressed: () => onArchive!(classInfo),
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
