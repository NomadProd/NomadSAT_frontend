/// Module clock arithmetic for the practice test.
///
/// Kept out of the screen so it can be tested without a widget tree.
library;

/// Time left in a module that started at [moduleStartedAt].
///
/// [pauseSeconds] is time the student spent out of the test, which the server
/// accumulates in `practice_test_attempts.timer_pause_seconds`; it does not
/// count against them. The result is clamped to `[0, timeLimitSeconds]`, so a
/// pause total can never hand back more time than the module is allowed.
Duration examModuleRemaining({
  required DateTime moduleStartedAt,
  required DateTime now,
  required int timeLimitSeconds,
  int pauseSeconds = 0,
}) {
  final elapsed = now.difference(moduleStartedAt).inSeconds - pauseSeconds;
  final left = timeLimitSeconds - elapsed;
  if (left <= 0) return Duration.zero;
  if (left >= timeLimitSeconds) return Duration(seconds: timeLimitSeconds);
  return Duration(seconds: left);
}
