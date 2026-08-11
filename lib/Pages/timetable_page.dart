part of class_detail;

class TimetablePage extends StatefulWidget {
  final int classId;
  final ClassService classService;
  final bool canEditSchedule;
  final String className;
  final List<SessionInfo> sessions;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;

  const TimetablePage({
    required this.classId,
    required this.classService,
    required this.canEditSchedule,
    required this.className,
    required this.sessions,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
  });

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late int _selectedMonthIndex;
  late List<SessionInfo> _sessions;
  bool _scheduleChanged = false;

  @override
  void initState() {
    super.initState();
    _sessions = List<SessionInfo>.from(widget.sessions);
    _selectedMonthIndex = _initialMonthIndex();
  }

  Future<void> _reloadSessions() async {
    final updated = await widget.classService.fetchClassSessions(widget.classId);
    if (!mounted) return;
    setState(() => _sessions = updated);
  }

  (DateTime, DateTime) _defaultDateRange() {
    if (_sessions.isEmpty) {
      final now = DateTime.now();
      return (_normalizeDate(now), _normalizeDate(now.add(const Duration(days: 27))));
    }
    final dates = _sessions.map((s) => _parseDate(s.date)).toList()..sort();
    return (_normalizeDate(dates.first), _normalizeDate(dates.last));
  }

