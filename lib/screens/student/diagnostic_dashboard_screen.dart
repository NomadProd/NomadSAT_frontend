import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/diagnostic_service.dart';
import 'package:flutter_web/Widgets/diagnostic_attempt_result_card.dart';
import 'package:flutter_web/Widgets/diagnostic_attempt_review_view.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/screens/shared/diagnostic_attempt_review_screen.dart';
import 'package:flutter_web/screens/student/diagnostic_test_screen.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticDashboardScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;
  final bool allowRetake;
  final bool showStudentNameOnReview;

  const DiagnosticDashboardScreen({
    super.key,
    this.studentId,
    this.studentName,
    this.allowRetake = true,
    this.showStudentNameOnReview = false,
  });

  @override
  State<DiagnosticDashboardScreen> createState() =>
      _DiagnosticDashboardScreenState();
}

class _DiagnosticDashboardScreenState extends State<DiagnosticDashboardScreen> {
  final _service = DiagnosticService();
  late Future<List<DiagnosticAttemptListItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAttempts();
  }

  Future<List<DiagnosticAttemptListItem>> _loadAttempts() {
    final studentId = widget.studentId;
    if (studentId == null) {
      return _service.fetchMyAttempts();
    }
    return _service.fetchAttemptsForStudent(studentId);
  }

  Future<void> _openAttempt(DiagnosticAttemptListItem attempt) async {
    if (attempt.isInProgress) {
      if (!widget.allowRetake) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DiagnosticTestScreen()),
      );
      if (!mounted) return;
      setState(() => _future = _loadAttempts());
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiagnosticAttemptReviewScreen(
          attemptId: attempt.attemptId,
          showStudentName: widget.showStudentNameOnReview,
        ),
      ),
    );
  }

  Future<void> _startTest() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DiagnosticTestScreen()),
    );
    if (!mounted) return;
    setState(() => _future = _loadAttempts());
  }

  @override
  Widget build(BuildContext context) {
    final viewingOther = widget.studentId != null;
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: viewingOther
                ? 'Diagnostic Test Results'
                : 'My Diagnostic Results',
            subtitle: viewingOther
                ? (widget.studentName ?? 'Completed diagnostic attempts')
                : 'History and approximate score ranges',
            pageLabel: 'Diagnostic',
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
                        ? 'You do not have permission to view these diagnostic results.'
                        : userFacingError(snap.error!),
                    onRetry: denied
                        ? null
                        : () => setState(() => _future = _loadAttempts()),
                  );
                }
                return DiagnosticAttemptListView(
                  attempts: snap.data ?? const [],
                  onOpen: _openAttempt,
                  onTakeTest: widget.allowRetake ? _startTest : null,
                  onRetake: widget.allowRetake && (snap.data?.isNotEmpty ?? false)
                      ? _startTest
                      : null,
                  emptyTitle: viewingOther
                      ? 'No diagnostic attempts yet'
                      : 'No diagnostic results yet',
                  emptyBody: viewingOther
                      ? 'This student has not completed a diagnostic test.'
                      : 'Take the 20-question diagnostic to see an approximate SAT score range.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
