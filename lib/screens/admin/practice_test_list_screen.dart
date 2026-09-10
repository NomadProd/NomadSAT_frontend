import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/admin/practice_test_editor_screen.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class PracticeTestListScreen extends StatefulWidget {
  const PracticeTestListScreen({super.key});

  @override
  State<PracticeTestListScreen> createState() => _PracticeTestListScreenState();
}

class _PracticeTestListScreenState extends State<PracticeTestListScreen> {
  final _service = PracticeTestService();
  final _classService = ClassService();

  List<PracticeTestInfo> _tests = [];
  List<ClassInfo> _classes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tests = await _service.fetchTests();
      final classes = await _classService.fetchClasses(archived: false);
      if (!mounted) return;
      setState(() {
        _tests = tests;
        _classes = classes;
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

  Future<void> _createTest() async {
    final title = await _promptForTitle();
    if (title == null) return;
    try {
      final created = await _service.createTest(title: title);
      if (!mounted) return;
      setState(() => _tests = [created, ..._tests]);
      await _openEditor(created);
    } catch (error) {
      _toast(userFacingError(error), isError: true);
    }
  }

  Future<String?> _promptForTitle({String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? 'New practice test' : 'Rename test'),
        content: TextField(
          key: const Key('practice-test-title-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Practice Test 1',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('practice-test-title-save'),
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _openEditor(PracticeTestInfo test) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeTestEditorScreen(testId: test.id),
      ),
    );
    await _load();
  }

  Future<void> _togglePublished(PracticeTestInfo test) async {
    try {
      final updated = await _service.setVisible(test.id, !test.visible);
      if (!mounted) return;
      setState(() {
        _tests = [
          for (final item in _tests) item.id == test.id ? updated : item,
        ];
      });
      _toast(updated.visible ? 'Published to the assigned groups' : 'Hidden');
    } catch (error) {
      // A 409 carries the reason -- which module is short, and by how much.
      _toast(userFacingError(error), isError: true);
    }
  }

  Future<void> _editGroups(PracticeTestInfo test) async {
    final selected = Set<int>.from(test.classIds);
    final saved = await showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Show this test to'),
          content: SizedBox(
            width: 380,
            child: _classes.isEmpty
                ? const Text('No groups available.')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final item in _classes)
                        CheckboxListTile(
                          key: Key('practice-test-group-${item.classId}'),
                          value: selected.contains(item.classId),
                          title: Text(item.className),
                          onChanged: (checked) => setDialogState(() {
                            if (checked == true) {
                              selected.add(item.classId);
                            } else {
                              selected.remove(item.classId);
                            }
                          }),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == null) return;
    try {
      final updated = await _service.setClasses(test.id, saved.toList()..sort());
      if (!mounted) return;
      setState(() {
        _tests = [
          for (final item in _tests) item.id == test.id ? updated : item,
        ];
      });
    } catch (error) {
      _toast(userFacingError(error), isError: true);
    }
  }

  Future<void> _deleteTest(PracticeTestInfo test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${test.title}"?'),
        content: const Text(
          'Students who already took it keep their results, but the test '
          'disappears from every group.',
        ),
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
      await _service.deleteTest(test.id);
      if (!mounted) return;
      setState(() => _tests = _tests.where((i) => i.id != test.id).toList());
    } catch (error) {
      _toast(userFacingError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: 'Practice Tests',
            subtitle: 'Author full-length tests and share them with your groups',
            pageLabel: 'Practice',
            onBack: () => Navigator.of(context).pop(),
            actions: [
              TuranHeaderAction(
                icon: Icons.add_rounded,
                label: 'New test',
                onTap: _createTest,
              ),
              TuranHeaderAction(
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                onTap: _load,
              ),
            ],
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
    if (_tests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No practice tests yet.\nCreate one, author its questions, '
                'then show it to a group.',
                key: Key('practice-test-empty'),
                textAlign: TextAlign.center,
                style: TextStyle(color: TuranColors.textMid, height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('practice-test-create'),
                onPressed: _createTest,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New practice test'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _tests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _TestCard(
          test: _tests[index],
          classes: _classes,
          onEditQuestions: () => _openEditor(_tests[index]),
          onEditGroups: () => _editGroups(_tests[index]),
          onTogglePublished: () => _togglePublished(_tests[index]),
          onDelete: () => _deleteTest(_tests[index]),
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final PracticeTestInfo test;
  final List<ClassInfo> classes;
  final VoidCallback onEditQuestions;
  final VoidCallback onEditGroups;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  const _TestCard({
    required this.test,
    required this.classes,
    required this.onEditQuestions,
    required this.onEditGroups,
    required this.onTogglePublished,
    required this.onDelete,
  });

  String get _groupLabel {
    if (test.classIds.isEmpty) return 'No groups yet';
    final names = classes
        .where((item) => test.classIds.contains(item.classId))
        .map((item) => item.className)
        .toList();
    if (names.isEmpty) return '${test.classIds.length} group(s)';
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final blocking = test.firstIncompleteModule;
    return Container(
      key: Key('practice-test-card-${test.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(test.title, style: TuranTextStyles.title),
              ),
              _StatusChip(published: test.visible),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final module in test.modules)
                _ModuleChip(module: module),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.groups_rounded,
                  size: 16, color: TuranColors.textMid),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _groupLabel,
                  key: Key('practice-test-groups-${test.id}'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: TuranColors.textMid, fontSize: 13),
                ),
              ),
            ],
          ),
          if (!test.visible && blocking != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TuranColors.warningBg,
                borderRadius: BorderRadius.circular(TuranRadius.sm),
              ),
              child: Text(
                'Add ${blocking.requiredQuestionCount - blocking.questionCount} '
                'more ${blocking.sectionLabel} question(s) before publishing.',
                key: Key('practice-test-blocked-${test.id}'),
                style: const TextStyle(
                    color: TuranColors.warning, fontSize: 12.5, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: Key('practice-test-edit-${test.id}'),
                onPressed: onEditQuestions,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Questions'),
              ),
              OutlinedButton.icon(
                key: Key('practice-test-groups-button-${test.id}'),
                onPressed: onEditGroups,
                icon: const Icon(Icons.groups_rounded, size: 18),
                label: const Text('Groups'),
              ),
              FilledButton.icon(
                key: Key('practice-test-publish-${test.id}'),
                onPressed: onTogglePublished,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      test.visible ? TuranColors.neutral : TuranColors.primary,
                ),
                icon: Icon(
                  test.visible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                ),
                label: Text(test.visible ? 'Hide' : 'Publish'),
              ),
              IconButton(
                key: Key('practice-test-delete-${test.id}'),
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: TuranColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool published;

  const _StatusChip({required this.published});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: published ? TuranColors.successBg : TuranColors.neutralBg,
        borderRadius: BorderRadius.circular(TuranRadius.pill),
      ),
      child: Text(
        published ? 'Published' : 'Draft',
        style: TextStyle(
          color: published ? TuranColors.success : TuranColors.neutral,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final PracticeTestModuleInfo module;

  const _ModuleChip({required this.module});

  @override
  Widget build(BuildContext context) {
    final color = module.isMath ? TuranColors.math : TuranColors.verbal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TuranRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${module.sectionLabel}  ${module.questionCount}/'
        '${module.requiredQuestionCount}  ·  ${module.minutes}m',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
