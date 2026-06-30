// =====================================================================
// mock_section.dart  -  part of class_detail library
// Contains: _MockInlineSection, _MockScoreHero
// =====================================================================

part of class_detail;

class _MockInlineSection extends StatelessWidget {
  final UserInfo student;
  final List<AssignmentInfo> assignments;
  final Map<int, List<MockResultInfo>> mockResultsByAssignment;
  final void Function(String?) onOpenLink;

  const _MockInlineSection({
    required this.student,
    required this.assignments,
    required this.mockResultsByAssignment,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return const _EmptyCard(
        width: 560,
        icon: Icons.quiz_outlined,
        message: 'Mock not assigned',
      );
    }

    final result = assignments
        .expand(
          (a) => mockResultsByAssignment[a.assignmentId] ?? <MockResultInfo>[],
        )
        .where((r) => r.studentId == student.userId && r.submitted)
        .firstOrNull;

    if (result == null) {
      return const _EmptyCard(
        width: 560,
        icon: Icons.pending_outlined,
        message: 'Not submitted yet',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 620,
        decoration: const BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: _BrandPattern(baseColor: Colors.white, opacity: 0.08),
            ),
            // Glow accent
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: _LogoMark(size: 26, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'SAT Mock Result',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Turan SAT - Official mock exam',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (result.totalPoints != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF9A825),
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${result.totalPoints}',
                                style: const TextStyle(
                                  color: _kPrimaryDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'pts',
                                style: TextStyle(
                                  color: _kTextMid,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Score panels
                  Row(
                    children: [
                      Expanded(
                        child: _MockScoreHero(
                          label: 'Verbal',
                          score: result.verbalPoints,
                          incorrect: result.verbalIncorrect,
                          accent: const Color(0xFFE1BEE7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MockScoreHero(
                          label: 'Math',
                          score: result.mathPoints,
                          incorrect: result.mathIncorrect,
                          accent: const Color(0xFFB2DFDB),
                        ),
                      ),
                    ],
                  ),
                  // Weak areas
                  if ((result.weakAreas ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.insights_rounded,
                            color: Colors.white.withOpacity(0.85),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WEAK AREAS',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  result.weakAreas ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Proof files
                  if (result.attachments.isNotEmpty ||
                      (result.photoLink ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (result.attachments.isNotEmpty)
                      for (final file in result.attachments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            onTap: () => onOpenLink(file.url),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_file_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.filename,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                    else if ((result.photoLink ?? '').isNotEmpty)
                      InkWell(
                        onTap: () => onOpenLink(result.photoLink),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.photo_outlined,
                                color: Colors.white.withOpacity(0.9),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'View proof',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Score panel в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _MockScoreHero extends StatelessWidget {
  final String label;
  final num? score, incorrect;
  final Color accent;

  const _MockScoreHero({
    required this.label,
    required this.score,
    required this.incorrect,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _kTextMid,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              score != null ? '$score' : '-',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: _kPrimaryDark,
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'pts',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kErrorBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close_rounded, size: 12, color: _kError),
              const SizedBox(width: 3),
              Text(
                incorrect != null ? '$incorrect incorrect' : '-',
                style: const TextStyle(
                  fontSize: 11,
                  color: _kError,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
