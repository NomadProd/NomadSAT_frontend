import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'package:flutter_web/widgets/confirm_dialog.dart';

class ClassDetailScreen extends StatefulWidget {
  final int classId;
  final bool isAdmin;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.isAdmin,
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
                subtitle: 'Students and sessions',
                pageLabel: 'Admin',
                onBack: () => Navigator.of(context).pop(),
                actions: [
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

  const _ClassDetailBody({
    required this.detail,
    required this.isAdmin,
    required this.onRemoveStudent,
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

  const _InfoCard({required this.title, required this.lines});

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
          Text(title, style: TuranTextStyles.title.copyWith(fontSize: 16)),
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
