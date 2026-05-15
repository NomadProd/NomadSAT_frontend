library class_detail;

import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Pages/academic_plan_page.dart';
import 'package:flutter_web/Pages/progress_history_page.dart';
import 'package:flutter_web/Widgets/turan_header.dart';

part '../Widgets/shared_widgets.dart';
part '../Sections/class_detail_header.dart';
part '../Widgets/session_widgets.dart';
part '../Sections/homework_section.dart';
part '../Sections/mock_section.dart';
part 'timetable_page.dart';

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Theme constants
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
const _kPrimary = Color(0xFF1A4AF0);
const _kPrimaryDark = Color(0xFF1A4AF0);
const _kBg = Color(0xFFF0F4FF);
const _kBorder = Color(0xFFD7E3FF);
const _kPanelBg = Color(0xFFF4F7FF);
const _kTextDark = Color(0xFF0D1B3E);
const _kTextMid = Color(0xFF4A5A7A);
const _kTextLight = Color(0xFF9AAAC6);
const _kSuccess = Color(0xFF1B873F);
const _kSuccessBg = Color(0xFFE8F5E9);
const _kError = Color(0xFFC62828);
const _kErrorBg = Color(0xFFFFEBEE);
const _kWarning = Color(0xFFBF6000);
const _kWarningBg = Color(0xFFFFF3E0);
const _kNeutral = Color(0xFF607D8B);
const _kNeutralBg = Color(0xFFF5F7FA);

const int _kMaxHomeworkSlots = 5;
const int _kMinHomeworkSlots = 1;
const String _kLogoAsset = 'assets/images/turan_sat_logo.jpg';

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Shared input decoration factory
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
InputDecoration _fieldDeco(String label, {String? hint, Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kPrimary, width: 1.5),
    ),
    filled: true,
    fillColor: _kPanelBg,
    labelStyle: const TextStyle(color: _kTextMid, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Utility functions
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
bool _isMockSession(SessionInfo s) => s.sessionType.toLowerCase() == 'mock';

bool _canOpenStudentProgress(UserInfo user) {
  final role = user.role.toLowerCase();
  return role == 'admin' || role == 'mentor' || role == 'teacher';
}

Color _sessionTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'verbal':
      return const Color(0xFF7B1FA2);
    case 'math':
      return const Color(0xFF00897B);
    case 'mock':
      return const Color(0xFFEF6C00);
    default:
      return _kNeutral;
  }
}

String _capitalize(String v) =>
    v.isEmpty ? v : v[0].toUpperCase() + v.substring(1).toLowerCase();

DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _parseDate(String v) {
  try {
    return DateTime.parse(v);
  } catch (_) {
    return DateTime.now();
  }
}

