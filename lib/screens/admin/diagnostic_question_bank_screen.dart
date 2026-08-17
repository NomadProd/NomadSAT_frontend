import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Services/diagnostic_service.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/Widgets/confirm_dialog.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/screens/student/diagnostic_test_screen.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticQuestionBankScreen extends StatefulWidget {
  const DiagnosticQuestionBankScreen({super.key});

  @override
  State<DiagnosticQuestionBankScreen> createState() =>
      _DiagnosticQuestionBankScreenState();
}

class _DiagnosticQuestionBankScreenState
    extends State<DiagnosticQuestionBankScreen> {
  final _authService = AuthService();
  final _service = DiagnosticService();
  late Future<DiagnosticBankData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DiagnosticBankData> _load() async {
    final user = await _authService.fetchMe();
    final role = user.role.toLowerCase();
    if (role == 'student') {
      return DiagnosticBankData(user: user, questions: const []);
    }
    final questions = await _service.fetchQuestionBank();
    return DiagnosticBankData(user: user, questions: questions);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: FutureBuilder<DiagnosticBankData>(
        future: _future,
        builder: (context, snap) {
          final user = snap.data?.user;
          return Column(
            children: [
              TuranHeader(
                user: user,
                title: 'Diagnostic Test Question Bank',
                subtitle: 'Fixed 20-question Digital SAT diagnostic layout',
                pageLabel: 'Diagnostic',
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  TuranHeaderAction(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    onTap: _reload,
                  ),
                ],
              ),
              Expanded(
                child: snap.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: CircularProgressIndicator(color: TuranColors.primary),
                      )
                    : snap.hasError
                    ? Center(
                        child: Text(
                          userFacingError(snap.error!),
                          style: const TextStyle(color: TuranColors.error),
                        ),
                      )
                    : DiagnosticQuestionBankView(
                        data: snap.data!,
                        onReload: _reload,
                        service: _service,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DiagnosticBankData {
  final UserInfo user;
  final List<DiagnosticQuestion> questions;

  const DiagnosticBankData({required this.user, required this.questions});
}

class DiagnosticQuestionBankView extends StatelessWidget {
  final DiagnosticBankData data;
  final VoidCallback onReload;
  final DiagnosticService service;

  const DiagnosticQuestionBankView({
    super.key,
    required this.data,
    required this.onReload,
    required this.service,
  });

  String get _role => data.user.role.toLowerCase();
  bool get canEdit => canManageDiagnosticBank(_role);
  bool get canView => canViewDiagnosticBank(_role);

  DiagnosticQuestion? _questionFor(int orderIndex) {
    for (final question in data.questions) {
      if (question.orderIndex == orderIndex) return question;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!canView) {
      return const Center(
        child: Text(
          'You do not have access to the diagnostic question bank.',
          style: TextStyle(color: TuranColors.textMid),
        ),
      );
    }

    final rwSlots = kDiagnosticLayout.where((slot) => !slot.isMath).toList();
    final mathSlots = kDiagnosticLayout.where((slot) => slot.isMath).toList();
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.tablet;

    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 20, compact ? 16 : 24, 32),
      children: [
        if (canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiagnosticTestScreen()),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Preview test'),
            ),
          ),
        if (canEdit) const SizedBox(height: 14),
        _SectionGroup(
          title: 'Reading & Writing',
          slots: rwSlots,
          questionFor: _questionFor,
          canEdit: canEdit,
          onEdit: (slot, question) => _openForm(context, slot, question),
          onDelete: (question) => _delete(context, question),
        ),
        const SizedBox(height: 18),
        _SectionGroup(
          title: 'Math',
          slots: mathSlots,
          questionFor: _questionFor,
          canEdit: canEdit,
          onEdit: (slot, question) => _openForm(context, slot, question),
          onDelete: (question) => _delete(context, question),
        ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    DiagnosticSlot slot,
    DiagnosticQuestion? question,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DiagnosticQuestionFormScreen(
          slot: slot,
          question: question,
          service: service,
        ),
      ),
    );
    if (changed == true) onReload();
  }

  Future<void> _delete(BuildContext context, DiagnosticQuestion question) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete question?',
      body:
          'Delete question ${question.orderIndex}? This is blocked if students have already answered it.',
    );
    if (!confirmed) return;
    try {
      await service.deleteQuestion(question.id);
      onReload();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(error))),
      );
    }
  }
}

class _SectionGroup extends StatelessWidget {
  final String title;
  final List<DiagnosticSlot> slots;
  final DiagnosticQuestion? Function(int orderIndex) questionFor;
  final bool canEdit;
  final void Function(DiagnosticSlot slot, DiagnosticQuestion? question) onEdit;
  final void Function(DiagnosticQuestion question) onDelete;

