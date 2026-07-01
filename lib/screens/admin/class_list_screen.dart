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

  late Future<_ClassListData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClassListData> _load() async {
    final user = await _authService.fetchMe();
    final classes = await _classService.fetchClasses();
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
                    ? 'Active and archived classes'
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
                        onArchive: isAdmin
                            ? (classInfo) =>
                                  _setClassArchived(classInfo, archived: true)
                            : null,
                        onRestore: isAdmin
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

// Apply future client filters to `all` first, then partition into these groups.
List<ClassInfo> activeClasses(List<ClassInfo> all) {
  return all.where((c) => !c.archived).toList()
    ..sort((a, b) => a.className.compareTo(b.className));
}

List<ClassInfo> archivedClasses(List<ClassInfo> all) {
  return all.where((c) => c.archived).toList()
    ..sort((a, b) => a.className.compareTo(b.className));
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TuranTextStyles.title.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 8),
          const Divider(color: TuranColors.border, height: 1),
        ],
      ),
    );
  }
}

class _ClassListBody extends StatelessWidget {
  final List<ClassInfo> classes;
  final bool isAdmin;
  final ValueChanged<ClassInfo> onOpen;
  final ValueChanged<ClassInfo>? onDelete;
  final ValueChanged<ClassInfo>? onArchive;
  final ValueChanged<ClassInfo>? onRestore;

  const _ClassListBody({
    required this.classes,
    required this.isAdmin,
    required this.onOpen,
    this.onDelete,
    this.onArchive,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        if (!isAdmin) {
          final sorted = [...classes]
            ..sort((a, b) => a.className.compareTo(b.className));
          return _buildScrollableContent(
            compact: compact,
            children: _buildFlatList(sorted),
          );
        }

        final active = activeClasses(classes);
        final archived = archivedClasses(classes);

        return _buildScrollableContent(
          compact: compact,
          children: [
            _SectionHeader(title: 'Active Classes (${active.length})'),
            if (active.isEmpty)
              const _SectionEmptyState(message: 'No active classes')
            else
              ..._buildClassCards(active, archived: false),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionHeader(title: 'Archived Classes (${archived.length})'),
              ..._buildClassCards(archived, archived: true),
            ],
          ],
        );
      },
    );
  }

  Widget _buildScrollableContent({
    required bool compact,
    required List<Widget> children,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? double.infinity : 960),
        child: ListView(
          padding: EdgeInsets.fromLTRB(compact ? 16 : 22, 22, compact ? 16 : 22, 34),
          children: children,
        ),
      ),
    );
  }

  List<Widget> _buildFlatList(List<ClassInfo> items) {
    if (items.isEmpty) {
      return const [
        _SectionEmptyState(message: 'No classes found'),
      ];
    }

    return [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        _ClassCard(
          classInfo: items[i],
          isAdmin: isAdmin,
          onOpen: onOpen,
          onDelete: onDelete,
          onArchive: onArchive,
          onRestore: onRestore,
        ),
      ],
    ];
  }

  List<Widget> _buildClassCards(List<ClassInfo> items, {required bool archived}) {
    return [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        _ClassCard(
          classInfo: items[i],
          isAdmin: isAdmin,
          onOpen: onOpen,
          onDelete: onDelete,
          onArchive: archived ? null : onArchive,
          onRestore: archived ? onRestore : null,
        ),
      ],
    ];
  }
}

class _SectionEmptyState extends StatelessWidget {
  final String message;

  const _SectionEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: TuranTextStyles.subtitle.copyWith(color: TuranColors.textMid),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassInfo classInfo;
  final bool isAdmin;
  final ValueChanged<ClassInfo> onOpen;
  final ValueChanged<ClassInfo>? onDelete;
  final ValueChanged<ClassInfo>? onArchive;
  final ValueChanged<ClassInfo>? onRestore;

  const _ClassCard({
    required this.classInfo,
    required this.isAdmin,
    required this.onOpen,
    this.onDelete,
    this.onArchive,
    this.onRestore,
  });

  bool get _isArchived => classInfo.archived;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _isArchived ? TuranColors.panelBg : TuranColors.surface,
      borderRadius: BorderRadius.circular(TuranRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        onTap: () => onOpen(classInfo),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TuranRadius.lg),
            border: Border.all(
              color: _isArchived
                  ? TuranColors.border.withValues(alpha: 0.7)
                  : TuranColors.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                _isArchived ? Icons.inventory_2_outlined : Icons.class_rounded,
                color: _isArchived ? TuranColors.textMid : TuranColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classInfo.className,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TuranTextStyles.title.copyWith(
                        fontSize: 16,
                        color: _isArchived
                            ? TuranColors.textMid
                            : TuranColors.textDark,
                      ),
                    ),
                    if (_isArchived) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: TuranColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: TuranColors.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          'Archived',
                          style: TuranTextStyles.caption.copyWith(
                            color: TuranColors.warning,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
  }
}
