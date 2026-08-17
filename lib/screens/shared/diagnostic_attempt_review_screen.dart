import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/diagnostic_service.dart';
import 'package:flutter_web/Widgets/diagnostic_attempt_review_view.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticAttemptReviewScreen extends StatefulWidget {
  final int attemptId;
  final bool showStudentName;

  const DiagnosticAttemptReviewScreen({
    super.key,
    required this.attemptId,
    this.showStudentName = false,
  });

  @override
  State<DiagnosticAttemptReviewScreen> createState() =>
      _DiagnosticAttemptReviewScreenState();
}

class _DiagnosticAttemptReviewScreenState
    extends State<DiagnosticAttemptReviewScreen> {
  final _service = DiagnosticService();
  late Future<DiagnosticAttemptDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAttemptDetail(widget.attemptId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: FutureBuilder<DiagnosticAttemptDetail>(
        future: _future,
        builder: (context, snap) {
          final denied = snap.hasError && _isAccessDenied(snap.error!);
          return Column(
            children: [
              TuranHeader(
                title: denied
                    ? 'Access denied'
                    : widget.showStudentName && snap.hasData
                    ? snap.data!.student.fullName
                    : 'Attempt review',
                subtitle: denied
                    ? 'You do not have permission to view this attempt'
                    : 'Question-by-question diagnostic review',
                pageLabel: 'Diagnostic',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: TuranColors.primary,
                        ),
                      )
                    : snap.hasError
                    ? DiagnosticAttemptReviewDenied(
                        message: denied
                            ? 'You do not have permission to view this diagnostic attempt.'
                            : userFacingError(snap.error!),
                        onRetry: denied
                            ? null
                            : () => setState(
                                () => _future = _service.fetchAttemptDetail(
                                  widget.attemptId,
                                ),
                              ),
                      )
                    : DiagnosticAttemptReviewView(
                        detail: snap.data!,
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

bool _isAccessDenied(Object error) {
  return error is ApiException &&
      (error.statusCode == 403 || error.statusCode == 404);
}
