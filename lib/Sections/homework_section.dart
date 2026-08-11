// =====================================================================
// homework_section.dart  —  part of class_detail library
// Contains: _HomeworkPerStudentSection, _HomeworkCard,
//           _AddHomeworkSlotCard, _HwStatus enum
// NEW: delete button for active (deadline not passed) assignments
// =====================================================================

part of class_detail;

enum _HwStatus { notAssigned, notSubmitted, submittedOnTime, submittedLate }

// ─────────────────────────────────────────────────────────────────────
// Per-student homework section: 1..5 slots + "add" card
// ─────────────────────────────────────────────────────────────────────
class _HomeworkPerStudentSection extends StatelessWidget {
  final UserInfo student;
  final List<AssignmentInfo> assignments;
  final Map<int, List<HomeworkResultInfo>> homeworkResultsByAssignment;
  final void Function(String?) onOpenLink;
  final void Function(int slotIndex, AssignmentInfo? assignment)
  onAssignHomework;
  final void Function(AssignmentInfo assignment)? onDeleteHomework;
  final void Function(AssignmentInfo assignment)? onCopyHomeworkToClass;
  final void Function(AssignmentInfo assignment)? onCopyAssignment;
  final bool canEditPastHomework;

  const _HomeworkPerStudentSection({
    required this.student,
    required this.assignments,
    required this.homeworkResultsByAssignment,
    required this.onOpenLink,
    required this.onAssignHomework,
    required this.onDeleteHomework,
    this.onCopyHomeworkToClass,
    this.onCopyAssignment,
    required this.canEditPastHomework,
  });

