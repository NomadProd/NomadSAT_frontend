import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticQuestionFigure extends StatelessWidget {
  final String url;
  final double scale;
  final String alt;

  const DiagnosticQuestionFigure({
    super.key,
    required this.url,
    this.scale = kDiagnosticImageScaleDefault,
    this.alt = 'Question image',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 720.0;
        final figureWidth = available * clampDiagnosticImageScale(scale);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const Key('diagnostic-question-figure-box'),
            width: figureWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TuranColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: TuranColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.network(
                  url,
                  width: figureWidth,
                  fit: BoxFit.fitWidth,
                  semanticLabel: alt,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      alt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: TuranColors.textMid),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
