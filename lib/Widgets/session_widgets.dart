// =====================================================================
// session_widgets.dart  —  part of class_detail library
// Contains: _WeeklySessionDateStrip, _SessionMetaCard, _MetaItem,
//           _MetaActionButton, _StudentSessionRow, _AttendanceChip
// =====================================================================

part of class_detail;

// ─────────────────────────────────────────────────────────────────────
// Session meta card
// ─────────────────────────────────────────────────────────────────────
class _WeeklySessionDateStrip extends StatelessWidget {
  final List<SessionInfo> sessions;
  final int selectedSessionId;
  final DateTime weekAnchor;
  final VoidCallback onPreviousWeek, onNextWeek, onToday;
  final ValueChanged<int> onSelect;

  const _WeeklySessionDateStrip({
    required this.sessions,
    required this.selectedSessionId,
    required this.weekAnchor,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.onSelect,
  });

  DateTime get _weekStart {
    final d = _normalizeDate(weekAnchor);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<SessionInfo> _sessionsForDay(DateTime day) {
    final target = _formatDateForApi(day);
    return [...sessions.where((s) => s.date == target)]..sort(
      (a, b) => _compactTime(a.startTime).compareTo(_compactTime(b.startTime)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _weekDays;
    final rangeLabel =
        '${_formatDateHuman(days.first)} - ${_formatDateHuman(days.last)}';
    final today = _normalizeDate(DateTime.now());

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _WeekNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousWeek,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_view_week_rounded,
                      color: _kPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        rangeLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kTextDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onToday,
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('TODAY'),
              ),
              const SizedBox(width: 6),
              _WeekNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextWeek,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final day = days[index];
                return _WeekDaySessionCard(
                  day: day,
                  isToday: _normalizeDate(day) == today,
                  sessions: _sessionsForDay(day),
                  selectedSessionId: selectedSessionId,
                  onSelect: onSelect,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _WeekNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _kPanelBg,
        shape: BoxShape.circle,
        border: Border.all(color: _kBorder),
      ),
      child: Icon(icon, color: _kPrimary, size: 20),
    ),
  );
}

class _WeekDaySessionCard extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<SessionInfo> sessions;
  final int selectedSessionId;
  final ValueChanged<int> onSelect;

