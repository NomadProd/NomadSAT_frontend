import 'package:flutter/material.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticModuleBreakView extends StatelessWidget {
  final VoidCallback onStartMath;

  const DiagnosticModuleBreakView({
    super.key,
    required this.onStartMath,
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
                const Text(
                  'Reading & Writing complete',
                  style: TuranTextStyles.title,
                ),
                const SizedBox(height: 10),
                const Text(
                  'That module is finished. Math is a separate module with its own 15-minute timer.',
                  style: TextStyle(
                    color: TuranColors.textMid,
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Math: 10 questions, 15 minutes',
                  style: TextStyle(
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
                    onPressed: onStartMath,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TuranColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                    ),
                    child: const Text('Start Math module'),
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
