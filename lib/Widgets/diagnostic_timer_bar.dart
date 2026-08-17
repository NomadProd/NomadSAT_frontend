import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticTimerBar extends StatelessWidget {
  final Duration remaining;
  final bool isMath;
  final VoidCallback? onLeave;
  final List<Widget> actions;

  const DiagnosticTimerBar({
    super.key,
    required this.remaining,
    required this.isMath,
    this.onLeave,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final urgent = remaining.inSeconds <= 30;
    final sectionLabel = isMath ? 'Math' : 'Reading & Writing';
    final timerChip = Container(
      key: const Key('diagnostic-timer'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFFCDD2) : Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        formatDiagnosticCountdown(remaining),
        style: TextStyle(
          color: urgent ? TuranColors.error : TuranColors.textDark,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontSize: 16,
        ),
      ),
    );

    return Material(
      color: TuranColors.primary,
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 10, compact ? 12 : 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (onLeave != null)
                    IconButton(
                      onPressed: onLeave,
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: 'Leave test',
                    ),
                  Expanded(
                    child: Text(
                      sectionLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  timerChip,
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
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