  const _SectionGroup({
    required this.title,
    required this.slots,
    required this.questionFor,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TuranTextStyles.title),
        const SizedBox(height: 10),
        for (final slot in slots) ...[
          _SlotCard(
            slot: slot,
            question: questionFor(slot.orderIndex),
            canEdit: canEdit,
            onEdit: () => onEdit(slot, questionFor(slot.orderIndex)),
            onDelete: () {
              final question = questionFor(slot.orderIndex);
              if (question != null) onDelete(question);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final DiagnosticSlot slot;
  final DiagnosticQuestion? question;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SlotCard({
    required this.slot,
    required this.question,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final filled = question != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TuranColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TuranColors.panelBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${slot.orderIndex}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: TuranColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.domain,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TuranColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${slot.difficulty} · ${slot.points} points'
                  '${filled ? '' : ' · empty slot'}',
                  style: const TextStyle(color: TuranColors.textMid, fontSize: 13),
                ),
              ],
            ),
          ),
          if (canEdit) ...[
            TextButton(
              onPressed: onEdit,
              child: Text(filled ? 'Edit' : 'Add'),
            ),
            if (filled)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: TuranColors.error,
                tooltip: 'Delete',
              ),
          ],
        ],
      ),
    );
  }
}

class DiagnosticQuestionFormScreen extends StatefulWidget {
  final DiagnosticSlot slot;
  final DiagnosticQuestion? question;
  final DiagnosticService service;

  const DiagnosticQuestionFormScreen({
    super.key,
    required this.slot,
    required this.question,
    required this.service,
  });

  @override
  State<DiagnosticQuestionFormScreen> createState() =>
      _DiagnosticQuestionFormScreenState();
}

class _DiagnosticQuestionFormScreenState
    extends State<DiagnosticQuestionFormScreen> {
  final _stemController = TextEditingController();
  final _imageController = TextEditingController();
  final _explanationController = TextEditingController();
  final _choiceControllers = {
    'A': TextEditingController(),
    'B': TextEditingController(),
    'C': TextEditingController(),
    'D': TextEditingController(),
  };
  String _correctChoice = 'A';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    if (question != null) {
      _stemController.text = question.questionText;
      _imageController.text = question.questionImage ?? '';
      _explanationController.text = question.explanation ?? '';
      _correctChoice = (question.correctChoice ?? 'A').toUpperCase();
      for (final choice in question.choices) {
        _choiceControllers[choice.key]?.text = choice.text;
      }
    }
  }

  @override
  void dispose() {
    _stemController.dispose();
    _imageController.dispose();
    _explanationController.dispose();
    for (final controller in _choiceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final slot = widget.slot;
    final mismatch = diagnosticLayoutMismatch(
      orderIndex: slot.orderIndex,
      section: slot.section,
      domain: slot.domain,
      difficulty: slot.difficulty,
      points: slot.points,
    );
    if (mismatch != null) {
      setState(() => _error = mismatch);
      return;
    }
    if (_stemController.text.trim().isEmpty) {
      setState(() => _error = 'Question text is required');
      return;
    }
    for (final entry in _choiceControllers.entries) {
      if (entry.value.text.trim().isEmpty) {
        setState(() => _error = 'Choice ${entry.key} is required');
        return;
      }
    }

    final payload = DiagnosticQuestion(
      id: widget.question?.id ?? 0,
      section: slot.section,
      domain: slot.domain,
      difficulty: slot.difficulty,
      points: slot.points,
      orderIndex: slot.orderIndex,
      questionText: _stemController.text.trim(),
      questionImage: _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim(),
      choices: [
        for (final key in ['A', 'B', 'C', 'D'])
          DiagnosticChoice(key: key, text: _choiceControllers[key]!.text.trim()),
      ],
      correctChoice: _correctChoice,
      explanation: _explanationController.text.trim().isEmpty
          ? null
          : _explanationController.text.trim(),
    ).toPayload();

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.question == null) {
        await widget.service.createQuestion(payload);
      } else {
        await widget.service.updateQuestion(widget.question!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = userFacingError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: widget.question == null ? 'Add question' : 'Edit question',
            subtitle: 'Slot ${slot.orderIndex} · ${slot.sectionLabel}',
            pageLabel: 'Diagnostic',
            onBack: () => Navigator.of(context).pop(false),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${slot.domain} · ${slot.difficulty} · ${slot.points} points',
                          style: const TextStyle(
                            color: TuranColors.textMid,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _stemController,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Question text',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _imageController,
                          decoration: const InputDecoration(
                            labelText: 'Question image URL (optional)',
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final key in ['A', 'B', 'C', 'D']) ...[
                          TextField(
                            controller: _choiceControllers[key],
                            maxLines: 2,
                            decoration: InputDecoration(labelText: 'Choice $key'),
                          ),
                          const SizedBox(height: 10),
                        ],
                        DropdownButtonFormField<String>(
                          value: _correctChoice,
                          decoration: const InputDecoration(labelText: 'Correct choice'),
                          items: [
                            for (final key in ['A', 'B', 'C', 'D'])
                              DropdownMenuItem(value: key, child: Text(key)),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _correctChoice = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _explanationController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Explanation (optional)',
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: TuranColors.error)),
                        ],
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TuranColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save question'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
