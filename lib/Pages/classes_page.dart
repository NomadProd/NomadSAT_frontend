import 'package:flutter/material.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Pages/class_detail_page.dart';
import 'package:flutter_web/Pages/control_panel_page.dart';
import 'package:flutter_web/Widgets/turan_header.dart';

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
  static const _kWeekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _kDefaultLessonTime = '18:30';
  static const _kDefaultMockTime = '09:00';
  static final _kTimePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _weeksController = TextEditingController(text: '4');
  late final List<_DayScheduleEntry> _verbalSchedule;
  late final List<_DayScheduleEntry> _mathSchedule;
  late final List<_DayScheduleEntry> _mockSchedule;
  late Future<List<UserInfo>> _teachersFuture;
  int? _verbalTeacherId;
  int? _mathTeacherId;
  bool _saving = false;
  String? _error;

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _verbalSchedule = List.generate(
      7,
      (_) => _DayScheduleEntry(time: _kDefaultLessonTime),
    );
    _mathSchedule = List.generate(
      7,
      (_) => _DayScheduleEntry(time: _kDefaultLessonTime),
    );
    _mockSchedule = List.generate(
      7,
      (_) => _DayScheduleEntry(time: _kDefaultMockTime),
    );
    _verbalSchedule[0].enabled = true;
    _verbalSchedule[2].enabled = true;
    _verbalSchedule[4].enabled = true;
    _mathSchedule[1].enabled = true;
    _mathSchedule[3].enabled = true;
    _mockSchedule[5].enabled = true;
    _mockSchedule[6].enabled = true;
    _teachersFuture = widget.classService.fetchTeachers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _weeksController.dispose();
    for (final day in _verbalSchedule) {
      day.dispose();
    }
    for (final day in _mathSchedule) {
      day.dispose();
    }
    for (final day in _mockSchedule) {
      day.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _buildSchedulePayload(
    List<_DayScheduleEntry> days,
  ) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      if (!day.enabled) continue;
      result.add({
        'day_of_week': i,
        'start_time': day.timeController.text.trim(),
      });
    }
    return result;
  }

  String? _validateWeeklySchedule() {
    final hasVerbal = _verbalSchedule.any((day) => day.enabled);
    final hasMath = _mathSchedule.any((day) => day.enabled);
    final hasMock = _mockSchedule.any((day) => day.enabled);
    if (!hasVerbal && !hasMath && !hasMock) {
      return 'Enable at least one verbal, math, or mock day';
    }

    for (var i = 0; i < _verbalSchedule.length; i++) {
      final day = _verbalSchedule[i];
      if (!day.enabled) continue;
      final time = day.timeController.text.trim();
      if (!_kTimePattern.hasMatch(time)) {
        return 'Verbal ${_kWeekdayLabels[i]}: use HH:MM (e.g. 18:30)';
      }
    }

    for (var i = 0; i < _mathSchedule.length; i++) {
      final day = _mathSchedule[i];
      if (!day.enabled) continue;
      final time = day.timeController.text.trim();
      if (!_kTimePattern.hasMatch(time)) {
        return 'Math ${_kWeekdayLabels[i]}: use HH:MM (e.g. 18:30)';
      }
    }

    for (var i = 0; i < _mockSchedule.length; i++) {
      final day = _mockSchedule[i];
      if (!day.enabled) continue;
      final time = day.timeController.text.trim();
      if (!_kTimePattern.hasMatch(time)) {
        return 'Mock ${_kWeekdayLabels[i]}: use HH:MM (e.g. 09:00)';
      }
    }

    return null;
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduleError = _validateWeeklySchedule();
    if (scheduleError != null) {
      setState(() => _error = scheduleError);
      return;
    }

    final weeks = int.tryParse(_weeksController.text.trim());
    if (weeks == null || weeks < 1 || weeks > 52) {
      setState(() => _error = 'Course length must be between 1 and 52 weeks');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.classService.createClass(
      name: _nameController.text.trim(),
      verbalTeacherId: _verbalTeacherId,
      mathTeacherId: _mathTeacherId,
      startDate: _startDateController.text.trim(),
      scheduleWeeks: weeks,
      verbalSchedule: _buildSchedulePayload(_verbalSchedule),
      mathSchedule: _buildSchedulePayload(_mathSchedule),
      mockSchedule: _buildSchedulePayload(_mockSchedule),
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
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 36, 10),
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
        width: 620,
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

            return Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 14),
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _weeksController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Course length (weeks)',
                        prefixIcon: Icon(Icons.date_range_rounded),
                        border: OutlineInputBorder(),
                        helperText: 'Schedule repeats weekly from the starting date',
                      ),
                      validator: (value) {
                        final weeks = int.tryParse(value?.trim() ?? '');
                        if (weeks == null || weeks < 1 || weeks > 52) {
                          return 'Enter a number from 1 to 52';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _WeeklyLessonSchedulePicker(
                      title: 'Verbal lessons',
                      icon: Icons.menu_book_rounded,
                      weekdayLabels: _kWeekdayLabels,
                      days: _verbalSchedule,
                      enabled: !_saving,
                      timeHint: _kDefaultLessonTime,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _WeeklyLessonSchedulePicker(
                      title: 'Math lessons',
                      icon: Icons.calculate_rounded,
                      weekdayLabels: _kWeekdayLabels,
                      days: _mathSchedule,
                      enabled: !_saving,
                      timeHint: _kDefaultLessonTime,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _WeeklyLessonSchedulePicker(
                      title: 'Mock tests',
                      icon: Icons.quiz_rounded,
                      weekdayLabels: _kWeekdayLabels,
                      days: _mockSchedule,
                      enabled: !_saving,
                      timeHint: _kDefaultMockTime,
                      helperText:
                          'Each mock block lasts 7.5 hours from the start time.',
                      onChanged: () => setState(() {}),
                    ),
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

class _DayScheduleEntry {
  bool enabled;
  final TextEditingController timeController;

  _DayScheduleEntry({this.enabled = false, String time = '18:30'})
      : timeController = TextEditingController(text: time);

  void dispose() => timeController.dispose();
}

class _WeeklyLessonSchedulePicker extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> weekdayLabels;
  final List<_DayScheduleEntry> days;
  final bool enabled;
  final String timeHint;
  final String? helperText;
  final VoidCallback onChanged;

  const _WeeklyLessonSchedulePicker({
    required this.title,
    required this.icon,
    required this.weekdayLabels,
    required this.days,
    required this.enabled,
    this.timeHint = '18:30',
    this.helperText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1A4AF0)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1A4AF0),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          helperText ??
              'Tap a day to enable it, then set the start time (HH:MM).',
          style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(days.length, (index) {
            final day = days[index];
            final label = weekdayLabels[index];
            return _WeekdayScheduleCell(
              label: label,
              enabled: enabled,
              active: day.enabled,
              timeController: day.timeController,
              timeHint: timeHint,
              onToggle: () {
                day.enabled = !day.enabled;
                onChanged();
              },
            );
          }),
        ),
      ],
    );
  }
}

