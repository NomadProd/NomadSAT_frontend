import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Pages/homework_detail_page.dart';
import 'package:flutter_web/Pages/mock_result_detail_page.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

const _kPrimary = TuranColors.primary;
const _kBg = TuranColors.bgAlt;
const _kSurface = TuranColors.surface;
const _kBorder = TuranColors.border;
const _kTextDark = TuranColors.textDark;
const _kTextMid = TuranColors.textMid;
const _kTextLight = TuranColors.textLight;
const _kSuccess = TuranColors.success;
const _kError = TuranColors.error;
const _kWarning = TuranColors.warning;
const _kMath = TuranColors.math;
const _kVerbal = TuranColors.verbal;

const _pageSize = 5; // completed homework per page

String _paginationRangeLabel(int page, int total) {
  if (total == 0) return 'Showing 0 of 0';
  final start = page * _pageSize + 1;
  final end = ((page + 1) * _pageSize).clamp(0, total);
  if (start >= end) return 'Showing $end of $total';
  return 'Showing $start–$end of $total';
}

// в”Ђв”Ђв”Ђ Page в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _classService = ClassService();

  late Future<_HomeworkPageData> _future;

  // Completed pagination
  int _todoPage = 0;
  int _completedPage = 0;

  // Header entrance animation
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _future = _loadHomework();

    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOutCubic));
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<_HomeworkPageData> _loadHomework() async {
    final user = await _authService.fetchMe();
    final classes = await _classService.fetchClasses();
    final items = <_HomeworkItem>[];

    for (final classInfo in classes) {
      final detail = await _classService.fetchClassFullDetail(
        classInfo.classId,
      );
      final sessionsById = {for (final s in detail.sessions) s.sessionId: s};

      for (final assignment in detail.assignments) {
        if (assignment.studentId != user.userId) continue;
        final session = sessionsById[assignment.sessionId];
        if (session == null) continue;

        HomeworkResultInfo? homeworkResult;
        MockResultInfo? mockResult;
        if (session.sessionType.toLowerCase() == 'mock') {
          final results = await _classService.fetchMockResultsByAssignment(
            assignment.assignmentId,
          );
          mockResult = results
              .where((r) => r.studentId == user.userId && r.submitted)
              .firstOrNull;
        } else {
          final results = await _classService.fetchHomeworkResultsByAssignment(
            assignment.assignmentId,
          );
          homeworkResult = results
              .where((r) => r.studentId == user.userId && r.submitted)
              .firstOrNull;
        }

        items.add(
          _HomeworkItem(
            classInfo: classInfo,
            session: session,
            assignment: assignment,
            result: homeworkResult,
            mockResult: mockResult,
          ),
        );
      }
    }

    final toDo =
        items.where((i) => !i.isCompleted && i.isSubmissionOpen).toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final completed = items.where((i) => i.isCompleted).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return _HomeworkPageData(user: user, toDo: toDo, completed: completed);
  }

  Future<void> _openDetails(_HomeworkItem item) async {
    if (item.isMock) {
      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MockResultDetailPage(
            title: item.title,
            className: item.classInfo.className,
            deadline: item.deadlineLabel,
            sessionType: _capitalize(item.session.sessionType),
            assignment: item.assignment,
            result: item.mockResult,
          ),
        ),
      );
      if (submitted == true && mounted) {
        setState(() {
          _future = _loadHomework();
          _todoPage = 0;
          _completedPage = 0;
        });
      }
      return;
    }

    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HomeworkDetailPage(
          title: item.title,
          className: item.classInfo.className,
          deadline: item.deadlineLabel,
          sessionType: _capitalize(item.session.sessionType),
          assignment: item.assignment,
          result: item.result,
        ),
      ),
    );
    if (submitted == true && mounted) {
      setState(() {
        _future = _loadHomework();
        _todoPage = 0;
        _completedPage = 0;
      });
    }
  }

  void _refresh() => setState(() {
    _future = _loadHomework();
    _todoPage = 0;
    _completedPage = 0;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<_HomeworkPageData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: _refresh,
            );
          }

          final data = snap.data!;
          return Column(
            children: [
              // в”Ђв”Ђ Animated header в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: _HomeworkHeader(user: data.user),
                ),
              ),

              // в”Ђв”Ђ Body в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: _SoftPattern()),
                    RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: () async {
                        final next = _loadHomework();
                        setState(() {
                          _future = next;
                          _todoPage = 0;
                          _completedPage = 0;
                        });
                        await next;
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                        children: [
                          // Stats row
                          _StatsRow(data: data),
                          const SizedBox(height: 20),

                          // Responsive two-column layout
                          _ResponsiveColumns(
                            toDo: data.toDo,
                            completed: data.completed,
                            todoPage: _todoPage,
                            completedPage: _completedPage,
                            onTodoPageChanged: (p) =>
                                setState(() => _todoPage = p),
                            onCompletedPageChanged: (p) =>
                                setState(() => _completedPage = p),
                            onOpenDetails: _openDetails,
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

// в”Ђв”Ђв”Ђ Loading в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        children: [
          // skeleton header
          Container(
            height: 160,
            decoration: const BoxDecoration(color: _kPrimary),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
                  SizedBox(height: 16),
                  Text(
                    'Loading homework...',
                    style: TextStyle(
                      color: _kTextMid,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

// в”Ђв”Ђв”Ђ Header в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _HomeworkHeader extends StatelessWidget {
  final UserInfo user;
  const _HomeworkHeader({required this.user});

  @override
  Widget build(BuildContext context) => TuranHeader(
    user: user,
    title: 'Submissions Dashboard',
    subtitle:
        'See homework and mock submissions, review completed work, and open details.',
    pageLabel: 'Submissions',
    onBack: () => Navigator.of(context).maybePop(),
  );
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: Colors.white.withOpacity(0.22)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Paints a subtle diagonal accent line across the header.
class _DiagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 60
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.85, size.height),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// в”Ђв”Ђв”Ђ Stats Row в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _StatsRow extends StatelessWidget {
  final _HomeworkPageData data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final lateCount = data.toDo.where((i) => i.isLate).length;
    final stats = [
      _StatItem(
        label: 'To Do',
        value: '${data.toDo.length}',
        icon: Icons.pending_actions_rounded,
        color: lateCount > 0 ? _kWarning : _kPrimary,
      ),
      _StatItem(
        label: 'Done',
        value: '${data.completed.length}',
        icon: Icons.task_alt_rounded,
        color: _kSuccess,
      ),
      _StatItem(
        label: 'Late',
        value: '$lateCount',
        icon: Icons.warning_amber_rounded,
        color: _kError,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(child: _StatCard(item: stats[i])),
          if (i < stats.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: item.color, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: TextStyle(
              color: item.color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: const TextStyle(
              color: _kTextLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Responsive Columns в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _ResponsiveColumns extends StatelessWidget {
  final List<_HomeworkItem> toDo;
  final List<_HomeworkItem> completed;
  final int todoPage;
  final int completedPage;
  final ValueChanged<int> onTodoPageChanged;
  final ValueChanged<int> onCompletedPageChanged;
  final ValueChanged<_HomeworkItem> onOpenDetails;

  const _ResponsiveColumns({
    required this.toDo,
    required this.completed,
    required this.todoPage,
    required this.completedPage,
    required this.onTodoPageChanged,
    required this.onCompletedPageChanged,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final todoCol = _TodoSection(
          items: toDo,
          currentPage: todoPage,
          onPageChanged: onTodoPageChanged,
          onOpenDetails: onOpenDetails,
        );
        final doneCol = _CompletedSection(
          items: completed,
          currentPage: completedPage,
          onPageChanged: onCompletedPageChanged,
          onOpenDetails: onOpenDetails,
        );

        if (constraints.maxWidth < 860) {
          return Column(
            children: [todoCol, const SizedBox(height: 16), doneCol],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: todoCol),
            const SizedBox(width: 16),
            Expanded(child: doneCol),
          ],
        );
      },
    );
  }
}

// в”Ђв”Ђв”Ђ To-Do Section в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _TodoSection extends StatelessWidget {
  final List<_HomeworkItem> items;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<_HomeworkItem> onOpenDetails;

  const _TodoSection({
    required this.items,
    required this.currentPage,
    required this.onPageChanged,
    required this.onOpenDetails,
  });

  int get _totalPages => (items.length / _pageSize).ceil().clamp(1, 9999);

  List<_HomeworkItem> get _visible {
    final start = currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'To Do',
      subtitle: 'Submissions waiting for you',
      icon: Icons.bolt_rounded,
      accent: _kWarning,
      count: items.length,
      child: items.isEmpty
          ? _EmptyState(
              icon: Icons.celebration_rounded,
              title: 'All caught up!',
              message: 'No pending submissions right now.',
              color: _kSuccess,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _visible.length; i++) ...[
                  _HomeworkCard(
                    item: _visible[i],
                    completed: false,
                    onTap: () => onOpenDetails(_visible[i]),
                  ),
                  if (i < _visible.length - 1) const SizedBox(height: 10),
                ],
                if (_totalPages > 1) ...[
                  const SizedBox(height: 16),
                  _PaginationBar(
                    current: currentPage,
                    total: _totalPages,
                    totalItems: items.length,
                    onPrev: currentPage > 0
                        ? () => onPageChanged(currentPage - 1)
                        : null,
                    onNext: currentPage < _totalPages - 1
                        ? () => onPageChanged(currentPage + 1)
                        : null,
                    onPageSelected: onPageChanged,
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _paginationRangeLabel(currentPage, items.length),
                    style: const TextStyle(
                      color: _kTextLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// в”Ђв”Ђв”Ђ Completed Section with Pagination в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _CompletedSection extends StatelessWidget {
  final List<_HomeworkItem> items;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<_HomeworkItem> onOpenDetails;

  const _CompletedSection({
    required this.items,
    required this.currentPage,
    required this.onPageChanged,
    required this.onOpenDetails,
  });

  int get _totalPages => (items.length / _pageSize).ceil().clamp(1, 9999);

  List<_HomeworkItem> get _visible {
    final start = currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Completed',
      subtitle: 'Submitted work & results',
      icon: Icons.workspace_premium_rounded,
      accent: _kSuccess,
      count: items.length,
      child: items.isEmpty
          ? _EmptyState(
              icon: Icons.history_rounded,
              title: 'No results yet',
              message: 'Completed submissions will appear here.',
              color: _kSuccess,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Visible cards
                for (var i = 0; i < _visible.length; i++) ...[
                  _HomeworkCard(
                    item: _visible[i],
                    completed: true,
                    onTap: () => onOpenDetails(_visible[i]),
                  ),
                  if (i < _visible.length - 1) const SizedBox(height: 10),
                ],

                if (_totalPages > 1) ...[
                  const SizedBox(height: 16),
                  _PaginationBar(
                    current: currentPage,
                    total: _totalPages,
                    totalItems: items.length,
                    onPrev: currentPage > 0
                        ? () => onPageChanged(currentPage - 1)
                        : null,
                    onNext: currentPage < _totalPages - 1
                        ? () => onPageChanged(currentPage + 1)
                        : null,
                    onPageSelected: onPageChanged,
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _paginationRangeLabel(currentPage, items.length),
                    style: const TextStyle(
                      color: _kTextLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// в”Ђв”Ђв”Ђ Pagination Bar в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _PaginationBar extends StatelessWidget {
  final int current;
  final int total;
  final int totalItems;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSelected;

  const _PaginationBar({
    required this.current,
    required this.total,
    required this.totalItems,
    required this.onPrev,
    required this.onNext,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _PagButton(
              label: 'Previous',
              icon: Icons.chevron_left_rounded,
              leading: true,
              onTap: onPrev,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == current;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onPageSelected(i),
                      borderRadius: BorderRadius.circular(TuranRadius.pill),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: AnimatedContainer(
                            duration: TuranMotion.normal,
                            width: active ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: active ? _kPrimary : _kBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            _PagButton(
              label: 'Next',
              icon: Icons.chevron_right_rounded,
              leading: false,
              onTap: onNext,
            ),
          ],
        ),
        if (total > 1) ...[
          const SizedBox(height: 8),
          Text(
            'Page ${current + 1} of $total',
            style: const TextStyle(
              color: _kTextLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _PagButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool leading;
  final VoidCallback? onTap;

  const _PagButton({
    required this.label,
    required this.icon,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: enabled ? _kPrimary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: leading
                ? [
                    Icon(
                      icon,
                      size: 17,
                      color: enabled ? _kPrimary : _kTextLight,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled ? _kPrimary : _kTextLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]
                : [
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled ? _kPrimary : _kTextLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      icon,
                      size: 17,
                      color: enabled ? _kPrimary : _kTextLight,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Section Shell в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final int count;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _kBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081A4AF0),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.18),
                      accent.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accent, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _kTextLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Count pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: accent.withOpacity(0.20), width: 1),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(color: _kBorder.withOpacity(0.7), height: 22),

          child,
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Homework Card в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _HomeworkCard extends StatelessWidget {
  final _HomeworkItem item;
  final bool completed;
  final VoidCallback onTap;

  const _HomeworkCard({
    required this.item,
    required this.completed,
    required this.onTap,
  });

  Color get _accentColor => completed
      ? _kSuccess
      : item.isLate
      ? _kError
      : item.subjectColor;

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;

    return Container(
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFFF6FFF9)
            : item.isLate
            ? _kError.withOpacity(0.04)
            : const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color bar
              Container(width: 5, color: color),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: badge + title + status pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject icon tile
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withOpacity(0.18),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                item.session.sessionType.isEmpty
                                    ? '?'
                                    : item.session.sessionType[0].toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _kTextDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.classInfo.className,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _kTextMid,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              completed
                                  ? 'Done'
                                  : item.isLate
                                  ? 'Late'
                                  : 'Open',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Date meta row
                      Row(
                        children: [
                          Icon(
                            completed
                                ? Icons.check_circle_outline_rounded
                                : Icons.schedule_rounded,
                            color: _kTextLight,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              completed
                                  ? item.completedLabel
                                  : item.deadlineLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kTextMid,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Instruction excerpt
                      if ((item.assignment.instruction ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.assignment.instruction!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kTextMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Bottom: result strip OR action button
                      if (completed && item.result != null)
                        _ResultStrip(result: item.result!)
                      else if (completed && item.isMock)
                        _MockResultStrip(item: item)
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    Color.lerp(color, Colors.black, 0.15)!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.30),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Open detail',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}

// в”Ђв”Ђв”Ђ Result Strip в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _ResultStrip extends StatelessWidget {
  final HomeworkResultInfo result;
  const _ResultStrip({required this.result});

  String get _total {
    final c = result.correctTotal, w = result.incorrectTotal;
    if (c == null && w == null) return '-';
    return '${(c ?? 0) + (w ?? 0)}';
  }

  String? get _acc => result.accuracy == null
      ? null
      : '${result.accuracy!.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSuccess.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          _Mini(label: 'Total', value: _total, color: _kTextDark),
          _Mini(
            label: 'Correct',
            value: '${result.correctTotal ?? '-'}',
            color: _kSuccess,
          ),
          _Mini(
            label: 'Wrong',
            value: '${result.incorrectTotal ?? '-'}',
            color: _kError,
          ),
          _Mini(label: 'Accuracy', value: _acc ?? '-', color: _kPrimary),
        ],
      ),
    );
  }
}

class _MockResultStrip extends StatelessWidget {
  final _HomeworkItem item;

  const _MockResultStrip({required this.item});

  @override
  Widget build(BuildContext context) {
    final result = item.mockResult;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.subjectColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          _Mini(
            label: 'Total',
            value: '${result?.totalPoints ?? '-'}',
            color: _kTextDark,
          ),
          _Mini(
            label: 'Verbal',
            value: '${result?.verbalPoints ?? '-'}',
            color: item.subjectColor,
          ),
          _Mini(
            label: 'Math',
            value: '${result?.mathPoints ?? '-'}',
            color: _kPrimary,
          ),
          _Mini(label: 'Status', value: 'Submitted', color: _kSuccess),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Mini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _kTextLight,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Empty State в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kTextMid,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Error State в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            const Text(
              'Could not load homework',
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

// в”Ђв”Ђв”Ђ Background Pattern в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _SoftPattern extends StatelessWidget {
  const _SoftPattern();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SoftPatternPainter());
}

class _SoftPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = _kPrimary.withOpacity(0.038);
    canvas.drawCircle(Offset(size.width * 0.06, 80), 110, p);
    p.color = _kSuccess.withOpacity(0.034);
    canvas.drawCircle(Offset(size.width * 0.94, 240), 140, p);
    p.color = _kWarning.withOpacity(0.030);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.90), 120, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// в”Ђв”Ђв”Ђ Helpers в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _HomeworkPageData {
  final UserInfo user;
  final List<_HomeworkItem> toDo;
  final List<_HomeworkItem> completed;

  const _HomeworkPageData({
    required this.user,
    required this.toDo,
    required this.completed,
  });
}

class _HomeworkItem {
  final ClassInfo classInfo;
  final SessionInfo session;
  final AssignmentInfo assignment;
  final HomeworkResultInfo? result;
  final MockResultInfo? mockResult;

  const _HomeworkItem({
    required this.classInfo,
    required this.session,
    required this.assignment,
    required this.result,
    required this.mockResult,
  });

  bool get isMock => session.sessionType.toLowerCase() == 'mock';

  bool get isCompleted =>
      isMock ? mockResult?.submitted == true : result?.submitted == true;
  bool get isSubmissionOpen =>
      !isMock || !DateTime.now().isBefore(_sessionDateTime(session));
  bool get isLate => !isCompleted && DateTime.now().isAfter(deadline);

  DateTime get deadline =>
      _deadlineFromParts(assignment.dueDate, assignment.dueTime);

  DateTime get completedAt => isMock
      ? deadline
      : DateTime.tryParse(result?.submittedAt ?? '') ?? deadline;

  String get title {
    final custom = (assignment.title ?? '').trim();
    if (custom.isNotEmpty) return custom;
    if (isMock) return 'Mock submission';
    final slot = assignment.slotIndex == null
        ? ''
        : ' ${assignment.slotIndex! + 1}';
    return '${_capitalize(session.sessionType)} homework$slot';
  }

  Color get subjectColor {
    switch (session.sessionType.toLowerCase()) {
      case 'math':
        return _kMath;
      case 'verbal':
        return _kVerbal;
      case 'mock':
        return const Color(0xFFEF6C00);
      default:
        return _kPrimary;
    }
  }

  String get deadlineLabel {
    if (isMock) {
      final date = _formatDateHuman(_parseDate(session.date));
      final time = _compactTime(session.startTime);
      return time.isEmpty ? 'Mock day $date' : 'Mock day $date at $time';
    }
    if ((assignment.dueDate ?? '').isEmpty) return 'No deadline';
    final date = _formatDateHuman(_parseDate(assignment.dueDate!));
    final time = _compactTime(assignment.dueTime);
    return time.isEmpty ? 'Due $date' : 'Due $date at $time';
  }

  String get completedLabel {
    if (isMock) return 'Mock submitted';
    final at = DateTime.tryParse(result?.submittedAt ?? '');
    if (at == null) return 'Submitted';
    return 'Submitted ${_formatDateHuman(at)}';
  }
}

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

DateTime _parseDate(String v) => DateTime.tryParse(v) ?? DateTime.now();

String _compactTime(String? v) {
  final t = (v ?? '').trim();
  return t.length >= 5 ? t.substring(0, 5) : t;
}

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
  return '${d.day} ${m[d.month - 1]}';
}

String _capitalize(String v) =>
    v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
