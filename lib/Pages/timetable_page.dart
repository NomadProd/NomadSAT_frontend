part of class_detail;

class TimetablePage extends StatefulWidget {
  final String className;
  final List<SessionInfo> sessions;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;

  const TimetablePage({
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
  int _selectedMonthIndex = 0;

  List<DateTime> get _visibleMonths {
    if (widget.sessions.isEmpty)
      return [DateTime(DateTime.now().year, DateTime.now().month)];

    final dates = widget.sessions.map((s) => _parseDate(s.date)).toList()
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
    for (final session in widget.sessions) {
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
              sessionCount: widget.sessions.length,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _MonthSwitcher(
                    monthLabel: _monthYearLabel(selectedMonth),
                    rangeLabel: months.length == 1
                        ? null
                        : '${_monthYearLabel(months.first)} - ${_monthYearLabel(months.last)}',
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
                  ),
                ],
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
  final VoidCallback onBack;

  const _TimetableHeader({
    required this.className,
    required this.sessionCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => TuranHeader(
    title: 'Timetable',
    subtitle: className,
    pageLabel: 'Schedule',
    onBack: onBack,
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

class _MonthSwitcher extends StatelessWidget {
  final String monthLabel;
  final String? rangeLabel;
  final bool canGoPrevious, canGoNext;
  final VoidCallback? onPrevious, onNext;

  const _MonthSwitcher({
    required this.monthLabel,
    required this.rangeLabel,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _CalendarNavButton(
            icon: Icons.chevron_left_rounded,
            enabled: canGoPrevious,
            onTap: onPrevious,
          ),
          const SizedBox(width: 12),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (rangeLabel != null)
                  Text(
                    rangeLabel!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextMid,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final Map<String, List<SessionInfo>> sessionsByDate;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;

  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.sessionsByDate,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
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
    final cells = _cells;
    final rows = (cells.length / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: _kTextLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows * 7,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              childAspectRatio: MediaQuery.of(context).size.width < 620
                  ? 0.95
                  : 1.45,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              if (day == null) return const SizedBox.shrink();
              final key = _formatDateForApi(day);
              final daySessions = sessionsByDate[key] ?? const <SessionInfo>[];
              return _MonthDayCell(
                day: day,
                isToday: _normalizeDate(day) == today,
                sessions: daySessions,
                verbalTeacher: verbalTeacher,
                mathTeacher: mathTeacher,
                teachers: teachers,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<SessionInfo> sessions;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;

  const _MonthDayCell({
    required this.day,
    required this.isToday,
    required this.sessions,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
  });

  @override
  Widget build(BuildContext context) {
    final hasSessions = sessions.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(8),
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
          const SizedBox(height: 6),
          if (hasSessions)
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final session in sessions.take(2))
                  _CompactSessionChip(
                    session: session,
                    verbalTeacher: verbalTeacher,
                    mathTeacher: mathTeacher,
                    teachers: teachers,
                  ),
                if (sessions.length > 2)
                  _MoreSessionsBadge(count: sessions.length - 2),
              ],
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

    return Tooltip(
      message: [
        _capitalize(session.sessionType),
        if (session.topic?.trim().isNotEmpty ?? false) session.topic!.trim(),
        time,
        if (teacher.trim().isNotEmpty) teacher,
      ].join('\n'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_compactTime(session.startTime)} ${_capitalize(session.sessionType)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            if ((session.topic ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  session.topic!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
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
