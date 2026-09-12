/// How a timetable day cell divides its height between session chips.
///
/// Kept out of the widget so the fitting rule can be tested on its own.
library;

/// Vertical gap between two chips in a day cell.
const double kCalendarChipGap = 3;

/// Below this a chip has no room left for even its compact one-row layout.
const double kCalendarMinChipHeight = 26;

/// Height the "+N more" badge takes when not every session is shown.
const double kCalendarBadgeHeight = 15;

/// How many session chips a day cell of [availableHeight] should render.
///
/// Every session is shown whenever they all fit at a legible height -- a
/// session hidden behind a badge is a session the student does not know about.
/// When they cannot all fit, one is always left over so the badge has
/// something to report, and at least one chip is shown however short the cell.
int calendarVisibleSessionCount({
  required double availableHeight,
  required int sessionCount,
}) {
  if (sessionCount <= 0) return 0;

  final heightForChips =
      availableHeight - kCalendarChipGap * (sessionCount - 1);
  if (heightForChips / sessionCount >= kCalendarMinChipHeight) {
    return sessionCount;
  }

  // Not all of them fit: reserve the badge's row, then fill what is left.
  final usable = availableHeight - kCalendarBadgeHeight + kCalendarChipGap;
  final fits = (usable / (kCalendarMinChipHeight + kCalendarChipGap)).floor();
  return fits.clamp(1, sessionCount - 1);
}
