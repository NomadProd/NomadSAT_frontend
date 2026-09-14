import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/Utils/exam_fullscreen.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class ExamTimerBar extends StatelessWidget {
  final Duration remaining;
  final bool isMath;
  final VoidCallback? onLeave;
  final String leaveTooltip;
  final List<Widget> actions;

  /// Bluebook lets a student put the countdown away when it is the clock
  /// rather than the question making them panic. The choice is owned by the
  /// screen, not by this bar -- the bar is torn down at every module boundary
  /// and would forget it. A null callback means the caller does not offer it,
  /// which is how the diagnostic keeps the bar it has.
  final bool timerVisible;
  final VoidCallback? onToggleTimer;

  const ExamTimerBar({
    super.key,
    required this.remaining,
    required this.isMath,
    this.onLeave,
    this.leaveTooltip = 'Leave test',
    this.actions = const [],
    this.timerVisible = true,
    this.onToggleTimer,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    final urgent = remaining.inSeconds <= 30;
    final sectionLabel = isMath ? 'Math' : 'Reading & Writing';
    final showTimer = timerVisible || onToggleTimer == null;
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
          padding:
              EdgeInsets.fromLTRB(compact ? 12 : 18, 10, compact ? 12 : 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (onLeave != null)
                    IconButton(
                      onPressed: onLeave,
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      tooltip: leaveTooltip,
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
                  if (showTimer) timerChip,
                  if (onToggleTimer != null)
                    IconButton(
                      key: const Key('exam-timer-toggle'),
                      onPressed: onToggleTimer,
                      tooltip: showTimer ? 'Hide timer' : 'Show timer',
                      icon: Icon(
                        showTimer
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.white,
                      ),
                    ),
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

/// Enters and leaves browser fullscreen. Hides itself where fullscreen is not
/// a real capability -- off the web, and on phones, whose browsers implement
/// it badly and have no chrome worth hiding.
class ExamFullscreenButton extends StatefulWidget {
  const ExamFullscreenButton({super.key});

  @override
  State<ExamFullscreenButton> createState() => _ExamFullscreenButtonState();
}

class _ExamFullscreenButtonState extends State<ExamFullscreenButton> {
  StreamSubscription<void>? _watch;
  bool _active = ExamFullscreen.isActive;

  @override
  void initState() {
    super.initState();
    // Esc leaves fullscreen without going near this button, so the icon has to
    // follow the browser rather than our own last tap.
    _watch = ExamFullscreen.onChange.listen((_) {
      if (mounted) setState(() => _active = ExamFullscreen.isActive);
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ExamFullscreen.isSupported ||
        MediaQuery.sizeOf(context).width < TuranBreakpoints.tablet) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      key: const Key('exam-fullscreen-toggle'),
      onPressed: () => _active ? ExamFullscreen.exit() : ExamFullscreen.enter(),
      icon: Icon(
        _active ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        _active ? 'Exit fullscreen' : 'Fullscreen',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Bluebook's flag. A working note for the student sitting the test: it rides
/// along to the module review screen so they can find what they were unsure
/// about, and it is gone once the test is submitted.
class ExamMarkForReviewButton extends StatelessWidget {
  final bool marked;
  final VoidCallback onToggle;

  const ExamMarkForReviewButton({
    super.key,
    required this.marked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('exam-mark-toggle'),
      onPressed: onToggle,
      icon: Icon(
        marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        marked ? 'Marked' : 'Mark for Review',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
