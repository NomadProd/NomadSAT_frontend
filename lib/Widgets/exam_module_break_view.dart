import 'package:flutter/material.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class ExamModuleBreakView extends StatelessWidget {
  final String completedModuleLabel;
  final String nextModuleLabel;
  final int nextQuestionCount;
  final int nextMinutes;
  final VoidCallback onStartNextModule;

  const ExamModuleBreakView({
    super.key,
    required this.completedModuleLabel,
    required this.nextModuleLabel,
    required this.nextQuestionCount,
    required this.nextMinutes,
    required this.onStartNextModule,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 24),
          child: Container(
            key: const Key('diagnostic-module-break'),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: TuranColors.surface,
              borderRadius: BorderRadius.circular(TuranRadius.lg),
              border: Border.all(color: TuranColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedModuleLabel complete',
                  style: TuranTextStyles.title,
                ),
                const SizedBox(height: 10),
                Text(
                  'That module is finished. $nextModuleLabel is a separate '
                  'module with its own $nextMinutes-minute timer.',
                  style: const TextStyle(
                    color: TuranColors.textMid,
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$nextModuleLabel: $nextQuestionCount questions, '
                  '$nextMinutes minutes',
                  style: const TextStyle(
                    color: TuranColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('diagnostic-start-math-button'),
                    onPressed: onStartNextModule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TuranColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                    ),
                    child: Text('Start $nextModuleLabel'),
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
