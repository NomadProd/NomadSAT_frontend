import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/Models/mock_result.dart';
import 'package:flutter_web/screens/admin/class_list_screen.dart';
import 'package:flutter_web/screens/admin/homework_result_detail_screen.dart';
import 'package:flutter_web/screens/admin/user_list_screen.dart';
import 'package:flutter_web/Widgets/confirm_dialog.dart';

const _kPrimary = Color(0xFF1A4AF0);
const _kBg = Color(0xFFF0F4FF);
const _kBorder = Color(0xFFD7E3FF);
const _kTextDark = Color(0xFF0D1B3E);
const _kTextMid = Color(0xFF4A5A7A);
const _kTextLight = Color(0xFF9AAAC6);
const _kSuccess = Color(0xFF1B873F);
const _kWarning = Color(0xFFEF6C00);
const _kMentor = Color(0xFF6A1B9A);

class ControlPanelPage extends StatefulWidget {
  const ControlPanelPage({super.key});

  @override
  State<ControlPanelPage> createState() => _ControlPanelPageState();
}

class _ControlPanelPageState extends State<ControlPanelPage> {
  final _authService = AuthService();
  final _classService = ClassService();
  late Future<_ControlPanelData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ControlPanelData> _load() async {
    final user = await _authService.fetchMe();
    final classes = await _classService.fetchClasses(archived: false);
    final details = await Future.wait(
      classes.map((classInfo) {
        return _classService.fetchClassFullDetail(classInfo.classId);
      }),
    );
    final users = await _classService.fetchUsers();

    details.sort((a, b) => a.className.compareTo(b.className));
    users.sort((a, b) {
      final roleCompare = a.role.compareTo(b.role);
      if (roleCompare != 0) return roleCompare;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });

    return _ControlPanelData(user: user, classes: details, users: users);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<_ControlPanelData>(
        future: _future,
        builder: (context, snap) {
          final user = snap.data?.user;
          return Column(
            children: [
              TuranHeader(
                user: user,
                title: 'Control Panel',
                subtitle:
                    'Structured database overview by class and user role.',
                pageLabel: 'Control Panel',
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  TuranHeaderAction(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    onTap: _refresh,
                  ),
                ],
              ),
              Expanded(
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(color: _kPrimary),
                      )
                    : snap.hasError
                    ? _ControlPanelError(
                        message: snap.error.toString(),
                        onRetry: _refresh,
                      )
                    : _ControlPanelContent(
                        data: snap.data!,
                        classService: _classService,
                        onChanged: _refresh,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ControlPanelData {
  final UserInfo user;
  final List<ClassFullDetailInfo> classes;
  final List<UserInfo> users;

  const _ControlPanelData({
    required this.user,
    required this.classes,
    required this.users,
  });
}

class _ClassResultBundle {
  final List<HomeworkResultInfo> homeworkResults;
  final List<MockResultInfo> mockResults;

  const _ClassResultBundle({
    required this.homeworkResults,
    required this.mockResults,
  });
}

class _ControlPanelContent extends StatelessWidget {
  final _ControlPanelData data;
  final ClassService classService;
  final VoidCallback onChanged;

  const _ControlPanelContent({
    required this.data,
    required this.classService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roleGroups = <String, List<UserInfo>>{};
    for (final user in data.users) {
      roleGroups.putIfAbsent(user.role, () => []).add(user);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
      children: [
        _OverviewMetrics(data: data),
        const SizedBox(height: 18),
        _SectionTitle(
          icon: Icons.class_rounded,
          title: 'Classes',
          subtitle:
              'Grouped class records with connected students, sessions, and workload.',
          action: data.user.role.toLowerCase() == 'admin'
              ? TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClassListScreen(),
                      ),
                    ).then((_) => onChanged());
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Manage classes'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (data.classes.isEmpty)
          const _EmptyPanel(message: 'No classes found')
        else
          ...data.classes.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClassDatabaseCard(
                detail: detail,
                teachers: data.users
                    .where((user) => user.role.toLowerCase() == 'teacher')
                    .toList(),
                users: data.users,
                classService: classService,
                currentUserRole: data.user.role,
                onChanged: onChanged,
              ),
            ),
          ),
        const SizedBox(height: 10),
        _SectionTitle(
          icon: Icons.people_alt_rounded,
          title: 'Users',
          subtitle: 'Users grouped separately by role.',
          action: _canManageUsers(data.user.role)
              ? TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserListScreen(),
                      ),
                    ).then((_) => onChanged());
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Manage users'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (data.users.isEmpty)
          const _EmptyPanel(message: 'No users found')
        else
          ...roleGroups.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UserRolePanel(role: entry.key, users: entry.value),
            ),
          ),
      ],
    );
  }
}

class _OverviewMetrics extends StatelessWidget {
  final _ControlPanelData data;

