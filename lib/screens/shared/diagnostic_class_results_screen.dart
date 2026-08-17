import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/diagnostic_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/Widgets/diagnostic_attempt_review_view.dart';
import 'package:flutter_web/screens/student/diagnostic_dashboard_screen.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticClassResultsScreen extends StatefulWidget {
  final int classId;
  final String className;
  final List<UserInfo> students;

  const DiagnosticClassResultsScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.students,
  });

  @override
  State<DiagnosticClassResultsScreen> createState() =>
      _DiagnosticClassResultsScreenState();
}

class _DiagnosticClassResultsScreenState
    extends State<DiagnosticClassResultsScreen> {
  final _service = DiagnosticService();
  late Future<List<DiagnosticAttemptListItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAttemptsForClass(widget.classId);
  }

  Map<int, DiagnosticAttemptListItem> _latestByStudent(
    List<DiagnosticAttemptListItem> attempts,
  ) {
    final latest = <int, DiagnosticAttemptListItem>{};
    for (final attempt in attempts) {
      if (!attempt.isCompleted) continue;
      latest.putIfAbsent(attempt.studentId, () => attempt);
    }
    return latest;
  }

  Future<void> _openStudent(UserInfo student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiagnosticDashboardScreen(
          studentId: student.userId,
          studentName: student.fullName,
          allowRetake: false,
          showStudentNameOnReview: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: 'Diagnostic Results',
            subtitle: widget.className,
            pageLabel: 'Class',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: FutureBuilder<List<DiagnosticAttemptListItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: TuranColors.primary),
                  );
                }
                if (snap.hasError) {
                  final denied = snap.error is ApiException &&
                      ((snap.error as ApiException).statusCode == 403 ||
                          (snap.error as ApiException).statusCode == 404);
                  return DiagnosticAttemptReviewDenied(
                    message: denied
                        ? 'You do not have permission to view diagnostic results for this class.'
                        : userFacingError(snap.error!),
                    onRetry: denied
                        ? null
                        : () => setState(
                            () => _future = _service.fetchAttemptsForClass(
                              widget.classId,
                            ),
                          ),
                  );
                }
                final latest = _latestByStudent(snap.data ?? const []);
                final students = [...widget.students]
                  ..sort(
                    (a, b) => a.fullName.toLowerCase().compareTo(
                      b.fullName.toLowerCase(),
                    ),
                  );
                if (students.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students enrolled in this class.',
                      style: TuranTextStyles.subtitle,
                    ),
                  );
                }
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 24,
                    18,
                    compact ? 16 : 24,
                    32,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          children: [
                            for (final student in students)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ClassStudentResultRow(
                                  student: student,
                                  latest: latest[student.userId],
                                  onTap: () => _openStudent(student),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassStudentResultRow extends StatelessWidget {
  final UserInfo student;
  final DiagnosticAttemptListItem? latest;
  final VoidCallback onTap;

  const _ClassStudentResultRow({
    required this.student,
    required this.latest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final attempt = latest;
    return Material(
      color: TuranColors.surface,
      borderRadius: BorderRadius.circular(TuranRadius.lg),
      child: InkWell(
        key: Key('diagnostic-class-student-${student.userId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TuranRadius.lg),
            border: Border.all(color: TuranColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        color: TuranColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attempt == null
                          ? 'No attempts yet'
                          : attempt.scoreRangeLabel,
                      style: TextStyle(
                        color: attempt == null
                            ? TuranColors.textMid
                            : TuranColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TuranColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
