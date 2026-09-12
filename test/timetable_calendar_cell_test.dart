import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Utils/calendar_cell_layout.dart';

void main() {
  group('calendarVisibleSessionCount', () {
    test('an empty day shows nothing', () {
      expect(
        calendarVisibleSessionCount(availableHeight: 120, sessionCount: 0),
        0,
      );
    });

    test('every session is shown when they all fit legibly', () {
      // A normal desktop cell has room for three chips at the minimum height.
      expect(
        calendarVisibleSessionCount(availableHeight: 120, sessionCount: 3),
        3,
        reason: 'sessions that fit must not be hidden behind a badge',
      );
      expect(
        calendarVisibleSessionCount(availableHeight: 120, sessionCount: 1),
        1,
      );
    });

    test('a crowded day keeps at least one session behind the badge', () {
      final visible =
          calendarVisibleSessionCount(availableHeight: 120, sessionCount: 9);
      expect(visible, greaterThanOrEqualTo(1));
      expect(
        visible,
        lessThan(9),
        reason: 'if every session were shown there would be no badge, but '
            'they cannot all fit legibly',
      );
    });

    test('a very short cell still shows one session', () {
      expect(
        calendarVisibleSessionCount(availableHeight: 18, sessionCount: 5),
        1,
        reason: 'a cell too short for any chip must still show one, never zero',
      );
    });

    test('more room never shows fewer sessions', () {
      var previous = 0;
      for (var height = 10.0; height <= 260; height += 5) {
        final visible =
            calendarVisibleSessionCount(availableHeight: height, sessionCount: 6);
        expect(
          visible,
          greaterThanOrEqualTo(previous),
          reason: 'growing the cell to ${height}px showed fewer sessions',
        );
        previous = visible;
      }
      expect(previous, 6, reason: 'a tall cell should fit all six');
    });

    test('never returns more sessions than the day has', () {
      for (var count = 0; count <= 8; count++) {
        expect(
          calendarVisibleSessionCount(availableHeight: 400, sessionCount: count),
          lessThanOrEqualTo(count),
        );
      }
    });
  });
}
