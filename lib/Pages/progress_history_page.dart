import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Utils/homework_pdf.dart';
import 'package:flutter_web/Utils/assignment_title.dart';
import 'package:flutter_web/theme/turan_theme.dart';

const _kPrimary = TuranColors.primary;
const _kBg = TuranColors.bg;
const _kBorder = TuranColors.border;
const _kTextDark = TuranColors.textDark;
const _kTextMid = TuranColors.textMid;
const _kTextLight = TuranColors.textLight;
const _kSuccess = TuranColors.success;
const _kError = TuranColors.error;
const _kMock = TuranColors.mock;

class ProgressHistoryPage extends StatefulWidget {
  final UserInfo student;

  const ProgressHistoryPage({super.key, required this.student});

  @override
  State<ProgressHistoryPage> createState() => _ProgressHistoryPageState();
}

class _ProgressHistoryPageState extends State<ProgressHistoryPage> {
  final _classService = ClassService();
  late Future<_ProgressHistoryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
  }

  Future<_ProgressHistoryData> _loadHistory() async {
    final history = await Future.wait([
      _classService.fetchStudentHomeworkHistory(widget.student.userId),
      _classService.fetchStudentMockHistory(widget.student.userId),
    ]);

    final homework = history[0]
        .cast<StudentHomeworkHistoryInfo>()
        .where((entry) => entry.result.submitted)
        .map(
          (entry) => _HomeworkHistoryItem(
            classInfo: entry.classInfo,
            session: entry.session,
            assignment: entry.assignment,
            result: entry.result,
          ),
        )
        .toList();

    final mocks = history[1]
        .cast<StudentMockHistoryInfo>()
        .where((entry) => entry.result.submitted)
        .map(
          (entry) => _MockHistoryItem(
            classInfo: entry.classInfo,
            session: entry.session,
            assignment: entry.assignment,
            result: entry.result,
          ),
        )
        .toList();

    homework.sort((a, b) => b.date.compareTo(a.date));
    mocks.sort((a, b) => b.date.compareTo(a.date));

    return _ProgressHistoryData(homework: homework, mocks: mocks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<_ProgressHistoryData>(
        future: _future,
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          return Column(
            children: [
              _HistoryHeader(student: widget.student),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _DotPattern()),
                    if (loading)
                      const Center(
                        child: CircularProgressIndicator(color: _kPrimary),
                      )
                    else if (snap.hasError)
                      _HistoryError(
                        message: userFacingError(snap.error!),
                        onRetry: () => setState(() => _future = _loadHistory()),
                      )
                    else
                      _HistoryBody(
                        data: snap.data!,
                        onRefresh: () async {
                          final next = _loadHistory();
                          setState(() => _future = next);
                          await next;
                        },
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

enum _HistoryResultView { verbal, math, mock }

class _HistoryBody extends StatefulWidget {
  final _ProgressHistoryData data;
  final Future<void> Function() onRefresh;

  const _HistoryBody({required this.data, required this.onRefresh});

  @override
  State<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<_HistoryBody> {
  _HistoryResultView _selectedView = _HistoryResultView.verbal;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          _ResultViewSwitch(
            selectedView: _selectedView,
            onChanged: (view) => setState(() => _selectedView = view),
            verbalCount: widget.data.verbalHomework.length,
            mathCount: widget.data.mathHomework.length,
            mockCount: widget.data.mocks.length,
          ),
          const SizedBox(height: 16),
          if (_selectedView == _HistoryResultView.verbal)
            _HomeworkHistorySection(
              title: 'Verbal Homework Results',
              color: TuranColors.verbal,
              items: widget.data.verbalHomework,
            )
          else if (_selectedView == _HistoryResultView.math)
            _HomeworkHistorySection(
              title: 'Math Homework Results',
              color: TuranColors.math,
              items: widget.data.mathHomework,
            )
          else ...[
            _MockVerbalHistorySection(items: widget.data.mocks),
            const SizedBox(height: 16),
            _MockMathHistorySection(items: widget.data.mocks),
          ],
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final UserInfo student;

  const _HistoryHeader({required this.student});

  String get _initials =>
      '${student.name.isNotEmpty ? student.name[0] : ''}'
              '${student.surname.isNotEmpty ? student.surname[0] : ''}'
          .toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kPrimary,
        boxShadow: [
          BoxShadow(
            color: Color(0x331A4AF0),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 18, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                tooltip: 'Back',
              ),
              const SizedBox(width: 6),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.32)),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Progress history',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultViewSwitch extends StatelessWidget {
  final _HistoryResultView selectedView;
  final ValueChanged<_HistoryResultView> onChanged;
  final int verbalCount;
  final int mathCount;
  final int mockCount;

  const _ResultViewSwitch({
    required this.selectedView,
    required this.onChanged,
    required this.verbalCount,
    required this.mathCount,
    required this.mockCount,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _ResultViewOption(
        view: _HistoryResultView.verbal,
        label: 'Verbal',
        count: verbalCount,
        icon: Icons.menu_book_rounded,
        color: TuranColors.verbal,
      ),
      _ResultViewOption(
        view: _HistoryResultView.math,
        label: 'Math',
        count: mathCount,
        icon: Icons.calculate_rounded,
        color: TuranColors.math,
      ),
      _ResultViewOption(
        view: _HistoryResultView.mock,
        label: 'Mock',
        count: mockCount,
        icon: Icons.workspace_premium_rounded,
        color: _kMock,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;
          final buttonWidth = narrow
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / options.length;

          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in options)
                SizedBox(
                  width: buttonWidth,
                  child: _ResultViewButton(
                    option: option,
                    selected: selectedView == option.view,
                    onTap: () => onChanged(option.view),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultViewOption {
  final _HistoryResultView view;
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _ResultViewOption({
    required this.view,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class _ResultViewButton extends StatelessWidget {
  final _ResultViewOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ResultViewButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = option.color;
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                color: selected ? Colors.white : color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _kTextDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.18)
                      : color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  option.count.toString(),
                  style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeworkHistorySection extends StatelessWidget {
  final String title;
  final Color color;
  final List<_HomeworkHistoryItem> items;

  const _HomeworkHistorySection({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scored = items.where((item) => item.score != null).toList();
    return _HistorySection(
      title: title,
      subtitle: 'Assignments, status, task details, score, and change',
      icon: Icons.assignment_turned_in_rounded,
      color: color,
      emptyMessage: 'No homework results yet',
      isEmpty: items.isEmpty,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HomeworkHistoryCard(
                      item: item,
                      delta: _homeworkDelta(item, scored),
                      color: color,
                    ),
                  ),
              ],
            );
          }
          return _ExcelTable(
            minWidth: 1366,
            columns: const [
              _TableColumn('Date', 96),
              _TableColumn('Class', 140),
              _TableColumn('Task / instruction', 280),
              _TableColumn('Status', 112),
              _TableColumn('Proof', 86),
              _TableColumn('Score', 90),
              _TableColumn('Delta', 94),
              _TableColumn('Correct', 78),
              _TableColumn('Wrong', 78),
              _TableColumn('Analysis', 360),
            ],
            rows: [
              for (final item in items)
                _HomeworkResultRow(
                  item: item,
                  delta: _homeworkDelta(item, scored),
                  color: color,
                ),
            ],
          );
        },
      ),
    );
  }

  double? _homeworkDelta(
    _HomeworkHistoryItem item,
    List<_HomeworkHistoryItem> scored,
  ) {
    final score = item.score;
    if (score == null) return null;
    final index = scored.indexOf(item);
    if (index < 0 || index + 1 >= scored.length) return null;
    final previousScore = scored[index + 1].score;
    return previousScore == null ? null : score - previousScore;
  }
}

class _MockVerbalHistorySection extends StatelessWidget {
  final List<_MockHistoryItem> items;

  const _MockVerbalHistorySection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _HistorySection(
      title: 'Mock Verbal Progress',
      subtitle: 'Verbal points compared to your previous mock',
      icon: Icons.menu_book_rounded,
      color: TuranColors.verbal,
      emptyMessage: 'No mock verbal results yet',
      isEmpty: items.isEmpty,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MockScoreCard(
                      item: items[i],
                      previousItem: i + 1 < items.length ? items[i + 1] : null,
                      scoreLabel: 'Verbal',
                      score: items[i].verbalScore,
                      previousScore: i + 1 < items.length
                          ? items[i + 1].verbalScore
                          : null,
                      color: TuranColors.verbal,
                    ),
                  ),
              ],
            );
          }
          return _ExcelTable(
            minWidth: 620,
            columns: const [
              _TableColumn('Date', 96),
              _TableColumn('Class', 150),
              _TableColumn('Verbal', 86),
              _TableColumn('Verbal Delta', 110),
            ],
            rows: [
              for (var i = 0; i < items.length; i++)
                _MockScoreRow(
                  item: items[i],
                  previousItem: i + 1 < items.length ? items[i + 1] : null,
                  score: items[i].verbalScore,
                  previousScore: i + 1 < items.length
                      ? items[i + 1].verbalScore
                      : null,
                  color: TuranColors.verbal,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MockMathHistorySection extends StatelessWidget {
  final List<_MockHistoryItem> items;

  const _MockMathHistorySection({required this.items});

  @override
  Widget build(BuildContext context) {
    return _HistorySection(
      title: 'Mock Math Progress',
      subtitle: 'Math points compared to your previous mock',
      icon: Icons.calculate_rounded,
      color: TuranColors.math,
      emptyMessage: 'No mock math results yet',
      isEmpty: items.isEmpty,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MockScoreCard(
                      item: items[i],
                      previousItem: i + 1 < items.length ? items[i + 1] : null,
                      scoreLabel: 'Math',
                      score: items[i].mathScore,
                      previousScore: i + 1 < items.length
                          ? items[i + 1].mathScore
                          : null,
                      color: TuranColors.math,
                    ),
                  ),
              ],
            );
          }
          return _ExcelTable(
            minWidth: 620,
            columns: const [
              _TableColumn('Date', 96),
              _TableColumn('Class', 150),
              _TableColumn('Math', 86),
              _TableColumn('Math Delta', 110),
            ],
            rows: [
              for (var i = 0; i < items.length; i++)
                _MockScoreRow(
                  item: items[i],
                  previousItem: i + 1 < items.length ? items[i + 1] : null,
                  score: items[i].mathScore,
                  previousScore: i + 1 < items.length
                      ? items[i + 1].mathScore
                      : null,
                  color: TuranColors.math,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MockScoreRow extends StatelessWidget {
  final _MockHistoryItem item;
  final _MockHistoryItem? previousItem;
  final double score;
  final double? previousScore;
  final Color color;

  const _MockScoreRow({
    required this.item,
    required this.previousItem,
    required this.score,
    required this.previousScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _TableRowShell(
      children: [
        _TextCell(width: 96, text: _formatDateShort(item.date)),
        _TextCell(width: 150, text: item.classInfo.className),
        _TextCell(width: 86, text: '${score.toInt()}', strong: true),
        _DeltaCell(
          width: 110,
          delta: previousScore == null ? null : score - previousScore!,
        ),
      ],
    );
  }
}

class _MockScoreCard extends StatelessWidget {
  final _MockHistoryItem item;
  final _MockHistoryItem? previousItem;
  final String scoreLabel;
  final double score;
  final double? previousScore;
  final Color color;

  const _MockScoreCard({
    required this.item,
    required this.previousItem,
    required this.scoreLabel,
    required this.score,
    required this.previousScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final delta = previousScore == null ? null : score - previousScore!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatDateShort(item.date)} · ${item.classInfo.className}',
            style: const TextStyle(
              color: _kTextMid,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$scoreLabel: ${score.toInt()}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _DeltaBadge(delta: delta, unit: ' pt'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeworkHistoryCard extends StatelessWidget {
  final _HomeworkHistoryItem item;
  final double? delta;
  final Color color;

  const _HomeworkHistoryCard({
    required this.item,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final result = item.result;
    final task = (item.assignment.title ?? item.assignment.instruction ?? '')
        .trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatDateShort(item.date)} · ${item.classInfo.className}',
            style: const TextStyle(
              color: _kTextMid,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task.isEmpty ? 'Homework task' : task,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TinyBadge(
                label: item.status.label,
                icon: item.status.icon,
                color: item.status.color,
              ),
              const Spacer(),
              Text(
                item.score == null ? '-' : '${item.score!.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              _DeltaBadge(delta: delta, unit: '%'),
            ],
          ),
          if ((result?.analysis ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result!.analysis!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kTextMid,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String emptyMessage;
  final Widget child;
  final bool isEmpty;

  const _HistorySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.emptyMessage,
    required this.child,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _kTextDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isEmpty)
            _EmptyHistoryMessage(message: emptyMessage, color: color)
          else
            child,
        ],
      ),
    );
  }
}

class _TableColumn {
  final String label;
  final double width;

  const _TableColumn(this.label, this.width);
}

class _ExcelTable extends StatelessWidget {
  final double minWidth;
  final List<_TableColumn> columns;
  final List<Widget> rows;

  const _ExcelTable({
    required this.minWidth,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final tableWidth = columns.fold<double>(
      0,
      (total, column) => total + column.width,
    );
    final contentWidth = tableWidth > minWidth ? tableWidth : minWidth;
    final width = contentWidth + 2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: columns
                    .map(
                      (column) =>
                          _HeaderCell(label: column.label, width: column.width),
                    )
                    .toList(),
              ),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1)
                const Divider(height: 1, color: _kBorder),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;

  const _HeaderCell({required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kTextMid,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HomeworkResultRow extends StatelessWidget {
  final _HomeworkHistoryItem item;
  final double? delta;
  final Color color;

  const _HomeworkResultRow({
    required this.item,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final result = item.result;
    return _TableRowShell(
      children: [
        _TextCell(width: 96, text: _formatDateShort(item.date)),
        _TextCell(width: 140, text: item.classInfo.className),
        _TaskCell(width: 280, item: item, color: color),
        _StatusCell(width: 112, status: item.status),
        _ProofLinkCell(width: 86, photoLink: result?.photoLink, color: color),
        _TextCell(
          width: 90,
          text: item.score == null ? '-' : '${item.score!.toStringAsFixed(1)}%',
          strong: item.score != null,
        ),
        SizedBox(
          width: 94,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _DeltaBadge(delta: delta, unit: '%'),
            ),
          ),
        ),
        _TextCell(width: 78, text: result?.correctTotal?.toString() ?? '-'),
        _TextCell(width: 78, text: result?.incorrectTotal?.toString() ?? '-'),
        _LongTextCell(width: 360, text: _textOrDash(result?.analysis)),
      ],
    );
  }
}

class _ProofLinkCell extends StatelessWidget {
  final double width;
  final String? photoLink;
  final Color color;

  const _ProofLinkCell({
    required this.width,
    required this.photoLink,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final link = (photoLink ?? '').trim();
    if (link.isEmpty) {
      return _TextCell(width: width, text: '-');
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: 'Open photo proof',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openExternalLink(link),
              child: Container(
                width: 32,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Icon(Icons.image_search_rounded, color: color, size: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeltaCell extends StatelessWidget {
  final double width;
  final double? delta;

  const _DeltaCell({required this.width, required this.delta});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _DeltaBadge(delta: delta, unit: 'pt'),
        ),
      ),
    );
  }
}

class _TableRowShell extends StatelessWidget {
  final List<Widget> children;

  const _TableRowShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final double width;
  final String text;
  final bool strong;

  const _TextCell({
    required this.width,
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: strong ? _kTextDark : _kTextMid,
              fontSize: 12,
              height: 1.25,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LongTextCell extends StatelessWidget {
  final double width;
  final String text;

  const _LongTextCell({
    required this.width,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            text,
            style: const TextStyle(
              color: _kTextMid,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCell extends StatelessWidget {
  final double width;
  final _HomeworkHistoryItem item;
  final Color color;

  const _TaskCell({
    required this.width,
    required this.item,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final link = (item.assignment.taskLink ?? '').trim();
    final instruction = (item.assignment.instruction ?? '').trim();
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _assignmentTitle(item.assignment, item.session),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (instruction.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      instruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextLight,
                        fontSize: 10,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (link.isNotEmpty) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Open task link',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openExternalLink(link),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.16)),
                    ),
                    child: Icon(
                      Icons.open_in_new_rounded,
                      color: color,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
            if ((item.assignment.homeworkDocument?.url ?? '').isNotEmpty) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Open PDF',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    try {
                      final pdfUrl = item.assignment.homeworkDocument!.url;
                      final opened = html.window.open(pdfUrl, '_blank');
                      if (opened == null) {
                        throw StateError('popup blocked');
                      }
                    } catch (_) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(
                          content: Text(homeworkPdfOpenErrorMessage),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.16)),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: color,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final double width;
  final _HomeworkStatus status;

  const _StatusCell({required this.width, required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _TinyBadge(
            label: status.label,
            icon: status.icon,
            color: status.color,
          ),
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double? delta;
  final String unit;

  const _DeltaBadge({required this.delta, required this.unit});

  @override
  Widget build(BuildContext context) {
    final value = delta;
    if (value == null) {
      return const SizedBox.shrink();
    }
    if (value == 0) {
      return const _TinyBadge(
        label: 'No change',
        icon: Icons.remove_rounded,
        color: _kTextLight,
      );
    }

    final isUp = value > 0;
    final color = isUp ? _kSuccess : _kError;
    final number = unit == 'pt'
        ? value.abs().toStringAsFixed(0)
        : value.abs().toStringAsFixed(1);
    return _TinyBadge(
      label: '${isUp ? '+' : '-'}$number $unit',
      icon: isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      color: color,
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TinyBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryMessage extends StatelessWidget {
  final String message;
  final Color color;

  const _EmptyHistoryMessage({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HistoryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 42, color: _kPrimary),
            const SizedBox(height: 14),
            const Text(
              'Could not load history',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextMid, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotPatternPainter());
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kPrimary.withOpacity(0.045)
      ..style = PaintingStyle.fill;

    const spacing = 22.0;
    const radius = 1.5;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressHistoryData {
  final List<_HomeworkHistoryItem> homework;
  final List<_MockHistoryItem> mocks;

  const _ProgressHistoryData({required this.homework, required this.mocks});

  List<_HomeworkHistoryItem> get verbalHomework => homework
      .where((item) => item.session.sessionType.toLowerCase() == 'verbal')
      .toList();

  List<_HomeworkHistoryItem> get mathHomework => homework
      .where((item) => item.session.sessionType.toLowerCase() == 'math')
      .toList();
}

class _HomeworkHistoryItem {
  final ClassInfo classInfo;
  final SessionInfo session;
  final AssignmentInfo assignment;
  final HomeworkResultInfo? result;

  const _HomeworkHistoryItem({
    required this.classInfo,
    required this.session,
    required this.assignment,
    required this.result,
  });

  DateTime get date =>
      DateTime.tryParse(result?.submittedAt ?? '') ??
      _deadlineFromParts(assignment.dueDate, assignment.dueTime);

  double? get score {
    final submittedResult = result;
    if (submittedResult == null) return null;
    if (submittedResult.accuracy != null) return submittedResult.accuracy!;
    final correct = submittedResult.correctTotal ?? 0;
    final incorrect = submittedResult.incorrectTotal ?? 0;
    final total = correct + incorrect;
    return total == 0 ? 0 : (correct / total) * 100;
  }

  _HomeworkStatus get status {
    final submittedResult = result;
    if (submittedResult == null) {
      return DateTime.now().isAfter(deadline)
          ? _HomeworkStatus.missed
          : _HomeworkStatus.pending;
    }
    final submittedAt = DateTime.tryParse(submittedResult.submittedAt ?? '');
    if (submittedAt == null) return _HomeworkStatus.onTime;
    return submittedAt.isAfter(deadline)
        ? _HomeworkStatus.late
        : _HomeworkStatus.onTime;
  }

  DateTime get deadline =>
      _deadlineFromParts(assignment.dueDate, assignment.dueTime);
}

class _MockHistoryItem {
  final ClassInfo classInfo;
  final SessionInfo session;
  final AssignmentInfo assignment;
  final MockResultInfo result;

  const _MockHistoryItem({
    required this.classInfo,
    required this.session,
    required this.assignment,
    required this.result,
  });

  DateTime get date => _sessionDateTime(session);

  double get verbalScore => (result.verbalPoints ?? 0).toDouble();

  double get mathScore => (result.mathPoints ?? 0).toDouble();

  double get score =>
      (result.totalPoints ?? (verbalScore + mathScore)).toDouble();
}

enum _HomeworkStatus {
  onTime('On time', Icons.check_circle_rounded, _kSuccess),
  late('Late', Icons.schedule_rounded, _kMock),
  missed('Missed', Icons.cancel_rounded, _kError),
  pending('Pending', Icons.hourglass_top_rounded, _kTextLight);

  final String label;
  final IconData icon;
  final Color color;

  const _HomeworkStatus(this.label, this.icon, this.color);
}

DateTime _deadlineFromParts(String? dueDate, String? dueTime) {
  final date = DateTime.tryParse(dueDate ?? '') ?? DateTime(2999);
  final time = _compactTime(dueTime);
  var hour = 23;
  var minute = 59;
  if (time.contains(':')) {
    final parts = time.split(':');
    hour = int.tryParse(parts[0]) ?? 23;
    minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 59 : 59;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

DateTime _sessionDateTime(SessionInfo session) {
  final date = DateTime.tryParse(session.date) ?? DateTime.now();
  final time = _compactTime(session.startTime);
  var hour = 23;
  var minute = 59;
  if (time.contains(':')) {
    final parts = time.split(':');
    hour = int.tryParse(parts[0]) ?? 23;
    minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 59 : 59;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

String _compactTime(String? value) {
  final text = (value ?? '').trim();
  return text.length >= 5 ? text.substring(0, 5) : text;
}

String _formatDateShort(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _textOrDash(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? '-' : trimmed;
}

void _openExternalLink(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  final withScheme = trimmed.startsWith(RegExp(r'https?://'))
      ? trimmed
      : 'https://$trimmed';
  html.window.open(withScheme, '_blank');
}

String _assignmentTitle(AssignmentInfo a, SessionInfo s) {
  return assignmentDisplayTitle(
    title: a.title,
    sessionType: s.sessionType,
    slotIndex: a.slotIndex,
    isMock: s.sessionType.toLowerCase() == 'mock',
  );
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