  const _WeekDaySessionCard({
    required this.day,
    required this.isToday,
    required this.sessions,
    required this.selectedSessionId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelected = sessions.any((s) => s.sessionId == selectedSessionId);
    final daySessionId = sessions.isEmpty ? null : sessions.first.sessionId;

    return InkWell(
      onTap: daySessionId == null ? null : () => onSelect(daySessionId),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: hasSelected ? const Color(0xFFEBF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasSelected
                ? _kPrimary
                : isToday
                ? _kPrimary.withOpacity(0.5)
                : _kBorder,
            width: hasSelected ? 2 : 1,
          ),
          boxShadow: hasSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _weekdayShort(day).toUpperCase(),
                  style: TextStyle(
                    color: isToday ? _kPrimary : _kTextMid,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  '${day.day.toString().padLeft(2, '0')} ${_shortMonth(day.month)}',
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sessions.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No sessions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kTextLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    final selected = s.sessionId == selectedSessionId;
                    final color = _sessionTypeColor(s.sessionType);
                    return InkWell(
                      onTap: () => onSelect(s.sessionId),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? color : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.sessionType.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected ? Colors.white : color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Text(
                              _compactTime(s.startTime),
                              style: TextStyle(
                                color: selected ? Colors.white : _kTextMid,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionMetaCard extends StatelessWidget {
  final SessionInfo session;
  final UserInfo? verbalTeacher, mathTeacher;
  final List<UserInfo> teachers;
  final bool canManageClass;
  final VoidCallback onStudents, onSessions;

  const _SessionMetaCard({
    required this.session,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.teachers,
    required this.canManageClass,
    required this.onStudents,
    required this.onSessions,
  });

  @override
  Widget build(BuildContext context) {
    final teacher = _teacherLabel(
      session,
      verbalTeacher,
      mathTeacher,
      teachers,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final narrow = c.maxWidth < 900;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: narrow || !canManageClass
                    ? c.maxWidth
                    : c.maxWidth - 236,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaItem(label: 'Teacher', value: teacher),
                    _MetaItem(
                      label: 'Topic',
                      value: (session.topic ?? '').isNotEmpty
                          ? session.topic!
                          : '—',
                    ),
                  ],
                ),
              ),
              if (canManageClass)
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MetaActionButton(
                        icon: Icons.group_rounded,
                        label: 'Students',
                        onTap: onStudents,
                      ),
                      const SizedBox(height: 8),
                      _MetaActionButton(
                        icon: Icons.calendar_month_rounded,
                        label: 'Sessions',
                        onTap: onSessions,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label, value;
  final Color? accent;
  const _MetaItem({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kPanelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kTextLight,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accent ?? _kTextDark,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetaActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MetaActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      side: const BorderSide(color: _kBorder),
      foregroundColor: _kPrimary,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Student session row
// ─────────────────────────────────────────────────────────────────────
class _StudentSessionRow extends StatelessWidget {
  final UserInfo student;
  final SessionInfo session;
  final AttendanceInfo? attendance;
  final List<AssignmentInfo> assignments;
  final Map<int, List<HomeworkResultInfo>> homeworkResultsByAssignment;
  final Map<int, List<MockResultInfo>> mockResultsByAssignment;
  final bool canOpenStudent;
  final VoidCallback onOpenStudent;
  final void Function(int slotIndex, AssignmentInfo? assignment)
  onAssignHomework;
  final void Function(AssignmentInfo assignment)? onDeleteHomework;
  final void Function(AssignmentInfo assignment)? onCopyHomeworkToClass;
  final void Function(String? url) onOpenLink;
  final VoidCallback onToggleAttendance;

  const _StudentSessionRow({
    required this.student,
    required this.session,
    required this.attendance,
    required this.assignments,
    required this.homeworkResultsByAssignment,
    required this.mockResultsByAssignment,
    required this.canOpenStudent,
    required this.onOpenStudent,
    required this.onAssignHomework,
    required this.onDeleteHomework,
    this.onCopyHomeworkToClass,
    required this.onOpenLink,
    required this.onToggleAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final isMock = _isMockSession(session);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — student info
          InkWell(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            onTap: canOpenStudent ? onOpenStudent : null,
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InitialsAvatar(
                    name: student.name,
                    surname: student.surname,
                    size: 38,
                    fontSize: 14,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${student.name} ${student.surname}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ID: ${student.userId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTextLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, color: _kBorder),
          // Right — homework / mock
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  _AttendanceChip(
                    attendance: attendance,
                    onTap: onToggleAttendance,
                  ),
                  if (isMock)
                    _MockInlineSection(
                      student: student,
                      assignments: assignments,
                      mockResultsByAssignment: mockResultsByAssignment,
                      onOpenLink: onOpenLink,
                    )
                  else
                    _HomeworkPerStudentSection(
                      student: student,
                      assignments: assignments,
                      homeworkResultsByAssignment: homeworkResultsByAssignment,
                      onOpenLink: onOpenLink,
                      onAssignHomework: onAssignHomework,
                      onDeleteHomework: onDeleteHomework,
                      onCopyHomeworkToClass: onCopyHomeworkToClass,
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

// ─────────────────────────────────────────────────────────────────────
// Attendance chip
// ─────────────────────────────────────────────────────────────────────
class _AttendanceChip extends StatelessWidget {
  final AttendanceInfo? attendance;
  final VoidCallback? onTap;
  const _AttendanceChip({required this.attendance, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = attendance?.status;

    final Color bg, fg;
    final IconData icon;
    final String text;

    if (status == null) {
      bg = _kNeutralBg;
      fg = _kNeutral;
      icon = Icons.help_outline_rounded;
      text = 'No record';
    } else if (status == AttendanceInfo.present) {
      bg = _kSuccessBg;
      fg = _kSuccess;
      icon = Icons.check_circle_outline_rounded;
      text = 'Present';
    } else if (status == AttendanceInfo.excused) {
      bg = _kWarningBg;
      fg = _kWarning;
      icon = Icons.event_busy_rounded;
      text = 'Excused';
    } else {
      bg = _kErrorBg;
      fg = _kError;
      icon = Icons.cancel_outlined;
      text = 'Absent';
    }

    return Tooltip(
      message: 'Tap to cycle: Present → Absent → Excused',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fg.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
