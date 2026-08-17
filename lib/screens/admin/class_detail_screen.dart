import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'package:flutter_web/Widgets/confirm_dialog.dart';
import 'package:flutter_web/screens/shared/diagnostic_class_results_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final int classId;
  final bool isAdmin;
  final bool canEditTeachers;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.isAdmin,
    this.canEditTeachers = false,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _classService = ClassService();
  late Future<ClassDetailInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = _classService.fetchClassDetail(widget.classId);
  }

  void _reload() {
    setState(() => _future = _classService.fetchClassDetail(widget.classId));
  }

  Future<void> _deleteClass(ClassDetailInfo detail) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete class',
      body:
          'Delete «${detail.className}»? All sessions, assignments, and results for this class will be permanently deleted.',
    );
    if (!confirmed || !mounted) return;

    final result = await _classService.deleteClass(classId: detail.classId);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class deleted')),
      );
      Navigator.of(context).pop(true);
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

  Future<void> _setClassArchived(
    ClassDetailInfo detail, {
    required bool archived,
  }) async {
    final confirmed = await showConfirmDialog(
      context,
      title: archived ? 'Archive class' : 'Restore class',
      body: archived
          ? 'Archive «${detail.className}»? Teachers and students will no longer see it.'
          : 'Restore «${detail.className}» to active classes?',
      confirmLabel: archived ? 'Archive' : 'Restore',
      confirmColor: archived ? TuranColors.warning : TuranColors.primary,
    );
    if (!confirmed || !mounted) return;

    final result = await _classService.updateClass(
      classId: detail.classId,
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

  Future<void> _removeStudent(ClassDetailInfo detail, UserInfo student) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove student',
      body: 'Remove «${student.name}» from «${detail.className}»?',
      confirmLabel: 'Remove',
      confirmColor: TuranColors.primary,
    );
    if (!confirmed || !mounted) return;

    final result = await _classService.removeStudentFromClass(
      classId: detail.classId,
      studentId: student.userId,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.name} removed from class')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Failed to remove student. Try again.',
        ),
      ),
    );
  }

  Future<void> _editTeachers(ClassDetailInfo detail) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditTeachersDialog(
        classService: _classService,
        detail: detail,
      ),
    );
    if (updated == true && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: FutureBuilder<ClassDetailInfo>(
        future: _future,
        builder: (context, snap) {
          return Column(
            children: [
              TuranHeader(
                title: snap.data?.className ?? 'Class',
                subtitle: snap.data?.archived == true
                    ? 'Archived class'
                    : 'Students and sessions',
                pageLabel: 'Admin',
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  if (widget.isAdmin && snap.hasData && !snap.data!.archived)
                    TuranHeaderAction(
                      icon: Icons.archive_outlined,
                      label: 'Archive',
                      onTap: () => _setClassArchived(snap.data!, archived: true),
                    ),
                  if (widget.isAdmin && snap.hasData && snap.data!.archived)
                    TuranHeaderAction(
                      icon: Icons.unarchive_rounded,
                      label: 'Restore',
                      onTap: () => _setClassArchived(snap.data!, archived: false),
                    ),
                  if (widget.isAdmin && snap.hasData)
                    TuranHeaderAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Class',
                      onTap: () => _deleteClass(snap.data!),
                    ),
                ],
              ),
              Expanded(
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(color: TuranColors.primary),
                      )
                    : snap.hasError
                    ? Center(child: Text('Failed to load class: ${snap.error}'))
                    : _ClassDetailBody(
                        detail: snap.data!,
                        isAdmin: widget.isAdmin,
                        onRemoveStudent: _removeStudent,
                        onEditTeachers: widget.canEditTeachers
                            ? () => _editTeachers(snap.data!)
                            : null,
                        onOpenDiagnosticResults: () {
                          final detail = snap.data!;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DiagnosticClassResultsScreen(
                                classId: detail.classId,
                                className: detail.className,
                                students: detail.students,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassDetailBody extends StatelessWidget {
  final ClassDetailInfo detail;
  final bool isAdmin;
  final Future<void> Function(ClassDetailInfo detail, UserInfo student)
  onRemoveStudent;
  final VoidCallback? onEditTeachers;
  final VoidCallback onOpenDiagnosticResults;

  const _ClassDetailBody({
    required this.detail,
    required this.isAdmin,
    required this.onRemoveStudent,
    required this.onOpenDiagnosticResults,
    this.onEditTeachers,
  });

  @override
  Widget build(BuildContext context) {
    final students = [...detail.students]
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      children: [
        _InfoCard(
          title: 'Teachers',
          lines: [
            'Verbal: ${detail.verbalTeacher?.fullName ?? '—'}',
            'Math: ${detail.mathTeacher?.fullName ?? '—'}',
          ],
          action: onEditTeachers == null
              ? null
              : TextButton.icon(
                  onPressed: onEditTeachers,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Diagnostic Results',
          lines: [
            'View completed diagnostic attempts for students in this class',
          ],
          action: TextButton.icon(
            onPressed: onOpenDiagnosticResults,
            icon: const Icon(Icons.quiz_rounded, size: 16),
            label: const Text('Open'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Students (${students.length})', style: TuranTextStyles.title),
        const SizedBox(height: 10),
        if (students.isEmpty)
          const Text('No students enrolled', style: TuranTextStyles.subtitle)
        else
          ...students.map(
            (student) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(student.fullName),
                subtitle: Text('ID: ${student.userId}'),
                trailing: isAdmin
                    ? IconButton(
                        icon: const Icon(Icons.person_remove),
                        color: TuranColors.error,
                        tooltip: 'Remove student',
                        onPressed: () => onRemoveStudent(detail, student),
                      )
                    : null,
              ),
            ),
          ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Sessions',
          lines: ['${detail.sessions.length} scheduled sessions'],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Widget? action;

  const _InfoCard({
    required this.title,
    required this.lines,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TuranTextStyles.title.copyWith(fontSize: 16),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: TuranTextStyles.subtitle),
            ),
        ],
      ),
    );
  }
}

class _EditTeachersDialog extends StatefulWidget {
  final ClassService classService;
  final ClassDetailInfo detail;

  const _EditTeachersDialog({
    required this.classService,
    required this.detail,
  });

  @override
  State<_EditTeachersDialog> createState() => _EditTeachersDialogState();
}

class _EditTeachersDialogState extends State<_EditTeachersDialog> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<UserInfo>> _teachersFuture;
  int? _verbalTeacherId;
  int? _mathTeacherId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verbalTeacherId = widget.detail.verbalTeacher?.userId;
    _mathTeacherId = widget.detail.mathTeacher?.userId;
    _teachersFuture = widget.classService.fetchTeachers();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verbalTeacherId == null || _mathTeacherId == null) {
      setState(() => _error = 'Choose both verbal and math teachers');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.classService.updateClass(
      classId: widget.detail.classId,
      verbalTeacherId: _verbalTeacherId,
      mathTeacherId: _mathTeacherId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final sessionsUpdated = result['sessions_updated'];
      final suffix = sessionsUpdated is int && sessionsUpdated > 0
          ? ' Updated $sessionsUpdated upcoming session(s).'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teachers updated.$suffix')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = result['message']?.toString() ?? 'Failed to update teachers';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Edit teachers'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<UserInfo>>(
          future: _teachersFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: TuranColors.primary),
                ),
              );
            }

            if (snap.hasError) {
              return Text(
                'Could not load teachers: ${snap.error}',
                style: const TextStyle(color: TuranColors.error),
              );
            }

            final teachers = snap.data ?? [];
            if (teachers.isEmpty) {
              return const Text('No teachers found.');
            }

            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _verbalTeacherId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Verbal teacher',
                      prefixIcon: Icon(Icons.menu_book_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: teachers
                        .map(
                          (teacher) => DropdownMenuItem<int>(
                            value: teacher.userId,
                            child: Text(
                              teacher.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _verbalTeacherId = value),
                    validator: (value) =>
                        value == null ? 'Choose a verbal teacher' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _mathTeacherId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Math teacher',
                      prefixIcon: Icon(Icons.calculate_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: teachers
                        .map(
                          (teacher) => DropdownMenuItem<int>(
                            value: teacher.userId,
                            child: Text(
                              teacher.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _mathTeacherId = value),
                    validator: (value) =>
                        value == null ? 'Choose a math teacher' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upcoming verbal/math sessions will be reassigned to the new teachers. Past sessions stay unchanged.',
                    style: TuranTextStyles.subtitle,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: TuranColors.error),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
