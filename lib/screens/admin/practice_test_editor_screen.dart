import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/Widgets/exam_question_preview_screen.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

const _difficulties = ['easy', 'medium', 'hard'];

class PracticeTestEditorScreen extends StatefulWidget {
  final int testId;

  const PracticeTestEditorScreen({super.key, required this.testId});

  @override
  State<PracticeTestEditorScreen> createState() =>
      _PracticeTestEditorScreenState();
}

class _PracticeTestEditorScreenState extends State<PracticeTestEditorScreen>
    with SingleTickerProviderStateMixin {
  final _service = PracticeTestService();

  PracticeTestInfo? _test;
  final Map<int, List<PracticeTestQuestionAdmin>> _questions = {};
  TabController? _tabs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final test = await _service.fetchTest(widget.testId);
      final byModule = <int, List<PracticeTestQuestionAdmin>>{};
      for (final module in test.modules) {
        byModule[module.id] = await _service.fetchModuleQuestions(module.id);
      }
      if (!mounted) return;
      setState(() {
        _test = test;
        _questions
          ..clear()
          ..addAll(byModule);
        _tabs ??= TabController(length: test.modules.length, vsync: this);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(error);
        _loading = false;
      });
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? TuranColors.error : TuranColors.success,
      ),
    );
  }

  Future<void> _openForm(
    PracticeTestModuleInfo module, {
    PracticeTestQuestionAdmin? existing,
    int? slot,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _QuestionForm(
            service: _service,
            module: module,
            existing: existing,
            slot: slot ?? existing?.orderIndex ?? 1,
            takenSlots: {
              for (final question in _questions[module.id] ?? const [])
                if (question.id != existing?.id) question.orderIndex,
            },
          ),
        ),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(PracticeTestQuestionAdmin question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete question ${question.orderIndex}?'),
        content: const Text('The slot becomes free again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TuranColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final unpublished = await _service.deleteQuestion(question.id);
      await _load();
      if (unpublished) {
        _toast(
          'Deleted. This test is back to draft until the slot is filled again.',
          isError: true,
        );
      }
    } catch (error) {
      _toast(userFacingError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final test = _test;
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: test?.title ?? 'Practice test',
            subtitle: 'Author each module question by question',
            pageLabel: 'Practice',
            onBack: () => Navigator.of(context).pop(),
            bottom: test == null || _tabs == null
                ? null
                : TabBar(
                    controller: _tabs,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    dividerColor: Colors.transparent,
                    tabs: [
                      for (final module in test.modules)
                        Tab(
                          key: Key('practice-module-tab-${module.id}'),
                          text: '${module.sectionLabel}  '
                              '${(_questions[module.id] ?? const []).length}/'
                              '${module.requiredQuestionCount}',
                        ),
                    ],
                  ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    final test = _test!;
    return TabBarView(
      controller: _tabs,
      children: [
        for (final module in test.modules)
          _ModulePane(
            module: module,
            questions: _questions[module.id] ?? const [],
            onAdd: (slot) => _openForm(module, slot: slot),
            onEdit: (question) => _openForm(module, existing: question),
            onDelete: _delete,
          ),
      ],
    );
  }
}

class _ModulePane extends StatelessWidget {
  final PracticeTestModuleInfo module;
  final List<PracticeTestQuestionAdmin> questions;
  final ValueChanged<int> onAdd;
  final ValueChanged<PracticeTestQuestionAdmin> onEdit;
  final ValueChanged<PracticeTestQuestionAdmin> onDelete;

  const _ModulePane({
    required this.module,
    required this.questions,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bySlot = {for (final item in questions) item.orderIndex: item};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${module.sectionLabel} · ${module.requiredQuestionCount} questions '
          '· ${module.minutes} minutes',
          style: const TextStyle(
            color: TuranColors.textMid,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (var slot = 1; slot <= module.requiredQuestionCount; slot++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SlotRow(
              slot: slot,
              question: bySlot[slot],
              onAdd: () => onAdd(slot),
              onEdit: () => onEdit(bySlot[slot]!),
              onDelete: () => onDelete(bySlot[slot]!),
            ),
          ),
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  final int slot;
  final PracticeTestQuestionAdmin? question;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SlotRow({
    required this.slot,
    required this.question,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final item = question;
    final filled = item != null;
    return Material(
      color: TuranColors.surface,
      borderRadius: BorderRadius.circular(TuranRadius.md),
      child: InkWell(
        key: Key('practice-slot-$slot'),
        borderRadius: BorderRadius.circular(TuranRadius.md),
        onTap: filled ? onEdit : onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TuranRadius.md),
            border: Border.all(
              color: filled ? TuranColors.border : TuranColors.inputBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled
                      ? TuranColors.primary.withValues(alpha: 0.1)
                      : TuranColors.neutralBg,
                  borderRadius: BorderRadius.circular(TuranRadius.sm),
                ),
                child: Text(
                  '$slot',
                  style: TextStyle(
                    color:
                        filled ? TuranColors.primary : TuranColors.textLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: filled
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.questionText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: TuranColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.domain} · ${item.difficulty}'
                            '${item.isGridIn ? ' · grid-in' : ''}',
                            style: const TextStyle(
                              color: TuranColors.textMid,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Empty — tap to add',
                        style: TextStyle(color: TuranColors.textLight),
                      ),
              ),
              if (filled)
                IconButton(
                  key: Key('practice-slot-delete-$slot'),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: TuranColors.error, size: 20),
                )
              else
                const Icon(Icons.add_rounded, color: TuranColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionForm extends StatefulWidget {
  final PracticeTestService service;
  final PracticeTestModuleInfo module;
  final PracticeTestQuestionAdmin? existing;
  final int slot;
  final Set<int> takenSlots;

  const _QuestionForm({
    required this.service,
    required this.module,
    required this.existing,
    required this.slot,
    required this.takenSlots,
  });

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  late final _passage = TextEditingController(
      text: widget.existing?.passageText ?? '');
  late final _stem =
      TextEditingController(text: widget.existing?.questionText ?? '');
  late final _explanation =
      TextEditingController(text: widget.existing?.explanation ?? '');
  late final _answers = TextEditingController(
      text: (widget.existing?.correctAnswers ?? const []).join(', '));
  late final List<TextEditingController> _choices = List.generate(
    4,
    (index) => TextEditingController(
      text: index < (widget.existing?.choices.length ?? 0)
          ? widget.existing!.choices[index].text
          : '',
    ),
  );

  late int _slot = widget.slot;
  late String _domain = widget.existing?.domain ??
      (widget.module.isMath ? kMathDomains.first : kRwDomains.first);
  late String _difficulty = widget.existing?.difficulty ?? 'easy';
  late bool _gridIn = widget.existing?.isGridIn ?? false;
  late String _correctChoice = widget.existing?.correctChoice ?? 'A';
  late String? _imageUrl = widget.existing?.questionImage;
  late String? _imagePublicId = widget.existing?.questionImagePublicId;
  late double _imageScale = widget.existing?.imageScale ?? kExamImageScaleDefault;

  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _passage.dispose();
    _stem.dispose();
    _explanation.dispose();
    _answers.dispose();
    for (final controller in _choices) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _domains =>
      widget.module.isMath ? kMathDomains : kRwDomains;

  List<String> get _parsedAnswers => _answers.text
      .split(RegExp(r'[,\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  PracticeTestQuestionAdmin _draft() {
    return PracticeTestQuestionAdmin(
      id: widget.existing?.id ?? 0,
      moduleId: widget.module.id,
      orderIndex: _slot,
      domain: _domain,
      difficulty: _difficulty,
      passageText: _passage.text.trim().isEmpty ? null : _passage.text.trim(),
      questionText: _stem.text.trim(),
      explanation:
          _explanation.text.trim().isEmpty ? null : _explanation.text.trim(),
      questionImage: _imageUrl,
      questionImagePublicId: _imagePublicId,
      imageScale: _imageScale,
      answerType: _gridIn ? 'spr' : 'mcq',
      choices: [
        for (var index = 0; index < _choices.length; index++)
          if (_choices[index].text.trim().isNotEmpty)
            ExamChoice(
              key: String.fromCharCode(65 + index),
              text: _choices[index].text.trim(),
            ),
      ],
      correctChoice: _correctChoice,
      correctAnswers: _parsedAnswers,
    );
  }

  Future<void> _pickImage() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final uploaded = await widget.service.uploadQuestionImage(file);
      if (!mounted) return;
      setState(() {
        _imageUrl = uploaded.url;
        _imagePublicId = uploaded.publicId;
        _uploading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(error);
        _uploading = false;
      });
    }
  }

  Future<void> _preview() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ExamQuestionPreviewScreen(
          question: _draft().toExamQuestion(isMath: widget.module.isMath),
          remaining: Duration(seconds: widget.module.timeLimitSeconds),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final payload = _draft().toPayload();
      if (widget.existing == null) {
        await widget.service.createQuestion(widget.module.id, payload);
      } else {
        await widget.service.updateQuestion(widget.existing!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(error);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final freeSlots = [
      for (var slot = 1; slot <= widget.module.requiredQuestionCount; slot++)
        if (!widget.takenSlots.contains(slot)) slot,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.existing == null
                      ? 'New ${widget.module.sectionLabel} question'
                      : 'Edit question $_slot',
                  style: TuranTextStyles.title,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: const Key('practice-form-slot'),
                        initialValue:
                            freeSlots.contains(_slot) ? _slot : freeSlots.firstOrNull,
                        decoration: const InputDecoration(labelText: 'Position'),
                        items: [
                          for (final slot in freeSlots)
                            DropdownMenuItem(value: slot, child: Text('$slot')),
                        ],
                        onChanged: (value) =>
                            setState(() => _slot = value ?? _slot),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _difficulty,
                        decoration:
                            const InputDecoration(labelText: 'Difficulty'),
                        items: [
                          for (final value in _difficulties)
                            DropdownMenuItem(value: value, child: Text(value)),
                        ],
                        onChanged: (value) =>
                            setState(() => _difficulty = value ?? _difficulty),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _domains.contains(_domain) ? _domain : _domains.first,
                  decoration: const InputDecoration(labelText: 'Domain'),
                  items: [
                    for (final value in _domains)
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) => setState(() => _domain = value ?? _domain),
                ),
                if (!widget.module.isMath) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passage,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Passage (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  key: const Key('practice-form-stem'),
                  controller: _stem,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                _ImageRow(
                  url: _imageUrl,
                  scale: _imageScale,
                  uploading: _uploading,
                  onPick: _pickImage,
                  onClear: () => setState(() {
                    _imageUrl = null;
                    _imagePublicId = null;
                  }),
                  onScale: (value) => setState(() => _imageScale = value),
                ),
                if (widget.module.isMath) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('practice-form-gridin-switch'),
                    contentPadding: EdgeInsets.zero,
                    value: _gridIn,
                    title: const Text('Student-produced response (grid-in)'),
                    subtitle: const Text(
                      'The student types an answer instead of picking a choice.',
                    ),
                    onChanged: (value) => setState(() => _gridIn = value),
                  ),
                ],
                const SizedBox(height: 4),
                if (_gridIn)
                  TextField(
                    key: const Key('practice-form-answers'),
                    controller: _answers,
                    decoration: const InputDecoration(
                      labelText: 'Accepted answers',
                      helperText:
                          'Comma separated, e.g. 2/3, 0.667. Equivalent forms '
                          'are matched automatically.',
                      helperMaxLines: 3,
                    ),
                  )
                else
                  RadioGroup<String>(
                    groupValue: _correctChoice,
                    onChanged: (value) =>
                        setState(() => _correctChoice = value ?? 'A'),
                    child: Column(
                      children: [
                        for (var index = 0; index < _choices.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: String.fromCharCode(65 + index),
                                ),
                                Expanded(
                                  child: TextField(
                                    key: Key('practice-form-choice-$index'),
                                    controller: _choices[index],
                                    decoration: InputDecoration(
                                      labelText:
                                          'Choice ${String.fromCharCode(65 + index)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select the radio next to the correct choice.',
                            style: TextStyle(
                                color: TuranColors.textMid, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _explanation,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (shown after submit)',
                    alignLabelWithHint: true,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TuranColors.errorBg,
                      borderRadius: BorderRadius.circular(TuranRadius.sm),
                    ),
                    child: Text(
                      _error!,
                      key: const Key('practice-form-error'),
                      style: const TextStyle(color: TuranColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              TextButton.icon(
                key: const Key('practice-form-preview'),
                onPressed: _saving ? null : _preview,
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Preview'),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('practice-form-save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save question'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageRow extends StatelessWidget {
  final String? url;
  final double scale;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final ValueChanged<double> onScale;

  const _ImageRow({
    required this.url,
    required this.scale,
    required this.uploading,
    required this.onPick,
    required this.onClear,
    required this.onScale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              key: const Key('practice-form-image'),
              onPressed: uploading ? null : onPick,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(
                uploading
                    ? 'Uploading…'
                    : url == null
                        ? 'Add figure'
                        : 'Replace figure',
              ),
            ),
            if (url != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onClear, child: const Text('Remove')),
            ],
          ],
        ),
        if (url != null) ...[
          const SizedBox(height: 6),
          Text(
            'Figure width ${(scale * 100).round()}%',
            style: const TextStyle(color: TuranColors.textMid, fontSize: 12),
          ),
          Slider(
            value: scale,
            min: kExamImageScaleMin,
            max: kExamImageScaleMax,
            divisions: 12,
            onChanged: onScale,
          ),
        ],
      ],
    );
  }
}