  const _OverviewMetrics({required this.data});

  @override
  Widget build(BuildContext context) {
    final sessionCount = data.classes.fold<int>(
      0,
      (total, detail) => total + detail.sessions.length,
    );
    final assignmentCount = data.classes.fold<int>(
      0,
      (total, detail) => total + detail.assignments.length,
    );
    final enrollmentCount = data.classes.fold<int>(
      0,
      (total, detail) => total + detail.students.length,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final width = narrow
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 30) / 4;
        final cards = [
          _MetricCard(
            label: 'Classes',
            value: data.classes.length.toString(),
            icon: Icons.class_rounded,
            color: _kPrimary,
          ),
          _MetricCard(
            label: 'Users',
            value: data.users.length.toString(),
            icon: Icons.people_alt_rounded,
            color: _kMentor,
          ),
          _MetricCard(
            label: 'Sessions',
            value: sessionCount.toString(),
            icon: Icons.event_rounded,
            color: _kWarning,
          ),
          _MetricCard(
            label: 'Assignments',
            value: assignmentCount.toString(),
            icon: Icons.assignment_rounded,
            color: _kSuccess,
          ),
          _MetricCard(
            label: 'Enrollments',
            value: enrollmentCount.toString(),
            icon: Icons.school_rounded,
            color: const Color(0xFF00897B),
          ),
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(width: width.clamp(180, 280).toDouble(), child: card),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassDatabaseCard extends StatelessWidget {
  final ClassFullDetailInfo detail;
  final List<UserInfo> teachers;
  final List<UserInfo> users;
  final ClassService classService;
  final String currentUserRole;
  final VoidCallback onChanged;

  const _ClassDatabaseCard({
    required this.detail,
    required this.teachers,
    required this.users,
    required this.classService,
    required this.currentUserRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: Icons.class_rounded, color: _kPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.className,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID ${detail.classId}  |  Verbal: ${_nameOf(detail.verbalTeacher)}  |  Math: ${_nameOf(detail.mathTeacher)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Students', value: detail.students.length),
              _InfoChip(label: 'Sessions', value: detail.sessions.length),
              _InfoChip(label: 'Homeworks', value: detail.assignments.length),
              _InfoChip(
                label: 'Homework results',
                value: detail.homeworkResultCount,
                onTap: () => _showClassTableDialog(
                  context: context,
                  detail: detail,
                  users: users,
                  classService: classService,
                  currentUserRole: currentUserRole,
                  onChanged: onChanged,
                  category: _ClassTableCategory.homeworkResults,
                ),
              ),
              _InfoChip(
                label: 'Mock results',
                value: detail.mockResultCount,
                onTap: () => _showClassTableDialog(
                  context: context,
                  detail: detail,
                  users: users,
                  classService: classService,
                  currentUserRole: currentUserRole,
                  onChanged: onChanged,
                  category: _ClassTableCategory.mockResults,
                ),
              ),
              _InfoChip(label: 'Attendance', value: detail.attendance.length),
            ],
          ),
          const SizedBox(height: 14),
          const _SubLabel('Students'),
          const SizedBox(height: 8),
          if (detail.students.isEmpty)
            const Text(
              'No enrolled students',
              style: TextStyle(color: _kTextLight, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final student in detail.students)
                  _NamePill(
                    label: student.fullName,
                    sublabel: 'ID ${student.userId}',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UserRolePanel extends StatelessWidget {
  final String role;
  final List<UserInfo> users;

  const _UserRolePanel({required this.role, required this.users});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: _roleIcon(role), color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_capitalize(role)} users',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _CountBadge(count: users.length, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final user in users)
                _NamePill(
                  label: user.fullName,
                  sublabel: user.email == null || user.email!.isEmpty
                      ? 'ID ${user.userId}'
                      : user.email!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ClassTableCategory {
  students,
  sessions,
  homeworks,
  homeworkResults,
  mockResults,
  attendance,
}

Future<void> _showHomeworkResultEditDialog({
  required BuildContext context,
  required HomeworkResultInfo result,
  required ClassService classService,
  required VoidCallback onChanged,
}) async {
  bool submitted = result.submitted;
  final correctController = TextEditingController(
    text: result.correctTotal?.toString() ?? '',
  );
  final incorrectController = TextEditingController(
    text: result.incorrectTotal?.toString() ?? '',
  );
  final analysisController = TextEditingController(text: result.analysis ?? '');
  String? photoLink = result.photoLink;
  String? selectedFileName = (photoLink ?? '').isEmpty
      ? null
      : 'Submitted screenshot';
  html.File? selectedPhotoFile;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit homework result'),
        content: SizedBox(
          width: 460,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: SwitchListTile(
                  value: submitted,
                  onChanged: (value) => setDialogState(() => submitted = value),
                  title: const Text('Submitted'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              _DialogField(
                width: 120,
                controller: correctController,
                label: 'Correct',
              ),
              _DialogField(
                width: 120,
                controller: incorrectController,
                label: 'Incorrect',
              ),
              SizedBox(
                width: 440,
                child: TextField(
                  controller: analysisController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Analysis'),
                ),
              ),
              SizedBox(
                width: 440,
                child: _PhotoPickerPanel(
                  photoLink: photoLink,
                  selectedFileName: selectedFileName,
                  onPick: () async {
                    final file = await _pickImageFile();
                    if (file == null) return;
                    setDialogState(() {
                      selectedPhotoFile = file;
                      selectedFileName = file.name;
                    });
                  },
                  onOpen: (photoLink ?? '').isEmpty
                      ? null
                      : () => html.window.open(photoLink!, '_blank'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final update = await classService.updateHomeworkResult(
                resultId: result.resultId,
                submitted: submitted,
                correctTotal: int.tryParse(correctController.text.trim()),
                incorrectTotal: int.tryParse(incorrectController.text.trim()),
                analysis: analysisController.text.trim(),
                photoFile: selectedPhotoFile,
                photoLink: photoLink,
              );
              if (!context.mounted) return;
              Navigator.of(dialogContext).pop();
              _showResultSnack(context, update);
              if (update['success'] == true) onChanged();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showMockResultEditDialog({
  required BuildContext context,
  required MockResultInfo result,
  required ClassService classService,
  required VoidCallback onChanged,
}) async {
  bool submitted = result.submitted;
  final verbalController = TextEditingController(
    text: result.verbalPoints?.toString() ?? '',
  );
  final mathController = TextEditingController(
    text: result.mathPoints?.toString() ?? '',
  );
  final weakAreasController = TextEditingController(
    text: result.weakAreas ?? '',
  );
  final verbalIncorrectController = TextEditingController(
    text: result.verbalIncorrect?.toString() ?? '',
  );
  final mathIncorrectController = TextEditingController(
    text: result.mathIncorrect?.toString() ?? '',
  );
  MockResultDetail? detail;
  String? filesError;

  try {
    detail = await classService.fetchMockResult(result.resultId);
  } catch (e) {
    filesError = e.toString();
  }

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit mock result'),
        content: SizedBox(
          width: 460,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: SwitchListTile(
                  value: submitted,
                  onChanged: (value) => setDialogState(() => submitted = value),
                  title: const Text('Submitted'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              _DialogField(
                width: 120,
                controller: verbalController,
                label: 'Verbal',
              ),
              _DialogField(
                width: 120,
                controller: mathController,
                label: 'Math',
              ),
              _DialogField(
                width: 160,
                controller: verbalIncorrectController,
                label: 'Verbal incorrect',
              ),
              _DialogField(
                width: 160,
                controller: mathIncorrectController,
                label: 'Math incorrect',
              ),
              SizedBox(
                width: 440,
                child: TextField(
                  controller: weakAreasController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Weak areas'),
                ),
              ),
              SizedBox(
                width: 440,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attached files',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (filesError != null)
                      Text(filesError!, style: const TextStyle(color: Colors.red))
                    else if (detail == null)
                      const Text('Loading files...')
                    else if (detail!.attachments.isEmpty &&
                        !(detail!.legacyPhoto && (detail!.photoLink ?? '').isNotEmpty))
                      const Text('No files attached')
                    else ...[
                      if (detail!.legacyPhoto && (detail!.photoLink ?? '').isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Legacy proof'),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => html.window.open(detail!.photoLink!, '_blank'),
                          ),
                        ),
                      for (final file in detail!.attachments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(file.filename, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => html.window.open(file.url, '_blank'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  final fileId = file.id;
                                  if (fileId == null) return;
                                  final ok = await classService.deleteMockFile(fileId);
                                  if (!context.mounted) return;
                                  if (ok) {
                                    detail = await classService.fetchMockResult(result.resultId);
                                    setDialogState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final update = await classService.updateMockResult(
                resultId: result.resultId,
                submitted: submitted,
                verbalPoints: int.tryParse(verbalController.text.trim()),
                mathPoints: int.tryParse(mathController.text.trim()),
                verbalIncorrect: int.tryParse(
                  verbalIncorrectController.text.trim(),
                ),
                mathIncorrect: int.tryParse(
                  mathIncorrectController.text.trim(),
                ),
                weakAreas: weakAreasController.text.trim(),
              );
              if (!context.mounted) return;
              Navigator.of(dialogContext).pop();
              _showResultSnack(context, update);
              if (update['success'] == true) onChanged();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void _showClassTableDialog({
  required BuildContext context,
  required ClassFullDetailInfo detail,
  required List<UserInfo> users,
  required ClassService classService,
  required String currentUserRole,
  required VoidCallback onChanged,
  required _ClassTableCategory category,
}) {
  final title = '${detail.className} - ${_categoryTitle(category)}';
  final Future<_ClassResultBundle>? resultFuture = switch (category) {
    _ClassTableCategory.homeworkResults =>
      classService
          .fetchHomeworkResultsByClass(detail.classId)
          .then(
            (homeworkResults) => _ClassResultBundle(
              homeworkResults: homeworkResults,
              mockResults: const [],
            ),
          ),
    _ClassTableCategory.mockResults =>
      classService
          .fetchMockResultsByClass(detail.classId)
          .then(
            (mockResults) => _ClassResultBundle(
              homeworkResults: const [],
              mockResults: mockResults,
            ),
          ),
    _ => null,
  };

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 920,
        height: 480,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: resultFuture == null
                    ? _classCategoryTable(
                        context: context,
                        detail: detail,
                        users: users,
                        results: const _ClassResultBundle(
                          homeworkResults: [],
                          mockResults: [],
                        ),
                        classService: classService,
                        currentUserRole: currentUserRole,
                        onChanged: onChanged,
                        category: category,
                      )
                    : FutureBuilder<_ClassResultBundle>(
                        future: resultFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 320,
                              height: 160,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _kPrimary,
                                ),
                              ),
                            );
                          }
                          if (snap.hasError) {
                            return SizedBox(
                              width: 420,
                              child: _EmptyPanel(
                                message:
                                    'Could not load ${_categoryTitle(category).toLowerCase()}: ${snap.error}',
                              ),
                            );
                          }
                          return _classCategoryTable(
                            context: context,
                            detail: detail,
                            users: users,
                            results: snap.data!,
                            classService: classService,
                            currentUserRole: currentUserRole,
                            onChanged: onChanged,
                            category: category,
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _RoundLabeledAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _RoundLabeledAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kPrimary.withOpacity(0.45)),
              ),
              child: Icon(icon, size: 16, color: _kPrimary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _classCategoryTable({
  required BuildContext context,
  required ClassFullDetailInfo detail,
  required List<UserInfo> users,
  required _ClassResultBundle results,
  required ClassService classService,
  required String currentUserRole,
  required VoidCallback onChanged,
  required _ClassTableCategory category,
}) {
  final isAdmin = currentUserRole.toLowerCase() == 'admin';
  switch (category) {
    case _ClassTableCategory.students:
      return DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
        ],
        rows: detail.students
            .map(
              (student) => DataRow(
                cells: [
                  DataCell(Text(student.fullName)),
                  DataCell(Text(student.email ?? '-')),
                  DataCell(
                    Text(student.role.isEmpty ? 'student' : student.role),
                  ),
                ],
              ),
            )
            .toList(),
      );
    case _ClassTableCategory.sessions:
      return DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Teacher')),
          DataColumn(label: Text('Topic')),
        ],
        rows: detail.sessions
            .map(
              (session) => DataRow(
                cells: [
                  DataCell(Text(session.date)),
                  DataCell(
                    Text(_timeRange(session.startTime, session.endTime)),
                  ),
                  DataCell(Text(session.sessionType)),
                  DataCell(
                    Text(_teacherName(detail, users, session.teacherId)),
                  ),
                  DataCell(Text(session.topic ?? '-')),
                ],
              ),
            )
            .toList(),
      );
    case _ClassTableCategory.homeworks:
      return DataTable(
        columns: const [
          DataColumn(label: Text('Session date')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Slot')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Due')),
          DataColumn(label: Text('Photo')),
        ],
        rows: detail.assignments
            .map(
              (assignment) => DataRow(
                cells: [
                  DataCell(Text(_assignmentSessionDate(detail, assignment))),
                  DataCell(
                    Text(_studentName(detail, users, assignment.studentId)),
                  ),
                  DataCell(Text(assignment.slotIndex?.toString() ?? '-')),
                  DataCell(Text(assignment.title ?? '-')),
                  DataCell(Text(_dueText(assignment))),
                  DataCell(Text(assignment.photoRequired ? 'Yes' : 'No')),
                ],
              ),
            )
            .toList(),
      );
    case _ClassTableCategory.homeworkResults:
      return DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Actions')),
          DataColumn(label: Text('Session date')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Version')),
          DataColumn(label: Text('Submitted')),
          DataColumn(label: Text('Correct')),
          DataColumn(label: Text('Incorrect')),
          DataColumn(label: Text('Accuracy')),
        ],
        rows: results.homeworkResults
            .map(
              (result) => DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundLabeledAction(
                          icon: Icons.folder_open_rounded,
                          label: 'Files',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HomeworkResultDetailScreen(
                                  resultId: result.resultId,
                                  historyId: result.historyId,
                                  studentName: _studentName(
                                    detail,
                                    users,
                                    result.studentId,
                                  ),
                                  sessionLabel: _resultAssignmentDate(
                                    detail,
                                    result.assignmentId,
                                  ),
                                  isAdmin: isAdmin,
                                ),
                              ),
                            );
                          },
                        ),
                        if (!result.isHistorical) ...[
                          const SizedBox(width: 10),
                          _RoundLabeledAction(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            onPressed: () => _showHomeworkResultEditDialog(
                              context: context,
                              result: result,
                              classService: classService,
                              onChanged: onChanged,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  DataCell(
                    Text(_resultAssignmentDate(detail, result.assignmentId)),
                  ),
                  DataCell(Text(_studentName(detail, users, result.studentId))),
                  DataCell(
                    Text(result.isHistorical ? 'Previous' : 'Current'),
                  ),
                  DataCell(Text(result.submitted ? 'Yes' : 'No')),
                  DataCell(Text(result.correctTotal?.toString() ?? '-')),
                  DataCell(Text(result.incorrectTotal?.toString() ?? '-')),
                  DataCell(
                    Text(
                      result.accuracy == null
                          ? '-'
                          : '${result.accuracy!.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      );
    case _ClassTableCategory.mockResults:
      return DataTable(
        columns: const [
          DataColumn(label: Text('Session date')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Submitted')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Verbal')),
          DataColumn(label: Text('Math')),
          DataColumn(label: Text('Weak areas')),
          DataColumn(label: Text('Edit')),
        ],
        rows: results.mockResults
            .map(
              (result) => DataRow(
                cells: [
                  DataCell(
                    Text(_resultAssignmentDate(detail, result.assignmentId)),
                  ),
                  DataCell(Text(_studentName(detail, users, result.studentId))),
                  DataCell(Text(result.submitted ? 'Yes' : 'No')),
                  DataCell(
                    Text(
                      (result.totalPoints ??
                              ((result.verbalPoints ?? 0) +
                                  (result.mathPoints ?? 0)))
                          .toString(),
                    ),
                  ),
                  DataCell(Text(result.verbalPoints?.toString() ?? '-')),
                  DataCell(Text(result.mathPoints?.toString() ?? '-')),
                  DataCell(Text(result.weakAreas ?? '-')),
                  DataCell(
                    IconButton(
                      tooltip: 'Edit mock result',
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () => _showMockResultEditDialog(
                        context: context,
                        result: result,
                        classService: classService,
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      );
    case _ClassTableCategory.attendance:
      return DataTable(
        columns: const [
          DataColumn(label: Text('Session date')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Status')),
        ],
        rows: detail.attendance
            .map(
              (attendance) => DataRow(
                cells: [
                  DataCell(Text(_attendanceSessionDate(detail, attendance))),
                  DataCell(
                    Text(_studentName(detail, users, attendance.studentId)),
                  ),
                  DataCell(Text(attendance.status ? 'Present' : 'Absent')),
                ],
              ),
            )
            .toList(),
      );
  }
}

class _DialogField extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final String label;
  final bool obscureText;

  const _DialogField({
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

class _PhotoPickerPanel extends StatelessWidget {
  final String? photoLink;
  final String? selectedFileName;
  final VoidCallback onPick;
  final VoidCallback? onOpen;

  const _PhotoPickerPanel({
    required this.photoLink,
    required this.selectedFileName,
    required this.onPick,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        (photoLink ?? '').isNotEmpty || (selectedFileName ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Icon(
            hasPhoto ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
            color: hasPhoto ? _kSuccess : _kPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedFileName ?? 'No screenshot attached',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kTextMid,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if ((photoLink ?? '').isNotEmpty) ...[
            IconButton(
              tooltip: 'Open screenshot',
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
          ],
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: Text(hasPhoto ? 'Change photo' : 'Add photo'),
          ),
        ],
      ),
    );
  }
}

Future<html.File?> _pickImageFile() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;
  input.click();
  await input.onChange.first;
  return input.files?.isNotEmpty == true ? input.files!.first : null;
}

void _showResultSnack(BuildContext context, Map<String, dynamic> result) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result['message']?.toString() ?? 'Done'),
      backgroundColor: result['success'] == true
          ? _kSuccess
          : const Color(0xFFC62828),
    ),
  );
}

String _categoryTitle(_ClassTableCategory category) {
  switch (category) {
    case _ClassTableCategory.students:
      return 'Students';
    case _ClassTableCategory.sessions:
      return 'Sessions';
    case _ClassTableCategory.homeworks:
      return 'Homeworks';
    case _ClassTableCategory.homeworkResults:
      return 'Homework results';
    case _ClassTableCategory.mockResults:
      return 'Mock results';
    case _ClassTableCategory.attendance:
      return 'Attendance';
  }
}

SessionInfo? _sessionForAssignment(
  ClassFullDetailInfo detail,
  AssignmentInfo assignment,
) {
  return detail.sessions
      .where((session) => session.sessionId == assignment.sessionId)
      .firstOrNull;
}

AssignmentInfo? _assignmentById(ClassFullDetailInfo detail, int assignmentId) {
  return detail.assignments
      .where((assignment) => assignment.assignmentId == assignmentId)
      .firstOrNull;
}

String _assignmentSessionDate(
  ClassFullDetailInfo detail,
  AssignmentInfo assignment,
) {
  return _sessionForAssignment(detail, assignment)?.date ?? '-';
}

String _resultAssignmentDate(ClassFullDetailInfo detail, int assignmentId) {
  final assignment = _assignmentById(detail, assignmentId);
  if (assignment == null) return '-';
  return _assignmentSessionDate(detail, assignment);
}

String _attendanceSessionDate(
  ClassFullDetailInfo detail,
  AttendanceInfo attendance,
) {
  return detail.sessions
          .where((session) => session.sessionId == attendance.sessionId)
          .firstOrNull
          ?.date ??
      '-';
}

String _studentName(
  ClassFullDetailInfo detail,
  List<UserInfo> users,
  int studentId,
) {
  final student =
      detail.students.where((user) => user.userId == studentId).firstOrNull ??
      users.where((user) => user.userId == studentId).firstOrNull;
  return student?.fullName.isNotEmpty == true
      ? student!.fullName
      : 'Unknown student';
}

String _teacherName(
  ClassFullDetailInfo detail,
  List<UserInfo> users,
  int? teacherId,
) {
  if (teacherId == null) return '-';
  if (detail.verbalTeacher?.userId == teacherId) {
    return detail.verbalTeacher!.fullName;
  }
  if (detail.mathTeacher?.userId == teacherId) {
    return detail.mathTeacher!.fullName;
  }
  final teacher = users.where((user) => user.userId == teacherId).firstOrNull;
  return teacher?.fullName.isNotEmpty == true ? teacher!.fullName : '-';
}

String _timeRange(String? start, String? end) {
  final compactStart = _compactTime(start);
  final compactEnd = _compactTime(end);
  if (compactStart.isEmpty && compactEnd.isEmpty) return '-';
  if (compactStart.isEmpty) return compactEnd;
  if (compactEnd.isEmpty) return compactStart;
  return '$compactStart - $compactEnd';
}

String _compactTime(String? value) {
  final text = (value ?? '').trim();
  return text.length >= 5 ? text.substring(0, 5) : text;
}

String _dueText(AssignmentInfo assignment) {
  final date = assignment.dueDate ?? '';
  final time = _compactTime(assignment.dueTime);
  if (date.isEmpty && time.isEmpty) return '-';
  return [date, time].where((part) => part.isNotEmpty).join(' ');
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kPrimary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTextLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 10), action!],
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _InfoChip({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: $value',
                style: const TextStyle(
                  color: _kTextMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.table_chart_rounded,
                  size: 13,
                  color: _kPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NamePill extends StatelessWidget {
  final String label;
  final String sublabel;

  const _NamePill({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.isEmpty ? 'Unnamed user' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kTextLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;

  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTextMid,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: _panelDecoration(),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _kTextLight,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ControlPanelError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ControlPanelError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, color: _kPrimary, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Could not load database overview',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextMid, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: _kBorder),
    boxShadow: const [
      BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}

String _nameOf(UserInfo? user) {
  final name = user?.fullName ?? '';
  return name.isEmpty ? '-' : name;
}

bool _canManageUsers(String role) {
  final normalized = role.toLowerCase();
  return normalized == 'admin' || normalized == 'mentor';
}

String _capitalize(String value) {
  if (value.isEmpty) return 'Unknown';
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return _kPrimary;
    case 'mentor':
      return _kMentor;
    case 'teacher':
      return _kSuccess;
    case 'student':
      return _kWarning;
    default:
      return _kTextMid;
  }
}

IconData _roleIcon(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return Icons.admin_panel_settings_rounded;
    case 'mentor':
      return Icons.manage_accounts_rounded;
    case 'teacher':
      return Icons.school_rounded;
    case 'student':
      return Icons.person_rounded;
    default:
      return Icons.badge_rounded;
  }
}