  Future<void> _openEditScheduleDialog() async {
    final (initialFrom, initialTo) = _defaultDateRange();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditClassScheduleDialog(
        classService: widget.classService,
        classId: widget.classId,
        sessions: _sessions,
        initialFrom: initialFrom,
        initialTo: initialTo,
      ),
    );
    if (saved == true) {
      _scheduleChanged = true;
      await _reloadSessions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule updated')),
      );
    }
  }

  int _initialMonthIndex() {
    final months = _visibleMonths;
    if (months.isEmpty) return 0;
    final now = DateTime.now();
    final idx = months.indexWhere(
      (month) => month.year == now.year && month.month == now.month,
    );
    return idx >= 0 ? idx : 0;
  }

  List<DateTime> get _visibleMonths {
    if (_sessions.isEmpty)
      return [DateTime(DateTime.now().year, DateTime.now().month)];

    final dates = _sessions.map((s) => _parseDate(s.date)).toList()
      ..sort((a, b) => a.compareTo(b));
    final first = DateTime(dates.first.year, dates.first.month);
    final last = DateTime(dates.last.year, dates.last.month);

    final months = <DateTime>[];
    var cursor = first;
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  Map<String, List<SessionInfo>> get _sessionsByDate {
    final map = <String, List<SessionInfo>>{};
    for (final session in _sessions) {
      map.putIfAbsent(session.date, () => []).add(session);
    }
    for (final daySessions in map.values) {
      daySessions.sort(
        (a, b) =>
            _compactTime(a.startTime).compareTo(_compactTime(b.startTime)),
      );
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final months = _visibleMonths;
    if (_selectedMonthIndex >= months.length) {
      _selectedMonthIndex = months.length - 1;
    }
    final sessionsByDate = _sessionsByDate;
    final today = _normalizeDate(DateTime.now());
    final selectedMonth = months[_selectedMonthIndex];
    final hasPrevious = _selectedMonthIndex > 0;
    final hasNext = _selectedMonthIndex < months.length - 1;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TimetableHeader(
              className: widget.className,
              sessionCount: _sessions.length,
              canEditSchedule: widget.canEditSchedule,
              onEditSchedule: _openEditScheduleDialog,
              onBack: () => Navigator.of(context).pop(_scheduleChanged),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 600;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? double.infinity : 920,
                      ),
                      child: Column(
                        children: [
                          _CalendarHeader(
                            monthLabel: _monthYearLabel(selectedMonth),
                            compact: compact,
                            canGoPrevious: hasPrevious,
                            canGoNext: hasNext,
                            onPrevious: hasPrevious
                                ? () => setState(() => _selectedMonthIndex--)
                                : null,
                            onNext: hasNext
                                ? () => setState(() => _selectedMonthIndex++)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _MonthCalendar(
                            month: selectedMonth,
                            today: today,
                            sessionsByDate: sessionsByDate,
                            verbalTeacher: widget.verbalTeacher,
                            mathTeacher: widget.mathTeacher,
                            teachers: widget.teachers,
                            compact: compact,
                          ),
                          if (compact) ...[
                            const SizedBox(height: 16),
                            _MonthAgendaList(
                              month: selectedMonth,
                              sessionsByDate: sessionsByDate,
                              verbalTeacher: widget.verbalTeacher,
                              mathTeacher: widget.mathTeacher,
                              teachers: widget.teachers,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableHeader extends StatelessWidget {
  final String className;
  final int sessionCount;
  final bool canEditSchedule;
  final VoidCallback onEditSchedule;
  final VoidCallback onBack;

  const _TimetableHeader({
    required this.className,
    required this.sessionCount,
    required this.canEditSchedule,
    required this.onEditSchedule,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => TuranHeader(
    title: 'Timetable',
    subtitle: className,
    pageLabel: 'Schedule',
    onBack: onBack,
    actions: canEditSchedule
        ? [
            TuranHeaderAction(
              icon: Icons.edit_calendar_rounded,
              label: 'Edit',
              onTap: onEditSchedule,
            ),
          ]
        : const [],
    bottom: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Text(
        '$sessionCount lessons',
        style: TextStyle(
          color: Colors.white.withOpacity(0.86),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _CalendarHeader extends StatelessWidget {
  final String monthLabel;
  final bool compact;
  final bool canGoPrevious, canGoNext;
  final VoidCallback? onPrevious, onNext;

  const _CalendarHeader({
    required this.monthLabel,
    required this.compact,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _CalendarNavButton(
            icon: Icons.chevron_left_rounded,
            enabled: canGoPrevious,
            onTap: onPrevious,
          ),
          const SizedBox(width: 10),
          if (!compact)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: _kPrimary,
                size: 20,
              ),
            ),
          if (!compact) const SizedBox(width: 10),
          Expanded(
            child: Text(
              monthLabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _kTextDark,
                fontSize: compact ? 15 : 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CalendarNavButton(
            icon: Icons.chevron_right_rounded,
            enabled: canGoNext,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _CalendarNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _kPrimary : _kPanelBg,
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? _kPrimary : _kBorder),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : _kTextLight,
          size: 19,
        ),
      ),
    );
  }
}

const _kWeekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _kWeekdaySemantics = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

double _calendarColumnGap(bool compact) => compact ? 6 : 8;

double _calendarRowGap(bool compact) => compact ? 6 : 10;

double _calendarCellAspectRatio(bool compact) => compact ? 1.1 : 1.2;

class _CalendarSevenColumnRow extends StatelessWidget {
  final double horizontalGap;
  final List<Widget> children;

  const _CalendarSevenColumnRow({
    required this.horizontalGap,
    required this.children,
  }) : assert(children.length == 7);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) SizedBox(width: horizontalGap),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _CalendarWeekdayRow extends StatelessWidget {
  final bool compact;

  const _CalendarWeekdayRow({required this.compact});

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 10.0 : 12.0;
    final gap = _calendarColumnGap(compact);

    return _CalendarSevenColumnRow(
      horizontalGap: gap,
      children: [
        for (var i = 0; i < 7; i++)
          Semantics(
            label: _kWeekdaySemantics[i],
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _kWeekdayLabels[i],
                  maxLines: 1,
                  style: TextStyle(
                    color: _kTextLight,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDateGrid extends StatelessWidget {
  final List<DateTime?> cells;
  final DateTime today;
  final Map<String, List<SessionInfo>> sessionsByDate;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;
  final bool compact;

  const _CalendarDateGrid({
    required this.cells,
    required this.today,
    required this.sessionsByDate,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final columnGap = _calendarColumnGap(compact);
    final rowGap = _calendarRowGap(compact);
    final aspectRatio = _calendarCellAspectRatio(compact);
    final weekCount = cells.length ~/ 7;

    return Column(
      children: [
        for (var week = 0; week < weekCount; week++) ...[
          if (week > 0) SizedBox(height: rowGap),
          _CalendarSevenColumnRow(
            horizontalGap: columnGap,
            children: [
              for (var col = 0; col < 7; col++)
                _CalendarDateGridCell(
                  day: cells[week * 7 + col],
                  today: today,
                  sessionsByDate: sessionsByDate,
                  verbalTeacher: verbalTeacher,
                  mathTeacher: mathTeacher,
                  teachers: teachers,
                  compact: compact,
                  aspectRatio: aspectRatio,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CalendarDateGridCell extends StatelessWidget {
  final DateTime? day;
  final DateTime today;
  final Map<String, List<SessionInfo>> sessionsByDate;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;
  final bool compact;
  final double aspectRatio;

  const _CalendarDateGridCell({
    required this.day,
    required this.today,
    required this.sessionsByDate,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
    required this.compact,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / aspectRatio;

        if (day == null) {
          return SizedBox(height: height);
        }

        final key = _formatDateForApi(day!);
        final daySessions = sessionsByDate[key] ?? const <SessionInfo>[];

        return SizedBox(
          height: height,
          child: _CalendarDayCell(
            day: day!,
            isToday: _normalizeDate(day!) == today,
            sessions: daySessions,
            verbalTeacher: verbalTeacher,
            mathTeacher: mathTeacher,
            teachers: teachers,
            compact: compact,
          ),
        );
      },
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final Map<String, List<SessionInfo>> sessionsByDate;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;
  final bool compact;

  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.sessionsByDate,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
    required this.compact,
  });

  List<DateTime?> get _cells {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CalendarWeekdayRow(compact: compact),
          SizedBox(height: compact ? 6 : 8),
          _CalendarDateGrid(
            cells: _cells,
            today: today,
            sessionsByDate: sessionsByDate,
            verbalTeacher: verbalTeacher,
            mathTeacher: mathTeacher,
            teachers: teachers,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _MonthAgendaList extends StatelessWidget {
  final DateTime month;
  final Map<String, List<SessionInfo>> sessionsByDate;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;

  const _MonthAgendaList({
    required this.month,
    required this.sessionsByDate,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
  });

  List<SessionInfo> get _monthSessions {
    final sessions = <SessionInfo>[];
    for (final entry in sessionsByDate.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      if (date.year == month.year && date.month == month.month) {
        sessions.addAll(entry.value);
      }
    }
    sessions.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return _compactTime(a.startTime).compareTo(_compactTime(b.startTime));
    });
    return sessions;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _monthSessions;
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: const Text(
          'No lessons scheduled this month.',
          style: TextStyle(
            color: _kTextMid,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agenda',
            style: TextStyle(
              color: _kTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < sessions.length; i++) ...[
            _AgendaSessionTile(
              session: sessions[i],
              verbalTeacher: verbalTeacher,
              mathTeacher: mathTeacher,
              teachers: teachers,
            ),
            if (i != sessions.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AgendaSessionTile extends StatelessWidget {
  final SessionInfo session;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;

  const _AgendaSessionTile({
    required this.session,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
  });

  @override
  Widget build(BuildContext context) {
    final color = _sessionTypeColor(session.sessionType);
    final date = _parseDate(session.date);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day} ${_shortMonth(date.month)} · ${_formatTimeRange(session.startTime, session.endTime)}',
                  style: const TextStyle(
                    color: _kTextMid,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _capitalize(session.sessionType),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if ((session.topic ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.topic!.trim(),
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<SessionInfo> sessions;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;
  final bool compact;

  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.sessions,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final hasSessions = sessions.isNotEmpty;
  if (compact) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isToday
              ? _kPrimary.withOpacity(0.10)
              : hasSessions
              ? _kPanelBg
              : const Color(0xFFFAFBFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? _kPrimary : _kBorder,
            width: isToday ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 23,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday ? _kPrimary : _kTextDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasSessions
                          ? _sessionTypeColor(sessions.first.sessionType)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
      decoration: BoxDecoration(
        color: isToday
            ? _kPrimary.withOpacity(0.08)
            : hasSessions
            ? _kPanelBg
            : const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? _kPrimary
              : hasSessions
              ? _kBorder
              : const Color(0xFFEAF0FF),
          width: isToday ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: isToday ? _kPrimary : _kTextDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (hasSessions)
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _sessionTypeColor(sessions.first.sessionType),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          if (hasSessions)
            Expanded(
              child: Builder(
                builder: (context) {
                  final visibleSessions = sessions.take(2).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < visibleSessions.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: i < visibleSessions.length - 1 ? 4 : 0,
                            ),
                            child: _CompactSessionChip(
                              session: visibleSessions[i],
                              verbalTeacher: verbalTeacher,
                              mathTeacher: mathTeacher,
                              teachers: teachers,
                            ),
                          ),
                        ),
                      if (sessions.length > 2)
                        _MoreSessionsBadge(count: sessions.length - 2),
                    ],
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Icon(
                  Icons.remove_rounded,
                  color: _kTextLight.withOpacity(0.35),
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactSessionChip extends StatelessWidget {
  final SessionInfo session;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;

  const _CompactSessionChip({
    required this.session,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
  });

  @override
  Widget build(BuildContext context) {
    final color = _sessionTypeColor(session.sessionType);
    final teacher = _teacherLabel(
      session,
      verbalTeacher,
      mathTeacher,
      teachers,
    );
    final time = _formatTimeRange(session.startTime, session.endTime);
    final topic = (session.topic ?? '').trim();
    final typeLabel = _capitalize(session.sessionType);
    final tutorLabel = _compactTeacherName(teacher);

    return Tooltip(
      message: [
        typeLabel,
        if (topic.isNotEmpty) topic,
        time,
        if (teacher.trim().isNotEmpty && teacher != '-') teacher,
      ].join('\n'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: constraints.maxHeight,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: color, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _compactTime(session.startTime),
                  maxLines: 1,
                  style: const TextStyle(
                    color: _kTextMid,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tutorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoreSessionsBadge extends StatelessWidget {
  final int count;

  const _MoreSessionsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _kTextLight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          color: _kTextMid,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _monthYearLabel(DateTime d) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

class _EditClassScheduleDialog extends StatefulWidget {
  final ClassService classService;
  final int classId;
  final List<SessionInfo> sessions;
  final DateTime initialFrom;
  final DateTime initialTo;

  const _EditClassScheduleDialog({
    required this.classService,
    required this.classId,
    required this.sessions,
    required this.initialFrom,
    required this.initialTo,
  });

  @override
  State<_EditClassScheduleDialog> createState() =>
      _EditClassScheduleDialogState();
}

class _EditClassScheduleDialogState extends State<_EditClassScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fromDateController;
  late final TextEditingController _toDateController;
  late final List<DayScheduleEntry> _verbalSchedule;
  late final List<DayScheduleEntry> _mathSchedule;
  late final List<DayScheduleEntry> _mockSchedule;
  late final List<DayScheduleEntry> _verbalReviewSchedule;
  late final List<DayScheduleEntry> _mathReviewSchedule;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fromDateController = TextEditingController(
      text: _formatDateForApi(widget.initialFrom),
    );
    _toDateController = TextEditingController(
      text: _formatDateForApi(widget.initialTo),
    );
    _verbalSchedule = WeeklyScheduleForm.createEntries();
    _mathSchedule = WeeklyScheduleForm.createEntries();
    _mockSchedule = WeeklyScheduleForm.createEntries(
      defaultTime: WeeklyScheduleForm.defaultMockTime,
    );
    _verbalReviewSchedule = WeeklyScheduleForm.createEntries();
    _mathReviewSchedule = WeeklyScheduleForm.createEntries();
    _applyInferredSchedule();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    WeeklyScheduleForm.disposeEntries(_verbalSchedule);
    WeeklyScheduleForm.disposeEntries(_mathSchedule);
    WeeklyScheduleForm.disposeEntries(_mockSchedule);
    WeeklyScheduleForm.disposeEntries(_verbalReviewSchedule);
    WeeklyScheduleForm.disposeEntries(_mathReviewSchedule);
    super.dispose();
  }

  void _applyInferredSchedule() {
    final from = DateTime.tryParse(_fromDateController.text.trim());
    final to = DateTime.tryParse(_toDateController.text.trim());
    if (from == null || to == null) return;
    WeeklyScheduleForm.inferFromSessions(
      sessions: widget.sessions,
      from: _normalizeDate(from),
      to: _normalizeDate(to),
      verbal: _verbalSchedule,
      math: _mathSchedule,
      mock: _mockSchedule,
      verbalReview: _verbalReviewSchedule,
      mathReview: _mathReviewSchedule,
    );
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required DateTime initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      controller.text = _formatDateForApi(picked);
      _applyInferredSchedule();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduleError = WeeklyScheduleForm.validate(
      verbal: _verbalSchedule,
      math: _mathSchedule,
      mock: _mockSchedule,
      verbalReview: _verbalReviewSchedule,
      mathReview: _mathReviewSchedule,
    );
    if (scheduleError != null) {
      setState(() => _error = scheduleError);
      return;
    }

    final from = _fromDateController.text.trim();
    final to = _toDateController.text.trim();
    if (DateTime.parse(from).isAfter(DateTime.parse(to))) {
      setState(() => _error = 'From date must be on or before to date');
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => _DialogShell(
            icon: Icons.warning_amber_rounded,
            title: 'Update schedule?',
            width: 420,
            content: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                'Apply the new weekly pattern from $from to $to?\n\n'
                'Lessons that no longer match may be removed, including '
                'linked homework and attendance.',
                style: const TextStyle(
                  fontSize: 15,
                  color: _kTextMid,
                  height: 1.5,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Yes, update'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.classService.updateClassSchedule(
      classId: widget.classId,
      fromDate: from,
      toDate: to,
      verbalSchedule: WeeklyScheduleForm.buildPayload(_verbalSchedule),
      mathSchedule: WeeklyScheduleForm.buildPayload(_mathSchedule),
      mockSchedule: WeeklyScheduleForm.buildPayload(_mockSchedule),
      verbalReviewSchedule:
          WeeklyScheduleForm.buildPayload(_verbalReviewSchedule),
      mathReviewSchedule: WeeklyScheduleForm.buildPayload(_mathReviewSchedule),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = result['message']?.toString() ?? 'Failed to update schedule';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 36, 10),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_calendar_rounded, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Edit schedule',
              style: TextStyle(
                color: _kPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 14),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose the date range to update. Lessons outside the weekly pattern will be removed inside this range.',
                    style: TextStyle(color: _kTextMid, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fromDateController,
                          enabled: !_saving,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'From date',
                            prefixIcon: Icon(Icons.event_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                          onTap: _saving
                              ? null
                              : () => _pickDate(
                                    controller: _fromDateController,
                                    initial: DateTime.tryParse(
                                          _fromDateController.text,
                                        ) ??
                                        widget.initialFrom,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _toDateController,
                          enabled: !_saving,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'To date',
                            prefixIcon: Icon(Icons.event_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                          onTap: _saving
                              ? null
                              : () => _pickDate(
                                    controller: _toDateController,
                                    initial: DateTime.tryParse(
                                          _toDateController.text,
                                        ) ??
                                        widget.initialTo,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  WeeklyLessonSchedulePicker(
                    title: 'Verbal lessons',
                    icon: Icons.menu_book_rounded,
                    weekdayLabels: WeeklyScheduleLabels.full,
                    days: _verbalSchedule,
                    enabled: !_saving,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  WeeklyLessonSchedulePicker(
                    title: 'Math lessons',
                    icon: Icons.calculate_rounded,
                    weekdayLabels: WeeklyScheduleLabels.full,
                    days: _mathSchedule,
                    enabled: !_saving,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  WeeklyLessonSchedulePicker(
                    title: 'Mock tests',
                    icon: Icons.quiz_rounded,
                    weekdayLabels: WeeklyScheduleLabels.full,
                    days: _mockSchedule,
                    enabled: !_saving,
                    timeHint: WeeklyScheduleForm.defaultMockTime,
                    helperText:
                        'Each mock block lasts 7.5 hours from the start time.',
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  WeeklyLessonSchedulePicker(
                    title: 'Verbal review',
                    icon: Icons.rate_review_rounded,
                    weekdayLabels: WeeklyScheduleLabels.full,
                    days: _verbalReviewSchedule,
                    enabled: !_saving,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  WeeklyLessonSchedulePicker(
                    title: 'Math review',
                    icon: Icons.rate_review_outlined,
                    weekdayLabels: WeeklyScheduleLabels.full,
                    days: _mathReviewSchedule,
                    enabled: !_saving,
                    onChanged: () => setState(() {}),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: _kError, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(_saving ? 'Saving...' : 'Apply'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