class _WeekdayScheduleCell extends StatelessWidget {
  static const _cellWidth = 78.0;
  static const _cellHeight = 90.0;
  static const _timeAreaHeight = 40.0;

  final String label;
  final bool enabled;
  final bool active;
  final TextEditingController timeController;
  final String timeHint;
  final VoidCallback onToggle;

  const _WeekdayScheduleCell({
    required this.label,
    required this.enabled,
    required this.active,
    required this.timeController,
    this.timeHint = '18:30',
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = active
        ? const Color(0xFF1A4AF0)
        : const Color(0xFFD7E3FF);
    final bgColor = active ? const Color(0xFFF4F7FF) : Colors.white;

    return SizedBox(
      width: _cellWidth,
      height: _cellHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: enabled ? onToggle : null,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                width: double.infinity,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active
                          ? const Color(0xFF1A4AF0)
                          : const Color(0xFF8A97B5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: _timeAreaHeight,
              width: double.infinity,
              child: active
                  ? TextField(
                      controller: timeController,
                      enabled: enabled,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 10,
                        ),
                        hintText: timeHint,
                        hintStyle: const TextStyle(fontSize: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: const Color(0xFF1A4AF0).withOpacity(0.35),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          borderSide: BorderSide(color: Color(0xFF1A4AF0)),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: enabled ? onToggle : null,
                      borderRadius: BorderRadius.circular(6),
                      child: const Center(
                        child: Text(
                          '—',
                          style: TextStyle(
                            color: Color(0xFFB8C4DE),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
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