String _formatDateForApi(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _formatDateHuman(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _weekdayShort(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[d.weekday - 1];
}

String _shortMonth(int m) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[(m - 1).clamp(0, 11)];
}

String _compactTime(String? v) {
  if ((v ?? '').isEmpty) return '';
  return v!.trim().length >= 5 ? v.trim().substring(0, 5) : v.trim();
}

String? _timeForApi(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return null;
  return t.length == 5 ? '$t:00' : t;
}

String _formatTimeRange(String? s, String? e) {
  final cs = _compactTime(s), ce = _compactTime(e);
  if (cs.isEmpty && ce.isEmpty) return '-';
  if (cs.isNotEmpty && ce.isNotEmpty) return '$cs - $ce';
  return cs.isNotEmpty ? cs : ce;
}

DateTime _sessionDateTime(SessionInfo session) {
  final date = _parseDate(session.date);
  final time = _compactTime(session.startTime);
  var hour = 23, minute = 59;
  if (time.contains(':')) {
    final parts = time.split(':');
    hour = int.tryParse(parts[0]) ?? 23;
    minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 59 : 59;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

SessionInfo? _bestInitialSession(List<SessionInfo> sessions) {
  if (sessions.isEmpty) return null;

  final now = DateTime.now();
  final today = _normalizeDate(now);
  final todaySessions =
      sessions
          .where((s) => _normalizeDate(_parseDate(s.date)) == today)
          .toList()
        ..sort((a, b) => _sessionDateTime(a).compareTo(_sessionDateTime(b)));
  if (todaySessions.isNotEmpty) {
    return todaySessions
            .where((s) => !_sessionDateTime(s).isBefore(now))
            .firstOrNull ??
        todaySessions.last;
  }

  final upcoming =
      sessions.where((s) => _sessionDateTime(s).isAfter(now)).toList()
        ..sort((a, b) => _sessionDateTime(a).compareTo(_sessionDateTime(b)));
  if (upcoming.isNotEmpty) return upcoming.first;

  final previous = [...sessions]
    ..sort((a, b) => _sessionDateTime(b).compareTo(_sessionDateTime(a)));
  return previous.first;
}

bool _isDeadlinePassed(String? dueDate, String? dueTime) {
  if ((dueDate ?? '').isEmpty) return false;
  try {
    final date = _parseDate(dueDate!);
    final time = _compactTime(dueTime);
    int h = 23, min = 59;
    if (time.contains(':')) {
      final p = time.split(':');
      if (p.length >= 2) {
        h = int.tryParse(p[0]) ?? 23;
        min = int.tryParse(p[1]) ?? 59;
      }
    }
    return DateTime.now().isAfter(
      DateTime(date.year, date.month, date.day, h, min),
    );
  } catch (_) {
    return false;
  }
}

String _teacherLabel(
  SessionInfo s,
  UserInfo? verbal,
  UserInfo? math,
  List<UserInfo> teachers,
) {
  if (s.teacherId != null) {
    final t = teachers.where((x) => x.userId == s.teacherId).firstOrNull;
    if (t != null) return '${t.name} ${t.surname}'.trim();
  }
  switch (s.sessionType.toLowerCase()) {
    case 'verbal':
      if (verbal != null) return '${verbal.name} ${verbal.surname}'.trim();
    case 'math':
      if (math != null) return '${math.name} ${math.surname}'.trim();
    case 'mock':
      final t = s.teacherId == null
          ? null
          : teachers.where((x) => x.userId == s.teacherId).firstOrNull;
      if (t != null) return '${t.name} ${t.surname}'.trim();
      if (math != null) return '${math.name} ${math.surname}'.trim();
      if (verbal != null) return '${verbal.name} ${verbal.surname}'.trim();
  }
  return '-';
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Page data container
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _PageData {
  final UserInfo user;
  final ClassFullDetailInfo detail;
  final List<UserInfo> teachers;
  final List<SessionInfo> sessions;
  final Map<int, List<HomeworkResultInfo>> homeworkResultsByAssignment;
  final Map<int, List<MockResultInfo>> mockResultsByAssignment;

  const _PageData({
    required this.user,
    required this.detail,
    required this.teachers,
    required this.sessions,
    required this.homeworkResultsByAssignment,
    required this.mockResultsByAssignment,
  });

  _PageData copyWith({
    UserInfo? user,
    ClassFullDetailInfo? detail,
    List<UserInfo>? teachers,
    List<SessionInfo>? sessions,
    Map<int, List<HomeworkResultInfo>>? homeworkResultsByAssignment,
    Map<int, List<MockResultInfo>>? mockResultsByAssignment,
  }) => _PageData(
    user: user ?? this.user,
    detail: detail ?? this.detail,
    teachers: teachers ?? this.teachers,
    sessions: sessions ?? this.sessions,
    homeworkResultsByAssignment:
        homeworkResultsByAssignment ?? this.homeworkResultsByAssignment,
    mockResultsByAssignment:
        mockResultsByAssignment ?? this.mockResultsByAssignment,
  );
}

// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
// Dialog result models
// в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _AssignmentDialogResult {
  final String instruction, taskLink, dueDate, dueTime;
  final List<UserInfo> students;
  const _AssignmentDialogResult({
    required this.instruction,
    required this.taskLink,
    required this.dueDate,
    required this.dueTime,
    required this.students,
  });
}

class _EditSessionDialogResult {
  final String date, startTime, endTime, sessionType, topic;
  final int? teacherId;
  const _EditSessionDialogResult({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.sessionType,
    required this.teacherId,
    required this.topic,
  });
}

// =====================================================================
// ClassDetailPage
// =====================================================================
class ClassDetailPage extends StatefulWidget {
  final int classId;
  final String className;

  const ClassDetailPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  final ClassService classService = ClassService();
  final AuthService authService = AuthService();

  _PageData? _pageData;
  bool _loading = true;
  String? _error;

  int? _selectedSessionId;
  bool _savingAssignment = false;
  bool _savingAttendance = false;
  bool _savingSession = false;
  List<UserInfo> _allStudents = [];
  DateTime _sessionWeekAnchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  // в”Ђв”Ђв”Ђ Data loading в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _loadAll();
      if (!mounted) return;
      setState(() {
        _pageData = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<_PageData> _loadAll() async {
    final user = await authService.fetchMe();
    final detail = await classService.fetchClassFullDetail(widget.classId);

    final role = user.role.toLowerCase();
    final isAdmin = role == 'admin';
    final canManageClass = isAdmin || role == 'mentor';
    final canLoadDirectories = canManageClass;
    final teachersFuture = canLoadDirectories
        ? classService.fetchTeachers()
        : Future.value([
            if (detail.verbalTeacher != null) detail.verbalTeacher!,
            if (detail.mathTeacher != null &&
                detail.mathTeacher!.userId != detail.verbalTeacher?.userId)
              detail.mathTeacher!,
          ]);
    final studentsFuture = canLoadDirectories
        ? classService.fetchStudents()
        : Future.value(detail.students);

    final sessions = [...detail.sessions]
      ..sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));

    final homeworkResults = <int, List<HomeworkResultInfo>>{};
    final mockResults = <int, List<MockResultInfo>>{};
    final visibleAssignments = user.role == 'student'
        ? detail.assignments.where((a) => a.studentId == user.userId)
        : detail.assignments;

    await Future.wait(
      visibleAssignments.map((a) async {
        final s = sessions.where((x) => x.sessionId == a.sessionId).firstOrNull;
        if (s == null) return;
        if (_isMockSession(s)) {
          mockResults[a.assignmentId] = await classService
              .fetchMockResultsByAssignment(a.assignmentId);
        } else {
          homeworkResults[a.assignmentId] = await classService
              .fetchHomeworkResultsByAssignment(a.assignmentId);
        }
      }),
    );

    if (_selectedSessionId == null ||
        sessions.every((s) => s.sessionId != _selectedSessionId)) {
      _selectedSessionId = _bestInitialSession(sessions)?.sessionId;
    }
    final selectedSession = sessions
        .where((s) => s.sessionId == _selectedSessionId)
        .firstOrNull;
    if (selectedSession != null) {
      _sessionWeekAnchor = _parseDate(selectedSession.date);
    }

    _allStudents = await studentsFuture;

    return _PageData(
      user: user,
      detail: detail,
      teachers: await teachersFuture,
      sessions: sessions,
      homeworkResultsByAssignment: homeworkResults,
      mockResultsByAssignment: mockResults,
    );
  }

  Future<void> _reload() async {
    try {
      final data = await _loadAll();
      if (!mounted) return;
      setState(() {
        _pageData = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  // в”Ђв”Ђв”Ђ Navigation в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<void> _logout() async {
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _returnToClasses() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/classes');
    }
  }

  void _openTimetablePage() {
    final d = _pageData;
    if (d == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimetablePage(
          className: widget.className,
          sessions: d.sessions,
          verbalTeacher: d.detail.verbalTeacher,
          mathTeacher: d.detail.mathTeacher,
          teachers: d.teachers,
        ),
      ),
    );
  }

  void _openAcademicPlanPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AcademicPlanPage(
          classId: widget.classId,
          className: widget.className,
        ),
      ),
    );
  }

  // в”Ђв”Ђв”Ђ Assignment dialogs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<void> _openAssignmentDialog({
    required SessionInfo session,
    required UserInfo student,
    required int slotIndex,
    AssignmentInfo? assignment,
  }) async {
    final instr = TextEditingController(text: assignment?.instruction ?? '');
    final link = TextEditingController(text: assignment?.taskLink ?? '');
    final dDate = TextEditingController(text: assignment?.dueDate ?? '');
    final dTime = TextEditingController(
      text: _compactTime(assignment?.dueTime),
    );
    final selectedStudents = <UserInfo>[student];
    int? selectedStudentId;

    int? nextHomeworkSlotFor(UserInfo s) {
      final usedSlots =
          _studentAssignmentsForSession(
                sessionId: session.sessionId,
                studentId: s.userId,
              )
              .map((a) => a.slotIndex)
              .whereType<int>()
              .where((slot) => slot >= 1 && slot <= _kMaxHomeworkSlots)
              .toSet();
      for (var slot = 1; slot <= _kMaxHomeworkSlots; slot++) {
        if (!usedSlots.contains(slot)) return slot;
      }
      return null;
    }

    List<UserInfo> availableStudents() {
      final selectedIds = selectedStudents.map((s) => s.userId).toSet();
      final available =
          (_pageData?.detail.students ?? [])
              .where((s) => !selectedIds.contains(s.userId))
              .where((s) => nextHomeworkSlotFor(s) != null)
              .toList()
            ..sort((a, b) {
              final byName = a.fullName.toLowerCase().compareTo(
                b.fullName.toLowerCase(),
              );
              return byName != 0 ? byName : a.userId.compareTo(b.userId);
            });
      return available;
    }

    int? displayedHomeworkSlotFor(UserInfo s) {
      if (assignment != null && s.userId == student.userId) {
        return assignment.slotIndex ?? (slotIndex + 1);
      }
      return nextHomeworkSlotFor(s);
    }

    final result = await showDialog<_AssignmentDialogResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final available = assignment == null
              ? availableStudents()
              : <UserInfo>[];
          if (selectedStudentId != null &&
              !available.any((s) => s.userId == selectedStudentId)) {
            selectedStudentId = null;
          }

          return _DialogShell(
            icon: Icons.assignment_rounded,
            title: assignment == null
                ? 'Assign Homework ${slotIndex + 1}'
                : 'Edit Homework ${slotIndex + 1}',
            width: 560,
            content: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DlgLabel('Content'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: instr,
                      maxLines: 4,
                      decoration: _fieldDeco('Instruction'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: link,
                      decoration: _fieldDeco('Task link', hint: 'https://...'),
                    ),
                    const SizedBox(height: 20),
                    const _DlgLabel('Students'),
                    const SizedBox(height: 10),
                    if (assignment == null) ...[
                      DropdownButtonFormField<int>(
                        key: ValueKey(
                          selectedStudents.map((s) => s.userId).join(','),
                        ),
                        initialValue: selectedStudentId,
                        decoration: _fieldDeco('Add student'),
                        hint: const Text('Choose available student'),
                        items: available
                            .map(
                              (s) => DropdownMenuItem<int>(
                                value: s.userId,
                                child: Text(
                                  '${s.fullName}  - Homework ${nextHomeworkSlotFor(s)}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: available.isEmpty
                            ? null
                            : (v) {
                                if (v == null) return;
                                final selected = available
                                    .where((s) => s.userId == v)
                                    .firstOrNull;
                                if (selected == null) return;
                                setDlg(() {
                                  selectedStudents.add(selected);
                                  selectedStudentId = null;
                                });
                              },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (selectedStudents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kErrorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kError.withOpacity(0.25)),
                        ),
                        child: const Text(
                          'Choose at least one student.',
                          style: TextStyle(
                            color: _kError,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedStudents
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: _kPanelBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _kBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 360,
                                      ),
                                      child: Text(
                                        '${s.fullName} - Homework ${displayedHomeworkSlotFor(s) ?? _kMaxHomeworkSlots}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _kTextDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (assignment == null) ...[
                                      const SizedBox(width: 6),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () => setDlg(
                                          () => selectedStudents.removeWhere(
                                            (x) => x.userId == s.userId,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: _kError,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 20),
                    const _DlgLabel('Deadline'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: dDate,
                            readOnly: true,
                            decoration: _fieldDeco(
                              'Date',
                              hint: 'YYYY-MM-DD',
                              suffixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                              ),
                            ),
                            onTap: () async {
                              final init = dDate.text.isNotEmpty
                                  ? _parseDate(dDate.text)
                                  : _normalizeDate(
                                      DateTime.now().add(
                                        const Duration(days: 1),
                                      ),
                                    );
                              final p = await showDatePicker(
                                context: ctx,
                                initialDate: init,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2100),
                              );
                              if (p != null) {
                                setDlg(() => dDate.text = _formatDateForApi(p));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: dTime,
                            decoration: _fieldDeco('Time', hint: '18:30'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: selectedStudents.isEmpty
                    ? null
                    : () => Navigator.of(ctx).pop(
                        _AssignmentDialogResult(
                          instruction: instr.text.trim(),
                          taskLink: link.text.trim(),
                          dueDate: dDate.text.trim(),
                          dueTime: dTime.text.trim(),
                          students: List<UserInfo>.from(selectedStudents),
                        ),
                      ),
                child: Text(
                  assignment == null && selectedStudents.length > 1
                      ? 'Assign to ${selectedStudents.length}'
                      : 'Save',
                ),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) return;

    setState(() => _savingAssignment = true);
    try {
      if (assignment == null) {
        var created = 0;
        final failures = <String>[];
        for (final selectedStudent in result.students) {
          final nextSlot = nextHomeworkSlotFor(selectedStudent);
          if (nextSlot == null) {
            failures.add('${selectedStudent.fullName}: no homework slots left');
            continue;
          }
          final r = await classService.createAssignmentForStudent(
            sessionId: session.sessionId,
            studentId: selectedStudent.userId,
            slotIndex: nextSlot,
            title: 'Homework $nextSlot',
            instruction: result.instruction.isEmpty ? null : result.instruction,
            taskLink: result.taskLink.isEmpty ? null : result.taskLink,
            dueDate: result.dueDate.isEmpty ? null : result.dueDate,
            dueTime: _timeForApi(result.dueTime),
          );
          if (r['success'] == true) {
            created++;
          } else {
            failures.add(
              '${selectedStudent.fullName}: ${r['message'] ?? 'failed'}',
            );
          }
        }

        if (!mounted) return;
        final message = failures.isEmpty
            ? 'Homework assigned to $created student${created == 1 ? '' : 's'}'
            : 'Assigned to $created. ${failures.length} failed.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        if (created > 0) await _reload();
      } else {
        final r = await classService.updateAssignment(
          assignmentId: assignment.assignmentId,
          studentId: student.userId,
          slotIndex: assignment.slotIndex ?? (slotIndex + 1),
          title: assignment.title ?? 'Homework ${slotIndex + 1}',
          instruction: result.instruction.isEmpty ? null : result.instruction,
          taskLink: result.taskLink.isEmpty ? null : result.taskLink,
          dueDate: result.dueDate.isEmpty ? null : result.dueDate,
          dueTime: _timeForApi(result.dueTime),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(r['message'] ?? 'Done')));
        if (r['success'] == true) await _reload();
      }
    } finally {
      if (mounted) setState(() => _savingAssignment = false);
    }
  }

  // в”Ђв”Ђв”Ђ Delete assignment в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<void> _deleteAssignment({required AssignmentInfo assignment}) async {
    final role = _pageData?.user.role.toLowerCase();
    if (role != 'admin' && role != 'teacher') return;
    final ok = await _confirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete homework?',
      body:
          'This will permanently remove "${assignment.title ?? 'Homework'}" and cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;

    setState(() => _savingAssignment = true);
    try {
      final r = await classService.deleteAssignment(
        assignmentId: assignment.assignmentId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message'] ?? 'Homework deleted')),
      );
      if (r['success'] == true) await _reload();
    } finally {
      if (mounted) setState(() => _savingAssignment = false);
    }
  }

  // в”Ђв”Ђв”Ђ Session dialogs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<void> _openEditSessionDialog({
    required SessionInfo session,
    required List<UserInfo> teachers,
  }) async {
    final role = _pageData?.user.role.toLowerCase();
    if (role != 'admin' && role != 'mentor') return;
    final dateC = TextEditingController(text: session.date);
    final startC = TextEditingController(text: _compactTime(session.startTime));
    final endC = TextEditingController(text: _compactTime(session.endTime));
    final topicC = TextEditingController(text: session.topic ?? '');
    String sType = session.sessionType;
    int? tId =
        session.teacherId ??
        (teachers.isNotEmpty ? teachers.first.userId : null);

    final result = await showDialog<_EditSessionDialogResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _DialogShell(
          icon: Icons.edit_calendar_rounded,
          title: 'Edit Session',
          width: 520,
          content: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DlgLabel('Schedule'),
                const SizedBox(height: 10),
                TextField(
                  controller: dateC,
                  readOnly: true,
                  decoration: _fieldDeco(
                    'Date',
                    suffixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                    ),
                  ),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: _parseDate(dateC.text),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2100),
                    );
                    if (p != null)
                      setDlg(() => dateC.text = _formatDateForApi(p));
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startC,
                        decoration: _fieldDeco('Start time', hint: '10:00'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endC,
                        decoration: _fieldDeco('End time', hint: '11:30'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _DlgLabel('Details'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sType,
                  decoration: _fieldDeco('Session type'),
                  items: const [
                    DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
                    DropdownMenuItem(value: 'math', child: Text('Math')),
                    DropdownMenuItem(value: 'mock', child: Text('Mock')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlg(() => sType = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: tId,
                  decoration: _fieldDeco('Teacher'),
                  items: teachers
                      .map(
                        (t) => DropdownMenuItem<int>(
                          value: t.userId,
                          child: Text('${t.name} ${t.surname}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDlg(() => tId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicC,
                  maxLines: 3,
                  decoration: _fieldDeco('Topic'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(
                _EditSessionDialogResult(
                  date: dateC.text.trim(),
                  startTime: startC.text.trim(),
                  endTime: endC.text.trim(),
                  sessionType: sType,
                  teacherId: tId,
                  topic: topicC.text.trim(),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => _savingSession = true);
    try {
      final r = await classService.updateSession(
        sessionId: session.sessionId,
        date: result.date,
        startTime: result.startTime.isEmpty ? null : result.startTime,
        endTime: result.endTime.isEmpty ? null : result.endTime,
        sessionType: result.sessionType,
        teacherId: result.teacherId,
        topic: result.topic.isEmpty ? null : result.topic,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r['message'] ?? 'Updated')));
      if (r['success'] == true) await _reload();
    } finally {
      if (mounted) setState(() => _savingSession = false);
    }
  }

  Future<void> _openCreateSessionDialog() async {
    final d = _pageData;
    if (d == null) return;
    final role = d.user.role.toLowerCase();
    if (role != 'admin' && role != 'mentor') return;
    final dateC = TextEditingController();
    final startC = TextEditingController();
    final endC = TextEditingController();
    final topicC = TextEditingController();
    String sType = 'verbal';
    int? tId = d.detail.verbalTeacher?.userId ?? d.teachers.firstOrNull?.userId;

    final result = await showDialog<_EditSessionDialogResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _DialogShell(
          icon: Icons.add_circle_outline_rounded,
          title: 'Create Session',
          width: 520,
          content: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DlgLabel('Schedule'),
                const SizedBox(height: 10),
                TextField(
                  controller: dateC,
                  readOnly: true,
                  decoration: _fieldDeco(
                    'Date',
                    hint: 'YYYY-MM-DD',
                    suffixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                    ),
                  ),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2100),
                    );
                    if (p != null)
                      setDlg(() => dateC.text = _formatDateForApi(p));
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startC,
                        decoration: _fieldDeco('Start time', hint: '10:00'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endC,
                        decoration: _fieldDeco('End time', hint: '11:30'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _DlgLabel('Details'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sType,
                  decoration: _fieldDeco('Session type'),
                  items: const [
                    DropdownMenuItem(value: 'verbal', child: Text('Verbal')),
                    DropdownMenuItem(value: 'math', child: Text('Math')),
                    DropdownMenuItem(value: 'mock', child: Text('Mock')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlg(() => sType = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: tId,
                  decoration: _fieldDeco('Teacher'),
                  items: d.teachers
                      .map(
                        (t) => DropdownMenuItem<int>(
                          value: t.userId,
                          child: Text('${t.name} ${t.surname}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDlg(() => tId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicC,
                  maxLines: 3,
                  decoration: _fieldDeco('Topic'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(
                _EditSessionDialogResult(
                  date: dateC.text.trim(),
                  startTime: startC.text.trim(),
                  endTime: endC.text.trim(),
                  sessionType: sType,
                  teacherId: tId,
                  topic: topicC.text.trim(),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final r = await classService.createSession(
      classId: widget.classId,
      date: result.date,
      startTime: result.startTime.isEmpty ? null : result.startTime,
      endTime: result.endTime.isEmpty ? null : result.endTime,
      sessionType: result.sessionType,
      teacherId: result.teacherId,
      topic: result.topic.isEmpty ? null : result.topic,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(r['message'] ?? 'Session created')));
    if (r['success'] == true) await _reload();
  }

  Future<void> _openSessionsDialog() async {
    final d = _pageData;
    if (d == null) return;
    final role = d.user.role.toLowerCase();
    if (role != 'admin' && role != 'mentor') return;
    final canDelete = role == 'admin';
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Column(
            children: [
              _dlgHeader(Icons.calendar_month_rounded, 'Sessions'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _openCreateSessionDialog();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create session'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          itemCount: d.sessions.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _kBorder),
                          itemBuilder: (_, i) {
                            final s = d.sessions[i];
                            final teacher = _teacherLabel(
                              s,
                              d.detail.verbalTeacher,
                              d.detail.mathTeacher,
                              d.teachers,
                            );
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: _SessionTypeBadge(type: s.sessionType),
                              title: Text(
                                '${_formatDateHuman(_parseDate(s.date))}  -  ${_capitalize(s.sessionType)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${_formatTimeRange(s.startTime, s.endTime)}  -  $teacher'
                                '${(s.topic ?? '').isNotEmpty ? '  -  ${s.topic}' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextMid,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _IconTextButton(
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    onTap: () async {
                                      Navigator.of(ctx).pop();
                                      await _openEditSessionDialog(
                                        session: s,
                                        teachers: d.teachers,
                                      );
                                    },
                                  ),
                                  if (canDelete) ...[
                                    const SizedBox(width: 6),
                                    _IconTextButton(
                                      icon: Icons.delete_outline_rounded,
                                      label: 'Delete',
                                      color: _kError,
                                      onTap: () async {
                                        final ok = await _confirmDialog(
                                          ctx,
                                          icon: Icons.delete_outline_rounded,
                                          title: 'Delete session?',
                                          body:
                                              'Delete ${_formatDateHuman(_parseDate(s.date))} ${s.sessionType} session?',
                                          confirmLabel: 'Delete',
                                          danger: true,
                                        );
                                        if (!ok) return;
                                        final r = await classService
                                            .deleteSession(
                                              sessionId: s.sessionId,
                                            );
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              r['message'] ?? 'Session deleted',
                                            ),
                                          ),
                                        );
                                        if (r['success'] == true) {
                                          await _reload();
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStudentsDialog({required List<UserInfo> students}) async {
    final role = _pageData?.user.role.toLowerCase();
    if (role != 'admin' && role != 'mentor') return;
    final canRemove = role == 'admin';
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Column(
            children: [
              _dlgHeader(Icons.group_rounded, 'Students'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _openAddStudentDialog();
                          },
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Add student'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          itemCount: students.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _kBorder),
                          itemBuilder: (_, i) {
                            final st = students[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: _InitialsAvatar(
                                name: st.name,
                                surname: st.surname,
                                size: 40,
                                fontSize: 15,
                              ),
                              title: Text(
                                '${st.name} ${st.surname}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'ID: ${st.userId}',
                                style: const TextStyle(
                                  color: _kTextMid,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: canRemove
                                  ? _IconTextButton(
                                      icon: Icons.person_remove_rounded,
                                      label: 'Remove',
                                      color: _kError,
                                      onTap: () async {
                                        final ok = await _confirmDialog(
                                          ctx,
                                          icon: Icons.person_remove_rounded,
                                          title: 'Remove student',
                                          body:
                                              'Remove ${st.name} ${st.surname} from this class?',
                                          confirmLabel: 'Remove',
                                          danger: true,
                                        );
                                        if (!ok) return;
                                        final r = await classService
                                            .removeStudentFromClass(
                                              classId: widget.classId,
                                              studentId: st.userId,
                                            );
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              r['message'] ?? 'Student removed',
                                            ),
                                          ),
                                        );
                                        if (r['success'] == true) {
                                          await _reload();
                                        }
                                      },
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddStudentDialog() async {
    final role = _pageData?.user.role.toLowerCase();
    if (role != 'admin' && role != 'mentor') return;
    if (_allStudents.isEmpty) {
      try {
        _allStudents = await classService.fetchStudents();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load students: $e')));
        return;
      }
    }
    final currentIds = (_pageData?.detail.students ?? [])
        .map((e) => e.userId)
        .toSet();
    final available =
        _allStudents.where((s) => !currentIds.contains(s.userId)).toList()
          ..sort((a, b) {
            final n = '${a.name} ${a.surname}'.toLowerCase().compareTo(
              '${b.name} ${b.surname}'.toLowerCase(),
            );
            return n != 0 ? n : a.userId.compareTo(b.userId);
          });
    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available students to add')),
      );
      return;
    }
    int? selectedId = available.first.userId;
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _DialogShell(
          icon: Icons.person_add_rounded,
          title: 'Add Student',
          width: 460,
          content: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: DropdownButtonFormField<int>(
              value: selectedId,
              decoration: _fieldDeco('Select student'),
              items: available
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s.userId,
                      child: Text('${s.name} ${s.surname}  (ID: ${s.userId})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setDlg(() => selectedId = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(selectedId),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final r = await classService.assignStudentToClass(
      classId: widget.classId,
      studentId: result,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(r['message'] ?? 'Student added')));
    if (r['success'] == true) await _reload();
  }

  Future<bool> _confirmDialog(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String body,
    required String confirmLabel,
    bool danger = false,
  }) async =>
      await showDialog<bool>(
        context: ctx,
        builder: (ctx2) => _DialogShell(
          icon: icon,
          title: title,
          width: 400,
          content: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 15,
                color: _kTextMid,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx2).pop(false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: danger
                  ? FilledButton.styleFrom(backgroundColor: _kError)
                  : null,
              onPressed: () => Navigator.of(ctx2).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  // в”Ђв”Ђв”Ђ Attendance в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<void> _toggleAttendance({
    required int sessionId,
    required int studentId,
    required AttendanceInfo? current,
  }) async {
    final newStatus = current == null ? true : !current.status;
    setState(() => _savingAttendance = true);
    try {
      final r = await classService.upsertAttendance(
        sessionId: sessionId,
        studentId: studentId,
        status: newStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message'] ?? 'Attendance updated')),
      );
      if (r['success'] == true && _pageData != null) {
        final list = [..._pageData!.detail.attendance];
        final idx = list.indexWhere(
          (a) => a.sessionId == sessionId && a.studentId == studentId,
        );
        final updated = AttendanceInfo(
          attendanceId: current?.attendanceId ?? 0,
          sessionId: sessionId,
          studentId: studentId,
          status: newStatus,
        );
        if (idx >= 0)
          list[idx] = updated;
        else
          list.add(updated);
        setState(() {
          _pageData = _pageData!.copyWith(
            detail: _pageData!.detail.copyWith(attendance: list),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _savingAttendance = false);
    }
  }

  // в”Ђв”Ђв”Ђ Helpers в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  void _openLink(String? url) {
    if ((url ?? '').trim().isEmpty) return;
    html.window.open(url!.trim(), '_blank');
  }

  void _openStudentPage(UserInfo student) {
    final user = _pageData?.user;
    if (user == null || !_canOpenStudentProgress(user)) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProgressHistoryPage(student: student)),
    );
  }

  List<AssignmentInfo> _studentAssignmentsForSession({
    required int sessionId,
    required int studentId,
  }) {
    if (_pageData == null) return [];
    final session = _pageData!.sessions
        .where((s) => s.sessionId == sessionId)
        .firstOrNull;
    if (session == null) return [];
    late final List<AssignmentInfo> items;
    if (_isMockSession(session)) {
      items = _pageData!.detail.assignments
          .where((a) => a.sessionId == sessionId)
          .toList();
    } else {
      items = _pageData!.detail.assignments
          .where((a) => a.sessionId == sessionId && a.studentId == studentId)
          .toList();
    }
    items.sort((a, b) {
      final as_ = a.slotIndex ?? 999999, bs_ = b.slotIndex ?? 999999;
      if (as_ != bs_) return as_.compareTo(bs_);
      return a.assignmentId.compareTo(b.assignmentId);
    });
    return items;
  }

  // в”Ђв”Ђв”Ђ Build в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  @override
  Widget build(BuildContext context) {
    final data = _pageData;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(190),
        child: _DetailHeader(
          user: data?.user,
          onBack: _returnToClasses,
          onLogout: _logout,
          className: widget.className,
          onTimetable: _openTimetablePage,
          onAcademicPlan: _openAcademicPlanPage,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: _kError,
                    ),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadInitial,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : data == null || data.sessions.isEmpty
          ? const Center(child: Text('No sessions yet'))
          : _buildBody(data),
    );
  }

  Widget _buildBody(_PageData data) {
    final role = data.user.role.toLowerCase();
    final isAdmin = role == 'admin';
    final canDeleteHomework = isAdmin || role == 'teacher';
    final canManageClass = isAdmin || role == 'mentor';
    final canOpenStudentProgress = _canOpenStudentProgress(data.user);
    final selected = data.sessions.firstWhere(
      (s) => s.sessionId == _selectedSessionId,
      orElse: () => data.sessions.first,
    );
    final attendance = data.detail.attendance
        .where((a) => a.sessionId == selected.sessionId)
        .toList();

    return Column(
      children: [
        // FIX #1 - height bumped from 90 в†’ 108 to prevent badge overflow
        _WeeklySessionDateStrip(
          sessions: data.sessions,
          selectedSessionId: selected.sessionId,
          weekAnchor: _sessionWeekAnchor,
          onPreviousWeek: () => setState(
            () => _sessionWeekAnchor = _sessionWeekAnchor.subtract(
              const Duration(days: 7),
            ),
          ),
          onNextWeek: () => setState(
            () => _sessionWeekAnchor = _sessionWeekAnchor.add(
              const Duration(days: 7),
            ),
          ),
          onToday: () => setState(() => _sessionWeekAnchor = DateTime.now()),
          onSelect: (id) {
            final next = data.sessions
                .where((s) => s.sessionId == id)
                .firstOrNull;
            setState(() {
              _selectedSessionId = id;
              if (next != null) _sessionWeekAnchor = _parseDate(next.date);
            });
          },
        ),
        if (_savingAssignment || _savingAttendance || _savingSession)
          const LinearProgressIndicator(minHeight: 2, color: _kPrimary),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _SessionMetaCard(
                session: selected,
                verbalTeacher: data.detail.verbalTeacher,
                mathTeacher: data.detail.mathTeacher,
                teachers: data.teachers,
                canManageClass: canManageClass,
                onStudents: () =>
                    _openStudentsDialog(students: data.detail.students),
                onSessions: _openSessionsDialog,
              ),
              const SizedBox(height: 16),
              ...data.detail.students.map((student) {
                final att = attendance
                    .where((a) => a.studentId == student.userId)
                    .firstOrNull;
                final assignments = _studentAssignmentsForSession(
                  sessionId: selected.sessionId,
                  studentId: student.userId,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StudentSessionRow(
                    student: student,
                    session: selected,
                    attendance: att,
                    assignments: assignments,
                    homeworkResultsByAssignment:
                        data.homeworkResultsByAssignment,
                    mockResultsByAssignment: data.mockResultsByAssignment,
                    canOpenStudent: canOpenStudentProgress,
                    onOpenStudent: () => _openStudentPage(student),
                    onAssignHomework: (slotIndex, assignment) =>
                        _openAssignmentDialog(
                          session: selected,
                          student: student,
                          slotIndex: slotIndex,
                          assignment: assignment,
                        ),
                    onDeleteHomework: canDeleteHomework
                        ? (assignment) =>
                              _deleteAssignment(assignment: assignment)
                        : null,
                    onOpenLink: _openLink,
                    onToggleAttendance: () => _toggleAttendance(
                      sessionId: selected.sessionId,
                      studentId: student.userId,
                      current: att,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
