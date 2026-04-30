import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Pages/academic_plan_page.dart';
import 'package:flutter_web/Pages/class_detail_page.dart';
import 'package:flutter_web/Pages/homework_detail_page.dart';
import 'package:flutter_web/Pages/mock_result_detail_page.dart';
import 'package:flutter_web/Pages/homework_page.dart';
import 'package:flutter_web/Pages/progress_history_page.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/app_route_observer.dart';
import 'package:flutter_web/Widgets/auth_guard.dart';

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Palette РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
const _kPrimary = Color(0xFF1A4AF0);
const _kBg = Color(0xFFF0F4FF);
const _kBorder = Color(0xFFD7E3FF);
const _kPanelBg = Color(0xFFFAFBFF);
const _kTextDark = Color(0xFF0D1B3E);
const _kTextMid = Color(0xFF4A5A7A);
const _kTextLight = Color(0xFF9AAAC6);
const _kSuccess = Color(0xFF1B873F);
const _kError = Color(0xFFC62828);
const _kErrorBg = Color(0xFFFFEBEE);
const _kWarning = Color(0xFFBF6000);
const _kWarningBg = Color(0xFFFFF3E0);

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Page РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final _authService = AuthService();
  final _classService = ClassService();

  late Future<_StudentHomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHome();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshHome();
  }

  void _refreshHome() {
    if (!mounted) return;
    setState(() {
      _future = _loadHome();
    });
  }

  Future<_StudentHomeData> _loadHome() async {
    final user = await _authService.fetchMe();
    final classes = await _classService.fetchClasses();
    final classHomes = <_StudentClassHome>[];

    for (final classInfo in classes) {
      final detail = await _classService.fetchClassFullDetail(
        classInfo.classId,
      );

      final sessions = [...detail.sessions]
        ..sort((a, b) => _parseDate(a.date).compareTo(_parseDate(b.date)));

      final homeworkResultsByAssignment = <int, List<HomeworkResultInfo>>{};
      final mockResultsByAssignment = <int, List<MockResultInfo>>{};

      for (final assignment in detail.assignments) {
        final session = _sessionForAssignment(sessions, assignment);
        if (session == null) continue;

        if (_isMockSession(session)) {
          mockResultsByAssignment[assignment.assignmentId] = await _classService
              .fetchMockResultsByAssignment(assignment.assignmentId);
        } else {
          homeworkResultsByAssignment[assignment.assignmentId] =
              await _classService.fetchHomeworkResultsByAssignment(
                assignment.assignmentId,
              );
        }
      }

      classHomes.add(
        _StudentClassHome(
          classInfo: classInfo,
          detail: detail,
          sessions: sessions,
          homeworkResultsByAssignment: homeworkResultsByAssignment,
          mockResultsByAssignment: mockResultsByAssignment,
        ),
      );
    }

    final enrolledClassHome = classHomes
        .where(
          (classHome) =>
              classHome.detail.students.any((s) => s.userId == user.userId) ||
              classHome.detail.assignments.any(
                (a) => a.studentId == user.userId,
              ),
        )
        .firstOrNull;

    return _StudentHomeData(
      user: user,
      academicPlanClass: enrolledClassHome?.classInfo,
      timetableClass: enrolledClassHome,
      dueHomework: _buildDueHomework(classHomes),
      nextClass: _buildNextClass(classHomes),
      progress: _buildProgress(classHomes),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  List<_DueHomeworkItem> _buildDueHomework(List<_StudentClassHome> classes) {
    final items = <_DueHomeworkItem>[];
    for (final classHome in classes) {
      for (final assignment in classHome.detail.assignments) {
        final session = _sessionForAssignment(classHome.sessions, assignment);
        if (session == null) continue;

        if (_isMockSession(session)) {
          if (!_isMockSubmissionOpen(session)) continue;
          final result = classHome
              .mockResultsByAssignment[assignment.assignmentId]
              ?.where((r) => r.submitted)
              .firstOrNull;
          if (result != null) continue;
          items.add(
            _DueHomeworkItem(
              assignment: assignment,
              session: session,
              classInfo: classHome.classInfo,
              result: null,
              isLate: _isMockSubmissionLate(session),
              isMock: true,
            ),
          );
          continue;
        }

        final result = classHome
            .homeworkResultsByAssignment[assignment.assignmentId]
            ?.where((r) => r.submitted)
            .firstOrNull;
        if (result != null) continue;
        items.add(
          _DueHomeworkItem(
            assignment: assignment,
            session: session,
            classInfo: classHome.classInfo,
            result: result,
            isLate: _isDeadlinePassed(assignment.dueDate, assignment.dueTime),
            isMock: false,
          ),
        );
      }
    }
    items.sort((a, b) {
      if (a.isLate != b.isLate) return a.isLate ? -1 : 1;
      return _deadlineFor(a.assignment).compareTo(_deadlineFor(b.assignment));
    });
    return items;
  }

  _NextClassInfo? _buildNextClass(List<_StudentClassHome> classes) {
    final upcoming = <_NextClassInfo>[];
    final now = DateTime.now();
    for (final classHome in classes) {
      for (final session in classHome.sessions) {
        final startsAt = _sessionDateTime(session);
        if (startsAt.isBefore(now)) continue;
        upcoming.add(
          _NextClassInfo(
            classInfo: classHome.classInfo,
            session: session,
            teacherName: _teacherNameForSession(classHome.detail, session),
          ),
        );
      }
    }
    if (upcoming.isEmpty) return null;
    upcoming.sort(
      (a, b) =>
          _sessionDateTime(a.session).compareTo(_sessionDateTime(b.session)),
    );
    return upcoming.first;
  }

  _ProgressInfo _buildProgress(List<_StudentClassHome> classes) {
    final homework = <_HomeworkProgressItem>[];
    final mocks = <_MockProgressItem>[];

    for (final classHome in classes) {
      for (final entry in classHome.homeworkResultsByAssignment.entries) {
        final assignment = _assignmentById(
          classHome.detail.assignments,
          entry.key,
        );
        if (assignment == null) continue;
        final session = _sessionForAssignment(classHome.sessions, assignment);
        if (session == null) continue;
        for (final result in entry.value.where((r) => r.submitted)) {
          homework.add(
            _HomeworkProgressItem(
              classInfo: classHome.classInfo,
              session: session,
              assignment: assignment,
              result: result,
            ),
          );
        }
      }
      for (final entry in classHome.mockResultsByAssignment.entries) {
        final assignment = _assignmentById(
          classHome.detail.assignments,
          entry.key,
        );
        if (assignment == null) continue;
        final session = _sessionForAssignment(classHome.sessions, assignment);
        if (session == null) continue;
        for (final result in entry.value.where((r) => r.submitted)) {
          mocks.add(
            _MockProgressItem(
              classInfo: classHome.classInfo,
              session: session,
              result: result,
            ),
          );
        }
      }
    }

    homework.sort(
      (a, b) => _homeworkProgressDate(b).compareTo(_homeworkProgressDate(a)),
    );
    mocks.sort(
      (a, b) =>
          _sessionDateTime(b.session).compareTo(_sessionDateTime(a.session)),
    );

    return _ProgressInfo(
      latestHomework: homework.firstOrNull,
      previousHomework: homework.length > 1 ? homework[1] : null,
      latestMock: mocks.firstOrNull,
      previousMock: mocks.length > 1 ? mocks[1] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<_StudentHomeData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: _refreshHome,
            );
          }

          final data = snap.data;
          if (data == null) {
            return _ErrorState(
              message: 'Home data was empty. Please try again.',
              onRetry: _refreshHome,
            );
          }

          return Column(
            children: [
              _StudentHeader(user: data.user, onLogout: _logout),
              Expanded(
                child: Stack(
                  children: [
                    // Subtle bg pattern
                    Positioned.fill(child: _BgPattern()),
                    RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: () async {
                        final next = _loadHome();
                        setState(() => _future = next);
                        await next;
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                        children: [
                          _GreetingCard(user: data.user),
                          const SizedBox(height: 14),
                          _DashboardRow(
                            children: [
                              _DueNowSection(
                                items: data.dueHomework,
                                onSubmitted: _refreshHome,
                              ),
                              _NextClassSection(nextClass: data.nextClass),
                              _ProgressSection(
                                progress: data.progress,
                                onOpenHistory: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AuthGuard(
                                      requiredRoles: const ['student'],
                                      child: ProgressHistoryPage(
                                        student: data.user,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _QuickNav(
                            academicPlanClass: data.academicPlanClass,
                            timetableClass: data.timetableClass,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Header РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _StudentHeader extends StatelessWidget {
  final UserInfo user;
  final VoidCallback onLogout;

  const _StudentHeader({required this.user, required this.onLogout});

  String get _initials =>
      '${user.name.isNotEmpty ? user.name[0] : ''}'
              '${user.surname.isNotEmpty ? user.surname[0] : ''}'
          .toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kPrimary,
        boxShadow: [
          BoxShadow(
            color: Color(0x441A4AF0),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _BrandPattern(baseColor: Colors.white, opacity: 0.08),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${user.name} ${user.surname}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.role,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Logo + wordmark
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Image(
                            image: AssetImage('assets/brand/turan_symbol.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'TuranSAT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Logout
                  _CircleIconButton(
                    icon: Icons.logout_rounded,
                    onTap: onLogout,
                    tooltip: 'Log out',
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

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Greeting card РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _GreetingCard extends StatelessWidget {
  final UserInfo user;

  const _GreetingCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _BrandPattern(baseColor: Colors.white, opacity: 0.07),
            ),
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, ${user.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Here's what needs your attention.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Dashboard row РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _DashboardRow extends StatelessWidget {
  final List<Widget> children;

  const _DashboardRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  SizedBox(width: 270, child: children[i]),
                  if (i != children.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Due now РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _DueNowSection extends StatelessWidget {
  final List<_DueHomeworkItem> items;
  final VoidCallback onSubmitted;

  const _DueNowSection({required this.items, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList();
    final hiddenCount = items.length - visibleItems.length;

    return _HomeSection(
      title: 'Due now',
      icon: Icons.assignment_late_rounded,
      headerTrailing: _DueCountBadge(count: items.length),
      child: items.isEmpty
          ? const _EmptySectionMessage(
              icon: Icons.check_circle_rounded,
              message: 'All clear',
              color: _kSuccess,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < visibleItems.length; i++) ...[
                  _HomeworkTile(
                    item: visibleItems[i],
                    onSubmitted: onSubmitted,
                  ),
                  if (i != visibleItems.length - 1) const SizedBox(height: 8),
                ],
                if (hiddenCount > 0) ...[
                  const SizedBox(height: 10),
                  _MoreHomeworkHint(count: hiddenCount),
                ],
              ],
            ),
    );
  }
}

class _DueCountBadge extends StatelessWidget {
  final int count;

  const _DueCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final tone = count == 0 ? _kSuccess : (count > 3 ? _kError : _kWarning);
    final label = count == 1 ? '1 submission' : '$count submissions';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tone.withOpacity(0.14), tone.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tone,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

class _MoreHomeworkHint extends StatelessWidget {
  final int count;

  const _MoreHomeworkHint({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              color: _kPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? '1 more submission is waiting in your list.'
                  : '$count more submissions are waiting in your list.',
              style: const TextStyle(
                color: _kTextMid,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  final _DueHomeworkItem item;
  final VoidCallback onSubmitted;

  const _HomeworkTile({required this.item, required this.onSubmitted});

  Future<void> _openDetails(BuildContext context) async {
    if (item.isMock) {
      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AuthGuard(
            requiredRoles: const ['student'],
            child: MockResultDetailPage(
              title: _assignmentTitle(item.assignment, item.session),
              className: item.classInfo.className,
              deadline: _formatMockSubmissionLabel(item.session),
              sessionType: _capitalize(item.session.sessionType),
              assignment: item.assignment,
            ),
          ),
        ),
      );
      if (submitted == true) onSubmitted();
      return;
    }

    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AuthGuard(
          requiredRoles: const ['student'],
          child: HomeworkDetailPage(
            title: _assignmentTitle(item.assignment, item.session),
            className: item.classInfo.className,
            deadline: _formatDeadline(item.assignment),
            sessionType: _capitalize(item.session.sessionType),
            assignment: item.assignment,
            result: item.result,
          ),
        ),
      ),
    );
    if (submitted == true) onSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    final color = item.isLate
        ? _kError
        : item.isMock
        ? _sessionTypeColor(item.session.sessionType)
        : _kWarning;
    final title = _assignmentTitle(item.assignment, item.session);
    final deadline = item.isMock
        ? _formatMockSubmissionLabel(item.session)
        : _formatDeadline(item.assignment);
    final sessionLabel = _capitalize(item.session.sessionType);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetails(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.isLate
                      ? Icons.priority_high_rounded
                      : item.isMock
                      ? Icons.quiz_rounded
                      : Icons.assignment_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.classInfo.className,
                      style: const TextStyle(
                        color: _kTextMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniInfoChip(
                          icon: Icons.schedule_rounded,
                          label: deadline,
                          color: color,
                        ),
                        _MiniInfoChip(
                          icon: Icons.school_rounded,
                          label: sessionLabel,
                          color: _sessionTypeColor(item.session.sessionType),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: item.isLate
                    ? 'Late'
                    : item.isMock
                    ? 'Open'
                    : 'To do',
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Next class РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _NextClassSection extends StatelessWidget {
  final _NextClassInfo? nextClass;

  const _NextClassSection({required this.nextClass});

  @override
  Widget build(BuildContext context) {
    final next = nextClass;
    final sessionColor = next == null
        ? _kPrimary
        : _sessionTypeColor(next.session.sessionType);
    return _HomeSection(
      title: 'Next class',
      icon: Icons.event_available_rounded,
      child: next == null
          ? const _EmptySectionMessage(
              icon: Icons.event_busy_rounded,
              message: 'No upcoming classes',
              color: _kTextLight,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SessionBadge(type: next.session.sessionType),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_capitalize(next.session.sessionType)} - ${next.classInfo.className}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTextDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Up next',
                  style: TextStyle(
                    color: sessionColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 8),
                _NextClassDetailCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date & Time',
                  value:
                      '${_formatDateHuman(_parseDate(next.session.date))} - ${_formatTimeRange(next.session.startTime, next.session.endTime)}',
                  accentColor: _kPrimary,
                ),
                const SizedBox(height: 8),
                _NextClassDetailCard(
                  icon: Icons.person_rounded,
                  label: 'Teacher',
                  value: next.teacherName,
                  accentColor: const Color(0xFF00897B),
                ),
                if ((next.session.topic ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _NextClassDetailCard(
                    icon: Icons.topic_rounded,
                    label: 'Topic',
                    value: (next.session.topic ?? '').trim(),
                    accentColor: const Color(0xFF7B1FA2),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
    );
  }
}

class _NextClassDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final int maxLines;

  const _NextClassDetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Progress РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _ProgressSection extends StatelessWidget {
  final _ProgressInfo progress;
  final VoidCallback onOpenHistory;

  const _ProgressSection({required this.progress, required this.onOpenHistory});

  @override
  Widget build(BuildContext context) {
    final latestHomeworkAccuracy = progress.latestHomework?.result.accuracy;
    final latestMockPoints = progress.latestMock?.result.totalPoints;

    return _HomeSection(
      title: 'Progress',
      icon: Icons.trending_up_rounded,
      headerTrailing: _ProgressHistoryButton(onTap: onOpenHistory),
      child: Row(
        children: [
          Expanded(
            child: _ProgressStatCard(
              label: 'Submissions',
              icon: Icons.fact_check_rounded,
              accentColor: _kPrimary,
              value: latestHomeworkAccuracy == null
                  ? 'No score'
                  : '${latestHomeworkAccuracy.toStringAsFixed(1)}%',
              delta: _hwDelta(progress),
              unit: '%',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ProgressStatCard(
              label: 'Mock',
              icon: Icons.query_stats_rounded,
              accentColor: const Color(0xFFEF6C00),
              value: latestMockPoints == null
                  ? 'No score'
                  : '$latestMockPoints pt',
              delta: _mockDelta(progress),
              unit: 'pt',
            ),
          ),
        ],
      ),
    );
  }

  double? _hwDelta(_ProgressInfo p) {
    final a = p.latestHomework?.result.accuracy;
    final b = p.previousHomework?.result.accuracy;
    return (a != null && b != null) ? a - b : null;
  }

  double? _mockDelta(_ProgressInfo p) {
    final a = p.latestMock?.result.totalPoints;
    final b = p.previousMock?.result.totalPoints;
    return (a != null && b != null) ? (a - b).toDouble() : null;
  }
}

class _ProgressHistoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProgressHistoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open progress history',
      child: Material(
        color: _kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _kPrimary.withOpacity(0.14)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timeline_rounded, size: 13, color: _kPrimary),
                SizedBox(width: 5),
                Text(
                  'History',
                  style: TextStyle(
                    color: _kPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color accentColor;
  final double? delta;

  const _ProgressStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final deltaValue = delta;
    final hasDelta = deltaValue != null && deltaValue != 0;
    final isUp = (deltaValue ?? 0) > 0;
    final deltaColor = isUp ? _kSuccess : _kError;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 15),
              ),
              const Spacer(),
              if (hasDelta) ...[
                Icon(
                  isUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: deltaColor,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  '${isUp ? '+' : ''}${deltaValue.abs().toStringAsFixed(1)}',
                  style: TextStyle(
                    color: deltaColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _kTextLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Quick nav РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _QuickNav extends StatelessWidget {
  final ClassInfo? academicPlanClass;
  final _StudentClassHome? timetableClass;

  const _QuickNav({
    required this.academicPlanClass,
    required this.timetableClass,
  });

  void _openHomework(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const AuthGuard(requiredRoles: ['student'], child: HomeworkPage()),
      ),
    );
  }

  void _openAcademicPlan(BuildContext context) {
    final classInfo = academicPlanClass;
    if (classInfo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No enrolled class found.')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthGuard(
          requiredRoles: const ['student'],
          child: AcademicPlanPage(
            classId: classInfo.classId,
            className: classInfo.className,
          ),
        ),
      ),
    );
  }

  void _openTimetable(BuildContext context) {
    final classHome = timetableClass;
    if (classHome == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No class timetable found.')),
      );
      return;
    }
    if (classHome.sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No timetable sessions found.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthGuard(
          requiredRoles: const ['student'],
          child: TimetablePage(
            className: classHome.classInfo.className,
            sessions: classHome.sessions,
            verbalTeacher: classHome.detail.verbalTeacher,
            mathTeacher: classHome.detail.mathTeacher,
            teachers: _teachersForTimetable(classHome.detail),
          ),
        ),
      ),
    );
  }

  List<UserInfo> _teachersForTimetable(ClassFullDetailInfo detail) {
    final teachers = <UserInfo>[];
    final verbalTeacher = detail.verbalTeacher;
    final mathTeacher = detail.mathTeacher;
    if (verbalTeacher != null) teachers.add(verbalTeacher);
    if (mathTeacher != null && mathTeacher.userId != verbalTeacher?.userId) {
      teachers.add(mathTeacher);
    }
    return teachers;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NavButton(
            icon: Icons.assignment_rounded,
            label: 'Homework',
            onTap: () => _openHomework(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NavButton(
            icon: Icons.calendar_month_rounded,
            label: 'Calendar',
            onTap: () => _openTimetable(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NavButton(
            icon: Icons.route_rounded,
            label: 'Academic plan',
            onTap: () => _openAcademicPlan(context),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Homework detail placeholder РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _HomeworkDetailPlaceholderPage extends StatelessWidget {
  final _DueHomeworkItem item;

  const _HomeworkDetailPlaceholderPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final instruction = (item.assignment.instruction ?? '').trim();
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: const Text('Homework'),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 420,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _assignmentTitle(item.assignment, item.session),
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.classInfo.className,
                style: const TextStyle(color: _kTextMid, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: _kTextLight,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDeadline(item.assignment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextMid,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (instruction.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  instruction,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Shared section wrapper РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _HomeSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? headerTrailing;

  const _HomeSection({
    required this.title,
    required this.icon,
    required this.child,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kPrimary, size: 16),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              if (headerTrailing != null) headerTrailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Empty state РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _EmptySectionMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _EmptySectionMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Status pill РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Session badge РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _SessionBadge extends StatelessWidget {
  final String type;

  const _SessionBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _sessionTypeColor(type);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Center(
        child: Text(
          type.isNotEmpty ? type[0].toUpperCase() : '?',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Circle icon button РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool small;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 34.0 : 40.0;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: small ? 18 : 20),
          ),
        ),
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Logo mark РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
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
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.color != color;
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Brand pattern (repeating chevrons) РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _BrandPattern extends StatelessWidget {
  final Color baseColor;
  final double opacity;

  const _BrandPattern({required this.baseColor, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BrandPatternPainter(color: baseColor.withOpacity(opacity)),
    );
  }
}

class _BrandPatternPainter extends CustomPainter {
  final Color color;

  _BrandPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const step = 36.0;
    const cw = 18.0;
    const ch = 10.0;

    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        // Top chevron
        canvas.drawPath(
          Path()
            ..moveTo(x, y + ch * 0.7)
            ..lineTo(x + cw / 2, y)
            ..lineTo(x + cw, y + ch * 0.7),
          paint,
        );
        // Bottom chevron (smaller)
        canvas.drawPath(
          Path()
            ..moveTo(x + cw * 0.22, y + ch * 1.3)
            ..lineTo(x + cw / 2, y + ch * 0.85)
            ..lineTo(x + cw * 0.78, y + ch * 1.3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrandPatternPainter old) => old.color != color;
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Subtle bg pattern (dots) РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _BgPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotPatternPainter());
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kPrimary.withOpacity(0.055)
      ..style = PaintingStyle.fill;

    const spacing = 22.0;
    const radius = 1.5;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Error state РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Could not load',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextMid, fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Data models (unchanged) РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
class _StudentHomeData {
  final UserInfo user;
  final ClassInfo? academicPlanClass;
  final _StudentClassHome? timetableClass;
  final List<_DueHomeworkItem> dueHomework;
  final _NextClassInfo? nextClass;
  final _ProgressInfo progress;

  const _StudentHomeData({
    required this.user,
    required this.academicPlanClass,
    required this.timetableClass,
    required this.dueHomework,
    required this.nextClass,
    required this.progress,
  });
}

class _StudentClassHome {
  final ClassInfo classInfo;
  final ClassFullDetailInfo detail;
  final List<SessionInfo> sessions;
  final Map<int, List<HomeworkResultInfo>> homeworkResultsByAssignment;
  final Map<int, List<MockResultInfo>> mockResultsByAssignment;

  const _StudentClassHome({
    required this.classInfo,
    required this.detail,
    required this.sessions,
    required this.homeworkResultsByAssignment,
    required this.mockResultsByAssignment,
  });
}

class _DueHomeworkItem {
  final AssignmentInfo assignment;
  final SessionInfo session;
  final ClassInfo classInfo;
  final HomeworkResultInfo? result;
  final bool isLate;
  final bool isMock;

  const _DueHomeworkItem({
    required this.assignment,
    required this.session,
    required this.classInfo,
    required this.result,
    required this.isLate,
    required this.isMock,
  });
}

class _NextClassInfo {
  final ClassInfo classInfo;
  final SessionInfo session;
  final String teacherName;

  const _NextClassInfo({
    required this.classInfo,
    required this.session,
    required this.teacherName,
  });
}

class _ProgressInfo {
  final _HomeworkProgressItem? latestHomework;
  final _HomeworkProgressItem? previousHomework;
  final _MockProgressItem? latestMock;
  final _MockProgressItem? previousMock;

  const _ProgressInfo({
    required this.latestHomework,
    required this.previousHomework,
    required this.latestMock,
    required this.previousMock,
  });
}

class _HomeworkProgressItem {
  final ClassInfo classInfo;
  final SessionInfo session;
  final AssignmentInfo assignment;
  final HomeworkResultInfo result;

  const _HomeworkProgressItem({
    required this.classInfo,
    required this.session,
    required this.assignment,
    required this.result,
  });
}

class _MockProgressItem {
  final ClassInfo classInfo;
  final SessionInfo session;
  final MockResultInfo result;

  const _MockProgressItem({
    required this.classInfo,
    required this.session,
    required this.result,
  });
}

// РІвЂќР‚РІвЂќР‚РІвЂќР‚ Helpers (unchanged) РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚РІвЂќР‚
SessionInfo? _sessionForAssignment(
  List<SessionInfo> sessions,
  AssignmentInfo a,
) => sessions.where((s) => s.sessionId == a.sessionId).firstOrNull;

AssignmentInfo? _assignmentById(List<AssignmentInfo> list, int id) =>
    list.where((a) => a.assignmentId == id).firstOrNull;

bool _isMockSession(SessionInfo s) => s.sessionType.toLowerCase() == 'mock';

bool _isDeadlinePassed(String? dueDate, String? dueTime) {
  if ((dueDate ?? '').isEmpty) return false;
  return DateTime.now().isAfter(_deadlineFromParts(dueDate, dueTime));
}

bool _isMockSubmissionOpen(SessionInfo session) => !_normalizeDate(
  DateTime.now(),
).isBefore(_normalizeDate(_parseDate(session.date)));

bool _isMockSubmissionLate(SessionInfo session) => _normalizeDate(
  DateTime.now(),
).isAfter(_normalizeDate(_parseDate(session.date)));

DateTime _deadlineFor(AssignmentInfo a) =>
    _deadlineFromParts(a.dueDate, a.dueTime);

DateTime _deadlineFromParts(String? dueDate, String? dueTime) {
  final date = DateTime.tryParse(dueDate ?? '') ?? DateTime(2999);
  final time = _compactTime(dueTime);
  var hour = 23;
  var minute = 59;
  if (time.contains(':')) {
    final parts = time.split(':');
    hour = int.tryParse(parts[0]) ?? 23;
    minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 59 : 59;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

DateTime _sessionDateTime(SessionInfo session) {
  final date = _parseDate(session.date);
  final time = _compactTime(session.startTime);
  var hour = 23;
  var minute = 59;
  if (time.contains(':')) {
    final parts = time.split(':');
    hour = int.tryParse(parts[0]) ?? 23;
    minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 59 : 59;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

DateTime _homeworkProgressDate(_HomeworkProgressItem item) =>
    DateTime.tryParse(item.result.submittedAt ?? '') ??
    _deadlineFor(item.assignment);

DateTime _normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime _parseDate(String value) => DateTime.tryParse(value) ?? DateTime.now();

String _compactTime(String? value) {
  final text = (value ?? '').trim();
  return text.length >= 5 ? text.substring(0, 5) : text;
}

String _formatDateHuman(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]}';
}

String _formatTimeRange(String? start, String? end) {
  final s = _compactTime(start);
  final e = _compactTime(end);
  if (s.isEmpty && e.isEmpty) return 'Time TBD';
  if (s.isNotEmpty && e.isNotEmpty) return '$s - $e';
  return s.isNotEmpty ? s : e;
}

String _formatDeadline(AssignmentInfo a) {
  final dueDate = (a.dueDate ?? '').trim();
  if (dueDate.isEmpty) return 'No deadline';
  final date = _formatDateHuman(_parseDate(dueDate));
  final time = _compactTime(a.dueTime);
  return time.isEmpty ? 'Due $date' : 'Due $date at $time';
}

String _formatMockSubmissionLabel(SessionInfo session) {
  final date = _formatDateHuman(_parseDate(session.date));
  final time = _formatTimeRange(session.startTime, session.endTime);
  return time == 'Time TBD' ? 'Mock day $date' : 'Mock day $date - $time';
}

String _assignmentTitle(AssignmentInfo a, SessionInfo s) {
  final title = (a.title ?? '').trim();
  if (title.isNotEmpty) return title;
  if (_isMockSession(s)) return 'Mock submission';
  final slot = a.slotIndex == null ? '' : ' ${a.slotIndex! + 1}';
  return '${_capitalize(s.sessionType)} homework$slot';
}

String _teacherNameForSession(ClassFullDetailInfo detail, SessionInfo session) {
  switch (session.sessionType.toLowerCase()) {
    case 'verbal':
      return detail.verbalTeacher?.fullName ?? 'Not assigned';
    case 'math':
      return detail.mathTeacher?.fullName ?? 'Not assigned';
    default:
      return detail.mathTeacher?.fullName ??
          detail.verbalTeacher?.fullName ??
          'Not assigned';
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

Color _sessionTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'verbal':
      return const Color(0xFF7B1FA2);
    case 'math':
      return const Color(0xFF00897B);
    case 'mock':
      return const Color(0xFFEF6C00);
    default:
      return _kPrimary;
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}
