import 'package:flutter/material.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/Widgets/exam_attempt_review_view.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

/// Score plus every question with the student's answer, the correct answer and
/// the explanation. Reuses the same review view the diagnostic renders.
class PracticeTestReviewScreen extends StatefulWidget {
  final int attemptId;
  final bool showStudentName;

  /// Injectable so the flow can be driven in tests without a server.
  final PracticeTestService? service;

  const PracticeTestReviewScreen({
    super.key,
    required this.attemptId,
    this.showStudentName = false,
    this.service,
  });

  @override
  State<PracticeTestReviewScreen> createState() =>
      _PracticeTestReviewScreenState();
}

class _PracticeTestReviewScreenState extends State<PracticeTestReviewScreen> {
  late final _service = widget.service ?? PracticeTestService();
  late Future<PracticeTestAttemptDetail> _future =
      _service.fetchAttemptDetail(widget.attemptId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: FutureBuilder<PracticeTestAttemptDetail>(
        future: _future,
        builder: (context, snap) {
          final denied = snap.error is ApiException &&
              ((snap.error as ApiException).statusCode == 403 ||
                  (snap.error as ApiException).statusCode == 404);
          return Column(
            children: [
              TuranHeader(
                title: denied
                    ? 'Access denied'
                    : widget.showStudentName && snap.hasData
                        ? snap.data!.studentName
                        : 'Practice test review',
                subtitle: denied
                    ? 'You do not have permission to view this attempt'
                    : 'Question-by-question review with explanations',
                pageLabel: 'Practice',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: snap.connectionState != ConnectionState.done
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: TuranColors.primary),
                      )
                    : snap.hasError
                        ? ExamAttemptReviewDenied(
                            message: denied
                                ? 'You do not have permission to view this attempt.'
                                : userFacingError(snap.error!),
                            onRetry: denied
                                ? null
                                : () => setState(
                                      () => _future = _service
                                          .fetchAttemptDetail(widget.attemptId),
                                    ),
                          )
                        : ExamAttemptReviewView(
                            detail: snap.data!.toExamReview(),
                            showStudentName: widget.showStudentName,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
