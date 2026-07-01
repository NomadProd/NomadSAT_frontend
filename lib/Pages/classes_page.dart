import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Pages/class_detail_page.dart';
import 'package:flutter_web/Pages/control_panel_page.dart';
import 'package:flutter_web/Widgets/turan_header.dart';

void _agentLog(
  String location,
  String message,
  Map<String, dynamic> data,
  String hypothesisId,
) {
  // #region agent log
  http
      .post(
        Uri.parse(
          'http://127.0.0.1:7698/ingest/65637874-c5bf-45fd-a1a7-6e90b8027bca',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Debug-Session-Id': '9ed305',
        },
        body: jsonEncode({
          'sessionId': '9ed305',
          'location': location,
          'message': message,
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'hypothesisId': hypothesisId,
        }),
      )
      .catchError((_) => http.Response('', 500));
  // #endregion
}

List<ClassInfo> _activeClasses(List<ClassInfo> all) {
  return all.where((c) => !c.archived).toList()
    ..sort((a, b) => a.className.compareTo(b.className));
}

List<ClassInfo> _archivedClasses(List<ClassInfo> all) {
  return all.where((c) => c.archived).toList()
    ..sort((a, b) => a.className.compareTo(b.className));
}

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  late Future<_PageData> _future;
  final ClassService classService = ClassService();
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_PageData> _loadAll() async {
    final classes = await classService.fetchClasses();
    final user = await authService.fetchMe();
    // #region agent log
    _agentLog(
      'classes_page.dart:_loadAll',
      'classes fetched',
      {
        'total': classes.length,
        'active': classes.where((c) => !c.archived).length,
        'archived': classes.where((c) => c.archived).length,
        'role': user.role,
      },
      'H1',
    );
    // #endregion
    return _PageData(classes: classes, user: user);
  }

  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _showCreateClassDialog() async {
    final outcome = await showDialog<_CreateClassOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateClassDialog(classService: classService),
    );

    if (!mounted || outcome == null || !outcome.created) return;

    setState(() => _future = _loadAll());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        backgroundColor: outcome.sessionCreated
            ? const Color(0xFF1A4AF0)
            : const Color(0xFFC62828),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: FutureBuilder<_PageData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A4AF0)),
            );
          }

          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: () => setState(() => _future = _loadAll()),
            );
          }

          final data = snap.data!;
          final role = data.user.role.toLowerCase();
          final isAdmin = role == 'admin' || role == 'mentor';
          final showArchivedSections = role == 'admin';

          return Column(
            children: [
              _Header(user: data.user, onLogout: _logout),
              Expanded(
                child: _ClassesContent(
                  classes: data.classes,
                  showArchivedSections: showArchivedSections,
                  canCreateClass: isAdmin,
                  onCreateClass: _showCreateClassDialog,
                  canOpenControlPanel: isAdmin,
                  onOpenControlPanel: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ControlPanelPage(),
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

class _PageData {
  final List<ClassInfo> classes;
  final UserInfo user;

  const _PageData({required this.classes, required this.user});
}

class _Header extends StatelessWidget {
  final UserInfo user;
  final VoidCallback onLogout;

  const _Header({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) => TuranHeader(
    user: user,
    title: 'Classes',
    subtitle: 'Manage classes, teachers, students, and course setup.',
    pageLabel: 'Classes',
    onLogout: onLogout,
  );
}

class _ClassesContent extends StatelessWidget {
  final List<ClassInfo> classes;
  final bool showArchivedSections;
  final bool canCreateClass;
  final VoidCallback onCreateClass;
  final bool canOpenControlPanel;
  final VoidCallback onOpenControlPanel;

  const _ClassesContent({
    required this.classes,
    required this.showArchivedSections,
    required this.canCreateClass,
    required this.onCreateClass,
    required this.canOpenControlPanel,
    required this.onOpenControlPanel,
  });

  @override
  Widget build(BuildContext context) {
    final actionButtons = [
      if (canOpenControlPanel)
        OutlinedButton.icon(
          onPressed: onOpenControlPanel,
          icon: const Icon(Icons.storage_rounded, size: 18),
          label: const Text('Data overview'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A4AF0),
            side: const BorderSide(color: Color(0xFF1A4AF0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      if (canCreateClass)
        ElevatedButton.icon(
          onPressed: onCreateClass,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create class'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A4AF0),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ClassesTitle(),
                        if (actionButtons.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: actionButtons,
                          ),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        const _ClassesTitle(),
                        const Spacer(),
                        for (var i = 0; i < actionButtons.length; i++) ...[
                          actionButtons[i],
                          if (i != actionButtons.length - 1)
                            const SizedBox(width: 10),
                        ],
                      ],
                    );
            },
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _ClassesBody(
              classes: classes,
              showArchivedSections: showArchivedSections,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassesSectionHeader extends StatelessWidget {
  final String title;

  const _ClassesSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.blue.shade100, height: 1),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  final String message;

  const _SectionEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue.shade300,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ClassesBody extends StatelessWidget {
  final List<ClassInfo> classes;
  final bool showArchivedSections;

  const _ClassesBody({
    required this.classes,
    required this.showArchivedSections,
  });

  @override
  Widget build(BuildContext context) {
    // #region agent log
    _agentLog(
      'classes_page.dart:_ClassesBody.build',
      'render branch',
      {
        'showArchivedSections': showArchivedSections,
        'total': classes.length,
        'active': classes.where((c) => !c.archived).length,
        'archived': classes.where((c) => c.archived).length,
      },
      'H2',
    );
    // #endregion

    if (classes.isEmpty) {
      return const _EmptyState();
    }

    if (!showArchivedSections) {
      final sorted = [...classes]
        ..sort((a, b) => a.className.compareTo(b.className));
      return _ClassGrid(classes: sorted);
    }

    final active = _activeClasses(classes);
    final archived = _archivedClasses(classes);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClassesSectionHeader(title: 'Active Classes (${active.length})'),
          if (active.isEmpty)
            const _SectionEmptyState(message: 'No active classes')
          else
            _ClassGrid(classes: active, shrinkWrap: true),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 24),
            _ClassesSectionHeader(
              title: 'Archived Classes (${archived.length})',
            ),
            _ClassGrid(classes: archived, shrinkWrap: true),
          ],
        ],
      ),
    );
  }
}

class _ClassesTitle extends StatelessWidget {
  const _ClassesTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Classes',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A4AF0),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _ClassGrid extends StatelessWidget {
  final List<ClassInfo> classes;
  final bool shrinkWrap;

  const _ClassGrid({required this.classes, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: classes.length,
      itemBuilder: (context, i) => _ClassTile(info: classes[i]),
    );
  }
}

class _CreateClassDialog extends StatefulWidget {
  final ClassService classService;

  const _CreateClassDialog({required this.classService});

  @override
  State<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<_CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  late Future<List<UserInfo>> _teachersFuture;
  int? _verbalTeacherId;
  int? _mathTeacherId;
  String _scheduleTemplate = 'intensive';
  bool _saving = false;
  String? _error;

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _teachersFuture = widget.classService.fetchTeachers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.classService.createClass(
      name: _nameController.text.trim(),
      verbalTeacherId: _verbalTeacherId,
      mathTeacherId: _mathTeacherId,
      scheduleTemplate: _scheduleTemplate,
      startDate: _startDateController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final sessionsCreated = result['sessions_created'] ?? 0;
      Navigator.of(context).pop(
        _CreateClassOutcome(
          created: true,
          sessionCreated: true,
          message: 'Class created with $sessionsCreated scheduled sessions.',
        ),
      );
      return;
    }

    setState(() {
      _saving = false;
      _error = result['message']?.toString() ?? 'Failed to create class';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1A4AF0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF1A4AF0)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Create class',
              style: TextStyle(
                color: Color(0xFF1A4AF0),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: FutureBuilder<List<UserInfo>>(
          future: _teachersFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A4AF0)),
                ),
              );
            }

            if (snap.hasError) {
              return _DialogMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load teachers',
                message: snap.error.toString(),
              );
            }

            final teachers = snap.data ?? [];
            if (teachers.isEmpty) {
              return const _DialogMessage(
                icon: Icons.person_off_rounded,
                title: 'No teachers found',
                message: 'Add at least one teacher before creating a class.',
              );
            }

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !_saving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Class name',
                        prefixIcon: Icon(Icons.class_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a class name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _TeacherDropdown(
                      label: 'Verbal teacher',
                      icon: Icons.menu_book_rounded,
                      value: _verbalTeacherId,
                      teachers: teachers,
                      enabled: !_saving,
                      onChanged: (value) {
                        setState(() => _verbalTeacherId = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    _TeacherDropdown(
                      label: 'Math teacher',
                      icon: Icons.calculate_rounded,
                      value: _mathTeacherId,
                      teachers: teachers,
                      enabled: !_saving,
                      onChanged: (value) {
                        setState(() => _mathTeacherId = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _scheduleTemplate,
                      decoration: const InputDecoration(
                        labelText: 'Schedule template',
                        prefixIcon: Icon(Icons.view_week_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'intensive',
                          child: Text('Intensive course'),
                        ),
                        DropdownMenuItem(
                          value: 'standard',
                          child: Text('Standard course'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _scheduleTemplate = value);
                            },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _startDateController,
                      enabled: !_saving,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Starting date',
                        prefixIcon: Icon(Icons.event_rounded),
                        suffixIcon: Icon(Icons.calendar_month_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Choose a starting date';
                        }
                        return null;
                      },
                      onTap: _saving
                          ? null
                          : () async {
                              final initial =
                                  DateTime.tryParse(
                                    _startDateController.text,
                                  ) ??
                                  DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDateController.text = _formatDate(
                                    picked,
                                  );
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    _TemplateSummary(template: _scheduleTemplate),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FutureBuilder<List<UserInfo>>(
          future: _teachersFuture,
          builder: (context, snap) {
            final canSubmit = snap.hasData && (snap.data?.isNotEmpty ?? false);
            return ElevatedButton.icon(
              onPressed: _saving || !canSubmit ? null : _createClass,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_saving ? 'Creating...' : 'Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4AF0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB7C9EF),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CreateClassOutcome {
  final bool created;
  final bool sessionCreated;
  final String message;

  const _CreateClassOutcome({
    required this.created,
    required this.sessionCreated,
    required this.message,
  });
}

class _TemplateSummary extends StatelessWidget {
  final String template;

  const _TemplateSummary({required this.template});

  @override
  Widget build(BuildContext context) {
    final intensive = template == 'intensive';
    final lines = intensive
        ? const [
            'Mon verbal, Tue math, Wed verbal, Thu math, Fri verbal',
            'Sat and Sun mock block: 09:00-16:30',
            'Verbal/math lessons: 18:30-20:00',
            'Repeats for 4 weeks from the starting date',
          ]
        : const [
            'Mon verbal, Tue rest, Wed math, Thu rest, Fri verbal',
            'Sat mock block: 09:00-16:30, Sun rest',
            'Verbal/math lessons: 18:30-20:00',
            'Repeats for 8 weeks from the starting date',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            intensive
                ? 'Intensive course schedule'
                : 'Standard course schedule',
            style: const TextStyle(
              color: Color(0xFF1A4AF0),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('* ', style: TextStyle(color: Color(0xFF1A4AF0))),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF4A5A7A),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? value;
  final List<UserInfo> teachers;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  const _TeacherDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.teachers,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: teachers
          .map(
            (teacher) => DropdownMenuItem<int>(
              value: teacher.userId,
              child: Text(teacher.fullName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) {
        if (value == null) return 'Choose a $label';
        return null;
      },
    );
  }
}

class _DialogMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DialogMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue.shade200, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A4AF0),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7DB3), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;
  final Color color;

  const _LogoMark({required this.size, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(color: color),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.12, h * 0.55)
        ..lineTo(w * 0.50, h * 0.22)
        ..lineTo(w * 0.88, h * 0.55),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.28, h * 0.78)
        ..lineTo(w * 0.50, h * 0.58)
        ..lineTo(w * 0.72, h * 0.78),
      paint,
    );

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.9),
      w * 0.05,
      Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ClassTile extends StatefulWidget {
  final ClassInfo info;

  const _ClassTile({required this.info});

  @override
  State<_ClassTile> createState() => _ClassTileState();
}

class _ClassTileState extends State<_ClassTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _buildTeacherName(String? name, String? surname) {
    final parts = [
      name,
      surname,
    ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!).toList();

    return parts.isEmpty ? 'Not assigned' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = widget.info.archived;
    final cardColor = isArchived
        ? const Color(0xFF8B95A8)
        : const Color(0xFF1A4AF0);

    final verbalTeacher = _buildTeacherName(
      widget.info.verbalTeacherName,
      widget.info.verbalTeacherSurname,
    );

    final mathTeacher = _buildTeacherName(
      widget.info.mathTeacherName,
      widget.info.mathTeacherSurname,
    );

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassDetailPage(
              classId: widget.info.classId,
              className: widget.info.className,
            ),
          ),
        );
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(isArchived ? 0.18 : 0.32),
                blurRadius: isArchived ? 10 : 16,
                offset: Offset(0, isArchived ? 4 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isArchived)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    child: const Text(
                      'Archived',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: -18,
                right: -18,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -28,
                left: -16,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.info.className,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Verbal: $verbalTeacher',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.calculate_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Math: $mathTeacher',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, size: 64, color: Colors.blue.shade200),
          const SizedBox(height: 16),
          Text(
            'No classes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Classes will appear here once added.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7DB3)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              'Could not load classes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7DB3)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4AF0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
