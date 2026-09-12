import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Utils/exam_timer.dart';

void main() {
  final started = DateTime.utc(2026, 9, 12, 9);

  group('examModuleRemaining', () {
    test('counts down from the module limit', () {
      expect(
        examModuleRemaining(
          moduleStartedAt: started,
          now: started.add(const Duration(minutes: 5)),
          timeLimitSeconds: 35 * 60,
        ),
        const Duration(minutes: 30),
      );
    });

    test('time spent away does not count against the module', () {
      expect(
        examModuleRemaining(
          moduleStartedAt: started,
          now: started.add(const Duration(minutes: 20)),
          timeLimitSeconds: 35 * 60,
          pauseSeconds: 10 * 60,
        ),
        const Duration(minutes: 25),
        reason: 'ten of those twenty minutes were spent out of the test',
      );
    });

    test('never goes negative', () {
      expect(
        examModuleRemaining(
          moduleStartedAt: started,
          now: started.add(const Duration(hours: 3)),
          timeLimitSeconds: 35 * 60,
        ),
        Duration.zero,
      );
    });

    test('a pause longer than the elapsed time cannot add time', () {
      expect(
        examModuleRemaining(
          moduleStartedAt: started,
          now: started.add(const Duration(minutes: 5)),
          timeLimitSeconds: 35 * 60,
          pauseSeconds: 99 * 60,
        ),
        const Duration(minutes: 35),
        reason: 'the module can never have more time left than its own limit',
      );
    });

    test('is timezone-agnostic', () {
      expect(
        examModuleRemaining(
          moduleStartedAt: started,
          now: started.toLocal().add(const Duration(minutes: 5)),
          timeLimitSeconds: 35 * 60,
        ),
        const Duration(minutes: 30),
      );
    });
  });
}
