import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';

class WeeklyScheduleLabels {
  static const full = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}

class DayScheduleEntry {
  bool enabled;
  final TextEditingController timeController;

  DayScheduleEntry({this.enabled = false, String time = '18:30'})
      : timeController = TextEditingController(text: time);

  void dispose() => timeController.dispose();
}

class WeeklyScheduleForm {
  static const defaultLessonTime = '18:30';
  static const defaultMockTime = '09:00';
  static final timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  static List<DayScheduleEntry> createEntries({
    String defaultTime = defaultLessonTime,
  }) {
    return List.generate(7, (_) => DayScheduleEntry(time: defaultTime));
  }

  static void disposeEntries(List<DayScheduleEntry> entries) {
    for (final entry in entries) {
      entry.dispose();
    }
  }

  static List<Map<String, dynamic>> buildPayload(List<DayScheduleEntry> days) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      if (!day.enabled) continue;
      result.add({
        'day_of_week': i,
        'start_time': day.timeController.text.trim(),
      });
    }
    return result;
  }

  static String compactTime(String? value) {
    if (value == null || value.isEmpty) return '';
    final parts = value.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return value;
  }

  static void inferFromSessions({
    required List<SessionInfo> sessions,
    required DateTime from,
    required DateTime to,
    required List<DayScheduleEntry> verbal,
    required List<DayScheduleEntry> math,
    required List<DayScheduleEntry> mock,
  }) {
    for (final entry in [...verbal, ...math, ...mock]) {
      entry.enabled = false;
      entry.timeController.text = defaultLessonTime;
    }
    for (final entry in mock) {
      entry.timeController.text = defaultMockTime;
    }

    for (final session in sessions) {
      final date = DateTime.tryParse(session.date);
      if (date == null) continue;
      final normalized = DateTime(date.year, date.month, date.day);
      if (normalized.isBefore(from) || normalized.isAfter(to)) continue;

      final weekday = date.weekday - 1;
      if (weekday < 0 || weekday > 6) continue;

      final type = session.sessionType.toLowerCase();
      final List<DayScheduleEntry>? entries = switch (type) {
        'verbal' => verbal,
        'math' => math,
        'mock' => mock,
        _ => null,
      };
      if (entries == null) continue;

      entries[weekday].enabled = true;
      entries[weekday].timeController.text = compactTime(session.startTime);
    }
  }

  static String? validate({
    required List<DayScheduleEntry> verbal,
    required List<DayScheduleEntry> math,
    required List<DayScheduleEntry> mock,
    List<String> weekdayLabels = WeeklyScheduleLabels.full,
  }) {
    final hasVerbal = verbal.any((day) => day.enabled);
    final hasMath = math.any((day) => day.enabled);
    final hasMock = mock.any((day) => day.enabled);
    if (!hasVerbal && !hasMath && !hasMock) {
      return 'Enable at least one verbal, math, or mock day';
    }

    for (var i = 0; i < verbal.length; i++) {
      final day = verbal[i];
      if (!day.enabled) continue;
      final time = day.timeController.text.trim();
      if (!timePattern.hasMatch(time)) {
        return 'Verbal ${weekdayLabels[i]}: use HH:MM (e.g. $defaultLessonTime)';
      }
    }

    for (var i = 0; i < math.length; i++) {
      final day = math[i];
      if (!day.enabled) continue;
      final time = day.timeController.text.trim();
      if (!timePattern.hasMatch(time)) {
        return 'Math ${weekdayLabels[i]}: use HH:MM (e.g. $defaultLessonTime)';
      }
    }

    for (var i = 0; i < mock.length; i++) {
      final day = mock[i];
      if (!day.enabled) continue;
      final time = day.timeController.text.trim();
      if (!timePattern.hasMatch(time)) {
        return 'Mock ${weekdayLabels[i]}: use HH:MM (e.g. $defaultMockTime)';
      }
    }

    return null;
  }
}

class WeeklyLessonSchedulePicker extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> weekdayLabels;
  final List<DayScheduleEntry> days;
  final bool enabled;
  final String timeHint;
  final String? helperText;
  final VoidCallback onChanged;

  const WeeklyLessonSchedulePicker({
    super.key,
    required this.title,
    required this.icon,
    required this.weekdayLabels,
    required this.days,
    required this.enabled,
    this.timeHint = WeeklyScheduleForm.defaultLessonTime,
    this.helperText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1A4AF0)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1A4AF0),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          helperText ??
              'Tap a day to enable it, then set the start time (HH:MM).',
          style: const TextStyle(color: Color(0xFF6B7A99), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(days.length, (index) {
            final day = days[index];
            final label = weekdayLabels[index];
            return WeekdayScheduleCell(
              label: label,
              enabled: enabled,
              active: day.enabled,
              timeController: day.timeController,
              timeHint: timeHint,
              onToggle: () {
                day.enabled = !day.enabled;
                onChanged();
              },
            );
          }),
        ),
      ],
    );
  }
}

class WeekdayScheduleCell extends StatelessWidget {
  static const _cellWidth = 78.0;
  static const _cellHeight = 90.0;
  static const _timeAreaHeight = 40.0;

  final String label;
  final bool enabled;
  final bool active;
  final TextEditingController timeController;
  final String timeHint;
  final VoidCallback onToggle;

  const WeekdayScheduleCell({
    super.key,
    required this.label,
    required this.enabled,
    required this.active,
    required this.timeController,
    this.timeHint = WeeklyScheduleForm.defaultLessonTime,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = active
        ? const Color(0xFF1A4AF0)
        : const Color(0xFFD7E3FF);
    final bgColor = active ? const Color(0xFFF4F7FF) : Colors.white;

    return SizedBox(
      width: _cellWidth,
      height: _cellHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: enabled ? onToggle : null,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                width: double.infinity,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active
                          ? const Color(0xFF1A4AF0)
                          : const Color(0xFF8A97B5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: _timeAreaHeight,
              width: double.infinity,
              child: active
                  ? TextField(
                      controller: timeController,
                      enabled: enabled,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 10,
                        ),
                        hintText: timeHint,
                        hintStyle: const TextStyle(fontSize: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: const Color(0xFF1A4AF0).withOpacity(0.35),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          borderSide: BorderSide(color: Color(0xFF1A4AF0)),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: enabled ? onToggle : null,
                      borderRadius: BorderRadius.circular(6),
                      child: const Center(
                        child: Text(
                          '—',
                          style: TextStyle(
                            color: Color(0xFFB8C4DE),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
