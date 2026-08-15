import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticResultsScreen extends StatelessWidget {
  final DiagnosticAttempt attempt;
  final VoidCallback onRetake;
  final VoidCallback? onBackToDashboard;

  const DiagnosticResultsScreen({
    super.key,
    required this.attempt,
    required this.onRetake,
    this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: 'Diagnostic results',
            subtitle: 'Approximate Digital SAT score range',
            pageLabel: 'Diagnostic',
            onBack: onBackToDashboard ?? () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: DiagnosticResultsView(
              attempt: attempt,
              onRetake: onRetake,
              onBackToDashboard: onBackToDashboard ?? () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosticResultsView extends StatelessWidget {
  final DiagnosticAttempt attempt;
  final VoidCallback onRetake;
  final VoidCallback? onBackToDashboard;

  const DiagnosticResultsView({
    super.key,
    required this.attempt,
    required this.onRetake,
    this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final low = attempt.totalRangeLow ?? 400;
    final high = attempt.totalRangeHigh ?? 1600;
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        20,
        compact ? 16 : 24,
        32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: BoxDecoration(
                    color: TuranColors.surface,
                    borderRadius: BorderRadius.circular(TuranRadius.lg),
                    border: Border.all(color: TuranColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: TuranColors.primary.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Estimated Score',
                        style: TuranTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TuranColors.textMid,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$low–$high',
                        key: const Key('diagnostic-score-range'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 36 : 44,
                          fontWeight: FontWeight.w900,
                          color: TuranColors.textDark,
                          letterSpacing: -1.2,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      DiagnosticScoreRangeBar(low: low, high: high),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 560;
                    final cards = [
                      _SectionScoreCard(
                        label: 'Reading & Writing',
                        score: attempt.rwScaledEstimate,
                        color: TuranColors.verbal,
                      ),
                      _SectionScoreCard(
                        label: 'Math',
                        score: attempt.mathScaledEstimate,
                        color: TuranColors.math,
                      ),
                    ];
                    if (stacked) {
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 10),
                          cards[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 10),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const DiagnosticDisclaimerBanner(),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retake test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TuranColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onBackToDashboard,
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text('Back to dashboard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TuranColors.primary,
                        side: const BorderSide(color: TuranColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DiagnosticDisclaimerBanner extends StatelessWidget {
  const DiagnosticDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('diagnostic-disclaimer'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuranColors.warningBg,
        borderRadius: BorderRadius.circular(TuranRadius.md),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: TuranColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              kDiagnosticScoreDisclaimer,
              style: const TextStyle(
                color: TuranColors.textDark,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosticScoreRangeBar extends StatelessWidget {
  final int low;
  final int high;

  const DiagnosticScoreRangeBar({
    super.key,
    required this.low,
    required this.high,
  });

  @override
  Widget build(BuildContext context) {
    const minScore = 400.0;
    const maxScore = 1600.0;
    final span = maxScore - minScore;
    final start = ((low - minScore) / span).clamp(0.0, 1.0);
    final end = ((high - minScore) / span).clamp(0.0, 1.0);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 18,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: TuranColors.panelBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Positioned(
                    left: width * start,
                    width: (width * (end - start)).clamp(8.0, width),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: TuranColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Text('400', style: TextStyle(color: TuranColors.textLight, fontSize: 11)),
            Spacer(),
            Text('1600', style: TextStyle(color: TuranColors.textLight, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _SectionScoreCard extends StatelessWidget {
  final String label;
  final int? score;
  final Color color;

  const _SectionScoreCard({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.md),
        border: Border.all(color: TuranColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TuranColors.textMid,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score?.toString() ?? '—',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