  @override
  Widget build(BuildContext context) {
    // Build slot map
    final bySlot = <int, AssignmentInfo>{};
    final unslotted = <AssignmentInfo>[];
    for (final a in assignments) {
      final s = a.slotIndex;
      if (s != null && s >= 1 && s <= _kMaxHomeworkSlots) {
        bySlot.putIfAbsent(s, () => a);
      } else {
        unslotted.add(a);
      }
    }
    // Fill unslotted into first available slots
    int u = 0;
    for (int slot = 1; slot <= _kMaxHomeworkSlots; slot++) {
      if (!bySlot.containsKey(slot) && u < unslotted.length) {
        bySlot[slot] = unslotted[u++];
      }
    }

    int highest = 0;
    bySlot.forEach((k, _) {
      if (k > highest) highest = k;
    });
    final visible = highest.clamp(_kMinHomeworkSlots, _kMaxHomeworkSlots);

    final cards = <Widget>[];
    for (int slot = 1; slot <= visible; slot++) {
      final assignment = bySlot[slot];
      final result = assignment == null
          ? null
          : (homeworkResultsByAssignment[assignment.assignmentId] ?? [])
                .where((r) => r.studentId == student.userId)
                .firstOrNull;
      cards.add(
        _HomeworkCard(
          title: 'Homework $slot',
          slotIndex: slot - 1,
          assignment: assignment,
          result: result,
          onOpenLink: onOpenLink,
          onAssignHomework: onAssignHomework,
          onDeleteHomework: onDeleteHomework,
          onCopyHomeworkToClass: onCopyHomeworkToClass,
          onCopyAssignment: onCopyAssignment,
          canEditPastHomework: canEditPastHomework,
        ),
      );
    }
    if (visible < _kMaxHomeworkSlots) {
      cards.add(
        _AddHomeworkSlotCard(
          nextSlot: visible + 1,
          onTap: () => onAssignHomework(visible, null),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: cards,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// "+" card to add the next homework slot
// ─────────────────────────────────────────────────────────────────────
class _AddHomeworkSlotCard extends StatelessWidget {
  final int nextSlot;
  final VoidCallback onTap;
  const _AddHomeworkSlotCard({required this.nextSlot, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _kPrimary.withOpacity(0.35),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            'Add Homework $nextSlot',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nextSlot >= _kMaxHomeworkSlots
                ? 'Last slot available'
                : 'Up to $_kMaxHomeworkSlots per session',
            style: const TextStyle(
              color: _kTextMid,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────
// Individual homework card
// NEW: shows Edit + Delete buttons when deadline has NOT passed
// ─────────────────────────────────────────────────────────────────────
class _HomeworkCard extends StatelessWidget {
  final String title;
  final int slotIndex;
  final AssignmentInfo? assignment;
  final HomeworkResultInfo? result;
  final void Function(String?) onOpenLink;
  final void Function(int slotIndex, AssignmentInfo? assignment)
  onAssignHomework;
  final void Function(AssignmentInfo assignment)? onDeleteHomework;
  final void Function(AssignmentInfo assignment)? onCopyHomeworkToClass;
  final void Function(AssignmentInfo assignment)? onCopyAssignment;
  final bool canEditPastHomework;

  const _HomeworkCard({
    required this.title,
    required this.slotIndex,
    required this.assignment,
    required this.result,
    required this.onOpenLink,
    required this.onAssignHomework,
    required this.onDeleteHomework,
    this.onCopyHomeworkToClass,
    this.onCopyAssignment,
    required this.canEditPastHomework,
  });

  _HwStatus get _status {
    if (assignment == null) return _HwStatus.notAssigned;
    if (result?.submitted == true) {
      return _isSubmittedLate(assignment!, result!)
          ? _HwStatus.submittedLate
          : _HwStatus.submittedOnTime;
    }
    return _HwStatus.notSubmitted;
  }

  Color get _borderColor => switch (_status) {
    _HwStatus.notAssigned => _kBorder,
    _HwStatus.notSubmitted => _kError.withOpacity(0.4),
    _HwStatus.submittedOnTime => _kSuccess.withOpacity(0.5),
    _HwStatus.submittedLate => _kWarning.withOpacity(0.5),
  };

  Color get _bgColor => switch (_status) {
    _HwStatus.notAssigned => _kPanelBg,
    _HwStatus.notSubmitted => _kErrorBg,
    _HwStatus.submittedOnTime => _kSuccessBg,
    _HwStatus.submittedLate => _kWarningBg,
  };

  String get _statusLabel => switch (_status) {
    _HwStatus.notAssigned => 'Not assigned',
    _HwStatus.notSubmitted => 'Not submitted',
    _HwStatus.submittedOnTime => 'Submitted on time',
    _HwStatus.submittedLate => 'Submitted late',
  };

  Color get _statusColor => switch (_status) {
    _HwStatus.notAssigned => _kNeutral,
    _HwStatus.notSubmitted => _kError,
    _HwStatus.submittedOnTime => _kSuccess,
    _HwStatus.submittedLate => _kWarning,
  };

  bool _isSubmittedLate(AssignmentInfo assignment, HomeworkResultInfo result) {
    final submittedAt = DateTime.tryParse(result.submittedAt ?? '');
    if (submittedAt == null) return false;
    final dueAt = _assignmentDueAt(assignment);
    if (dueAt == null) return false;
    return submittedAt.isAfter(dueAt);
  }

  DateTime? _assignmentDueAt(AssignmentInfo assignment) {
    final dueDate = assignment.dueDate;
    if ((dueDate ?? '').isEmpty) return null;
    try {
      final date = _parseDate(dueDate!);
      final time = _compactTime(assignment.dueTime);
      int hour = 23;
      int minute = 59;
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          hour = int.tryParse(parts[0]) ?? 23;
          minute = int.tryParse(parts[1]) ?? 59;
        }
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = assignment;
    final deadlinePassed = _isDeadlinePassed(cur?.dueDate, cur?.dueTime);

    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _kTextDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Body ────────────────────────────────────────────────
          if (cur == null) ...[
            const Text(
              'No homework assigned yet.',
              style: TextStyle(fontSize: 13, color: _kTextMid),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => onAssignHomework(slotIndex, null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Assign'),
            ),
          ] else ...[
            if ((cur.instruction ?? '').isNotEmpty)
              _InfoRow(label: 'Instruction', value: cur.instruction ?? ''),
            if ((cur.taskLink ?? '').isNotEmpty) ...[
              if ((cur.instruction ?? '').isNotEmpty) const SizedBox(height: 8),
              _LinkRow(
                label: 'Task',
                url: cur.taskLink ?? '',
                onOpen: onOpenLink,
              ),
            ],
            if (cur.homeworkDocument != null) ...[
              const SizedBox(height: 10),
              HomeworkPdfSection(
                document: cur.homeworkDocument,
                canManage: false,
                onOpen: () => onOpenLink(cur.homeworkDocument?.url),
              ),
            ],
            if ((cur.dueDate ?? '').isNotEmpty ||
                (cur.dueTime ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Deadline',
                value:
                    '${(cur.dueDate ?? '').isNotEmpty ? cur.dueDate : '—'}'
                            ' ${(cur.dueTime ?? '').isNotEmpty ? _compactTime(cur.dueTime) : ''}'
                        .trim(),
              ),
            ],
            const SizedBox(height: 12),

            // ── Actions ─────────────────────────────────────────
            if (!deadlinePassed) ...[
              // Active: Edit + Delete + Copy to class
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => onAssignHomework(slotIndex, cur),
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text('Edit'),
                  ),
                  if (onCopyAssignment != null)
                    OutlinedButton.icon(
                      onPressed: () => onCopyAssignment!(cur),
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: _kPrimary,
                      ),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withOpacity(0.45)),
                      ),
                    ),
                  if (onCopyHomeworkToClass != null)
                    OutlinedButton.icon(
                      onPressed: () => onCopyHomeworkToClass!(cur),
                      icon: const Icon(
                        Icons.copy_all_rounded,
                        size: 16,
                        color: _kPrimary,
                      ),
                      label: const Text('Copy to class'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withOpacity(0.45)),
                      ),
                    ),
                  if (onDeleteHomework != null)
                    OutlinedButton.icon(
                      onPressed: () => onDeleteHomework!(cur),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: _kError,
                      ),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kError,
                        side: BorderSide(color: _kError.withOpacity(0.5)),
                      ),
                    ),
                ],
              ),
            ] else ...[
              if (canEditPastHomework ||
                  onCopyAssignment != null ||
                  onCopyHomeworkToClass != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canEditPastHomework)
                      FilledButton.icon(
                        onPressed: () => onAssignHomework(slotIndex, cur),
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text('Edit'),
                      ),
                    if (onCopyAssignment != null)
                      OutlinedButton.icon(
                        onPressed: () => onCopyAssignment!(cur),
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: _kPrimary,
                        ),
                        label: const Text('Copy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: BorderSide(color: _kPrimary.withOpacity(0.45)),
                        ),
                      ),
                    if (onCopyHomeworkToClass != null)
                      OutlinedButton.icon(
                        onPressed: () => onCopyHomeworkToClass!(cur),
                        icon: const Icon(
                          Icons.copy_all_rounded,
                          size: 16,
                          color: _kPrimary,
                        ),
                        label: const Text('Copy to class'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: BorderSide(color: _kPrimary.withOpacity(0.45)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // Past: show result
              if (result?.submitted == true) ...[
                if ((result?.photoLink ?? '').isNotEmpty)
                  _LinkRow(
                    label: 'Proof',
                    url: result?.photoLink ?? '',
                    onOpen: onOpenLink,
                  ),
                if ((result?.submittedAt ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Submitted at',
                    value: result?.submittedAt ?? '',
                  ),
                ],
                if ((result?.analysis ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Analysis', value: result?.analysis ?? ''),
                ],
                if (result?.correctTotal != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Score', value: '${result!.correctTotal}'),
                ],
              ] else ...[
                const Text(
                  'Not submitted.',
                  style: TextStyle(
                    color: _kError,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
