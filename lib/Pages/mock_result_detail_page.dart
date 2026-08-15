import 'dart:async';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/Models/homework_result.dart';
import 'package:flutter_web/Models/mock_result.dart';
import 'package:flutter_web/Utils/homework_pdf.dart';
import 'package:flutter_web/Widgets/file_list_tile.dart';
import 'package:flutter_web/Widgets/homework_pdf_section.dart';

const _kPrimary = Color(0xFF1A4AF0);
const _kBg = Color(0xFFF2F6FF);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFD7E3FF);
const _kTextDark = Color(0xFF0D1B3E);
const _kTextMid = Color(0xFF4A5A7A);
const _kTextLight = Color(0xFF9AAAC6);
const _kSuccess = Color(0xFF1B873F);
const _kError = Color(0xFFC62828);
const _kMock = Color(0xFFEF6C00);

const _maxFiles = 10;
const _maxFileSizeBytes = 10 * 1024 * 1024;
const _maxFileSizeMessage = 'File size cannot exceed 10mb';
const _allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'pdf'];

class MockResultDetailPage extends StatefulWidget {
  final String title;
  final String className;
  final String deadline;
  final String sessionType;
  final AssignmentInfo assignment;
  final SessionInfo? session;
  final MockResultInfo? result;

  const MockResultDetailPage({
    super.key,
    required this.title,
    required this.className,
    required this.deadline,
    required this.sessionType,
    required this.assignment,
    this.session,
    this.result,
  });

  @override
  State<MockResultDetailPage> createState() => _MockResultDetailPageState();
}

class _MockResultDetailPageState extends State<MockResultDetailPage>
    with SingleTickerProviderStateMixin {
  final _classService = ClassService();
  final _formKey = GlobalKey<FormState>();
  final _verbalController = TextEditingController();
  final _mathController = TextEditingController();
  final _analysisController = TextEditingController();

  MockResultDetail? _result;
  final List<PlatformFile> _pendingFiles = [];
  bool _saving = false;
  String? _error;
  String? _bannerError;
  Timer? _bannerTimer;

  late AnimationController _heroAnim;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();

    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutCubic));
    _heroAnim.forward();

    final result = widget.result;
    if (result != null) {
      _verbalController.text = result.verbalPoints?.toString() ?? '';
      _mathController.text = result.mathPoints?.toString() ?? '';
      _analysisController.text = result.weakAreas ?? '';
      if (result.resultId > 0) {
        _reloadResult(result.resultId);
      }
    } else {
      _loadExistingMockResultIfAny();
    }
  }

  Future<void> _loadExistingMockResultIfAny() async {
    try {
      final results = await _classService.fetchMockResultsByAssignment(
        widget.assignment.assignmentId,
      );
      final existing = results
          .where((r) => r.studentId == widget.assignment.studentId)
          .firstOrNull;
      if (existing == null || existing.resultId <= 0) return;
      if (!mounted) return;

      _verbalController.text = existing.verbalPoints?.toString() ?? '';
      _mathController.text = existing.mathPoints?.toString() ?? '';
      _analysisController.text = existing.weakAreas ?? '';
      await _reloadResult(existing.resultId);
    } catch (_) {
      if (!mounted) return;
      _showBannerError(
        'Could not load the previous mock result. You can still submit.',
      );
    }
  }

  Future<int?> _resolveExistingMockResultId() async {
    final results = await _classService.fetchMockResultsByAssignment(
      widget.assignment.assignmentId,
    );
    final existing = results
        .where((r) => r.studentId == widget.assignment.studentId)
        .firstOrNull;
    if (existing == null || existing.resultId <= 0) return null;
    return existing.resultId;
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _heroAnim.dispose();
    _verbalController.dispose();
    _mathController.dispose();
    _analysisController.dispose();
    super.dispose();
  }

  Future<void> _reloadResult(int resultId) async {
    try {
      final result = await _classService.fetchMockResult(resultId);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = userFacingError(e));
    }
  }

  void _showBannerError(String message) {
    _bannerTimer?.cancel();
    setState(() => _bannerError = message);
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bannerError = null);
    });
  }

  void _openLink(String url) {
    final t = url.trim();
    if (t.isEmpty) return;
    final withScheme = t.startsWith(RegExp(r'https?://')) ? t : 'https://$t';
    html.window.open(withScheme, '_blank');
  }

  void _openHomeworkPdf(String url) {
    try {
      final trimmed = url.trim();
      if (trimmed.isEmpty) {
        throw StateError('empty');
      }
      final opened = html.window.open(trimmed, '_blank');
      if (opened == null) {
        throw StateError('popup blocked');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(homeworkPdfOpenErrorMessage)),
      );
    }
  }

  bool get _canEditFiles => _result == null || !_result!.isSubmittedLocked;

  bool get _hasExistingFiles {
    final result = _result;
    if (result == null) return false;
    if (result.attachments.isNotEmpty) return true;
    return (result.photoLink ?? '').isNotEmpty;
  }

  int get _totalFileCount {
    final uploaded = _result?.attachments.length ?? 0;
    return uploaded + _pendingFiles.length;
  }

  Future<void> _pickFiles() async {
    if (!_canEditFiles || _saving) return;

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    for (final file in picked.files) {
      final ext = (file.extension ?? '').toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        _showBannerError(
          '«${file.name}» is not a supported file type (images and PDF only)',
        );
        return;
      }
      if (file.size > _maxFileSizeBytes) {
        _showBannerError(_maxFileSizeMessage);
        return;
      }
    }

    if (_totalFileCount + picked.files.length > _maxFiles) {
      _showBannerError('Maximum 10 files per submission');
      return;
    }

    setState(() {
      _pendingFiles.addAll(picked.files);
      _error = null;
    });
  }

  void _removePendingFile(int index) {
    setState(() => _pendingFiles.removeAt(index));
  }

  Future<void> _deleteUploadedFile(HomeworkFile file) async {
    if (_saving) return;
    final fileId = file.id;
    if (fileId == null) {
      setState(() => _error = 'Could not delete file');
      return;
    }
    setState(() => _saving = true);
    final ok = await _classService.deleteMockFile(fileId);
    if (!mounted) return;
    if (ok && _result != null) {
      await _reloadResult(_result!.id);
    } else if (!ok) {
      setState(() => _error = 'Could not delete file');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<int?> _ensureResultId() async {
    final existing = _result;
    if (existing != null && existing.id > 0) return existing.id;

    final initial = widget.result;
    if (initial != null && initial.resultId > 0) return initial.resultId;

    final verbalPoints = int.tryParse(_verbalController.text.trim());
    final mathPoints = int.tryParse(_mathController.text.trim());
    final analysis = _analysisController.text.trim();

    final created = await _classService.createMockResult(
      assignmentId: widget.assignment.assignmentId,
      studentId: widget.assignment.studentId,
      submitted: false,
      verbalPoints: verbalPoints,
      mathPoints: mathPoints,
      weakAreas: analysis.isEmpty ? null : analysis,
    );

    if (created['success'] != true) {
      final msg = created['message']?.toString() ?? 'Could not create result';
      if (msg.toLowerCase().contains('already exists')) {
        final resultId = await _resolveExistingMockResultId();
        if (resultId != null) {
          await _reloadResult(resultId);
          return resultId;
        }
      }
      setState(() => _error = msg);
      return null;
    }

    final resultId = created['result_id'] as int?;
    if (resultId != null) {
      await _reloadResult(resultId);
    }
    return resultId;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final photoRequired = widget.assignment.photoRequired;
    if (photoRequired && _pendingFiles.isEmpty && !_hasExistingFiles) {
      setState(() => _error = 'Please attach at least one file before submitting.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final resultId = await _ensureResultId();
    if (resultId == null) {
      setState(() => _saving = false);
      return;
    }

    if (_pendingFiles.isNotEmpty) {
      final upload = await _classService.uploadMockResultFiles(
        resultId: resultId,
        files: List<PlatformFile>.from(_pendingFiles),
      );

      if (upload['success'] != true) {
        setState(() {
          _saving = false;
          _error = upload['message']?.toString() ?? 'Upload failed';
        });
        return;
      }

      _result = upload['result'] as MockResultDetail?;
      _pendingFiles.clear();
    }

    final verbalPoints = int.tryParse(_verbalController.text.trim());
    final mathPoints = int.tryParse(_mathController.text.trim());
    final analysis = _analysisController.text.trim();

    final response = await _classService.updateMockResult(
      resultId: resultId,
      submitted: true,
      photoLink: _result?.photoLink,
      verbalPoints: verbalPoints,
      mathPoints: mathPoints,
      weakAreas: analysis.isEmpty ? null : analysis,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Mock result submitted',
          ),
          backgroundColor: _kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = response['message']?.toString() ?? 'Could not submit mock result';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _DetailPattern()),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SlideTransition(
                position: _heroSlide,
                child: FadeTransition(
                  opacity: _heroFade,
                  child: _DetailHero(
                    title: widget.title,
                    className: widget.className,
                    deadline: widget.deadline,
                    sessionType: widget.sessionType,
                    photoRequired: widget.assignment.photoRequired,
                    hasSubmission: _result?.submitted == true || widget.result?.submitted == true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 34),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = _DetailsCard(
                      taskLink: widget.assignment.taskLink?.trim() ?? '',
                      mockDocument: widget.session?.mockDocument,
                      photoRequired: widget.assignment.photoRequired,
                      onOpenLink: _openLink,
                      onOpenMockPdf: _openHomeworkPdf,
                    );
                    final form = _SubmissionCard(
                      formKey: _formKey,
                      verbalController: _verbalController,
                      mathController: _mathController,
                      analysisController: _analysisController,
                      saving: _saving,
                      error: _error,
                      bannerError: _bannerError,
                      canEditFiles: _canEditFiles,
                      pendingFiles: _pendingFiles,
                      result: _result,
                      onPickFiles: _pickFiles,
                      onRemovePending: _removePendingFile,
                      onDeleteUploaded: _deleteUploadedFile,
                      onOpenUrl: _openLink,
                      onSubmit: _submit,
                    );

                    if (constraints.maxWidth < 860) {
                      return Column(
                        children: [details, const SizedBox(height: 16), form],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 16),
                        Expanded(child: form),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final String title;
  final String className;
  final String deadline;
  final String sessionType;
  final bool photoRequired;
  final bool hasSubmission;

  const _DetailHero({
    required this.title,
    required this.className,
    required this.deadline,
    required this.sessionType,
    required this.photoRequired,
    required this.hasSubmission,
  });

  @override
  Widget build(BuildContext context) => TuranHeader(
    title: title,
    subtitle: className,
    pageLabel: 'Mock Submission',
    onBack: () => Navigator.of(context).maybePop(),
    bottom: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusBadge(submitted: hasSubmission, photoRequired: photoRequired),
        _HeroChip(icon: Icons.quiz_rounded, label: sessionType),
        _HeroChip(icon: Icons.schedule_rounded, label: deadline),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final bool submitted;
  final bool photoRequired;

  const _StatusBadge({required this.submitted, required this.photoRequired});

  @override
  Widget build(BuildContext context) {
    final color = submitted ? _kSuccess : _kMock;
    final label = submitted ? 'Submitted' : 'Pending';
    final icon = submitted
        ? Icons.check_circle_rounded
        : Icons.hourglass_top_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.45), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.13),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withOpacity(0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.84), size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.90),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  final String taskLink;
  final HomeworkDocument? mockDocument;
  final bool photoRequired;
  final ValueChanged<String> onOpenLink;
  final ValueChanged<String> onOpenMockPdf;

  const _DetailsCard({
    required this.taskLink,
    required this.mockDocument,
    required this.photoRequired,
    required this.onOpenLink,
    required this.onOpenMockPdf,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Mock Info',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBlock(
            label: 'Submission',
            icon: Icons.quiz_rounded,
            child: const Text(
              'Enter your verbal and math points, add notes for your teacher, and upload a screenshot or PDF proof if needed.',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _InfoBlock(
            label: 'Mock Link',
            icon: Icons.link_rounded,
            child: taskLink.isEmpty
                ? const Text(
                    'No link attached.',
                    style: TextStyle(
                      color: _kTextLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : InkWell(
                    onTap: () => onOpenLink(taskLink),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            taskLink,
                            style: const TextStyle(
                              color: _kPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 14,
                          color: _kPrimary,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          HomeworkPdfSection(
            document: mockDocument,
            canManage: false,
            title: 'Mock Test Document',
            emptyFilename: 'No test document uploaded yet',
            sectionKey: 'mock-pdf',
            onOpen: mockDocument != null
                ? () => onOpenMockPdf(mockDocument!.url)
                : null,
          ),
          const SizedBox(height: 14),
          _RequirementBanner(photoRequired: photoRequired),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController verbalController;
  final TextEditingController mathController;
  final TextEditingController analysisController;
  final bool saving;
  final String? error;
  final String? bannerError;
  final bool canEditFiles;
  final List<PlatformFile> pendingFiles;
  final MockResultDetail? result;
  final VoidCallback onPickFiles;
  final ValueChanged<int> onRemovePending;
  final ValueChanged<HomeworkFile> onDeleteUploaded;
  final ValueChanged<String> onOpenUrl;
  final VoidCallback onSubmit;

  const _SubmissionCard({
    required this.formKey,
    required this.verbalController,
    required this.mathController,
    required this.analysisController,
    required this.saving,
    required this.error,
    required this.bannerError,
    required this.canEditFiles,
    required this.pendingFiles,
    required this.result,
    required this.onPickFiles,
    required this.onRemovePending,
    required this.onDeleteUploaded,
    required this.onOpenUrl,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isUpdate = result != null || pendingFiles.isNotEmpty;
    final showReadOnly = result?.isSubmittedLocked == true;

    return _Panel(
      title: showReadOnly ? 'Submitted Mock Result' : (isUpdate ? 'Update Submission' : 'Submit Mock Result'),
      icon: showReadOnly ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ScoreField(
                    controller: verbalController,
                    label: 'Verbal Points',
                    icon: Icons.menu_book_rounded,
                    color: _kMock,
                    enabled: !saving && !showReadOnly,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreField(
                    controller: mathController,
                    label: 'Math Points',
                    icon: Icons.calculate_rounded,
                    color: _kPrimary,
                    enabled: !saving && !showReadOnly,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: analysisController,
              enabled: !saving && !showReadOnly,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(fontSize: 14, color: _kTextDark),
              decoration: InputDecoration(
                labelText: 'Analysis / Notes',
                hintText: 'What went well? What should your teacher know?',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.psychology_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kPrimary, width: 2),
                ),
                filled: true,
                fillColor: _kBg,
              ),
            ),
            const SizedBox(height: 14),
            if (bannerError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kError.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kError.withOpacity(0.25)),
                ),
                child: Text(
                  bannerError!,
                  style: const TextStyle(
                    color: _kError,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (showReadOnly)
              _MockSubmittedFilesSection(result: result!, onOpenUrl: onOpenUrl)
            else
              _MockFilesEditor(
                pendingFiles: pendingFiles,
                uploadedFiles: result?.attachments ?? const [],
                saving: saving,
                onPickFiles: onPickFiles,
                onRemovePending: onRemovePending,
                onDeleteUploaded: onDeleteUploaded,
                onOpenUrl: onOpenUrl,
                legacyPhotoLink: result?.legacyPhoto == true ? result?.photoLink : null,
              ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kError.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kError.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _kError,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: _kError,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (canEditFiles) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _SubmitButton(saving: saving, onSubmit: onSubmit),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MockFilesEditor extends StatelessWidget {
  final List<PlatformFile> pendingFiles;
  final List<HomeworkFile> uploadedFiles;
  final bool saving;
  final VoidCallback onPickFiles;
  final ValueChanged<int> onRemovePending;
  final ValueChanged<HomeworkFile> onDeleteUploaded;
  final ValueChanged<String> onOpenUrl;
  final String? legacyPhotoLink;

  const _MockFilesEditor({
    required this.pendingFiles,
    required this.uploadedFiles,
    required this.saving,
    required this.onPickFiles,
    required this.onRemovePending,
    required this.onDeleteUploaded,
    required this.onOpenUrl,
    this.legacyPhotoLink,
  });

  @override
  Widget build(BuildContext context) {
    final legacy = (legacyPhotoLink ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proof files (1–10)',
          style: TextStyle(
            color: _kTextDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: pendingFiles.isEmpty && uploadedFiles.isEmpty && legacy.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No files selected',
                    style: TextStyle(color: _kTextLight, fontWeight: FontWeight.w600),
                  ),
                )
              : Column(
                  children: [
                    if (legacy.isNotEmpty)
                      LegacyPhotoListTile(
                        photoLink: legacy,
                        onTap: () => onOpenUrl(legacy),
                      ),
                    for (final file in uploadedFiles)
                      SubmittedFileListTile(
                        file: file,
                        onTap: () => onOpenUrl(file.url),
                        onRemove: saving ? null : () => onDeleteUploaded(file),
                      ),
                    for (var i = 0; i < pendingFiles.length; i++)
                      PendingFileListTile(
                        file: pendingFiles[i],
                        enabled: !saving,
                        onRemove: () => onRemovePending(i),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: saving ? null : onPickFiles,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add files'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kBorder),
          ),
        ),
      ],
    );
  }
}

class _MockSubmittedFilesSection extends StatelessWidget {
  final MockResultDetail result;
  final ValueChanged<String> onOpenUrl;

  const _MockSubmittedFilesSection({
    required this.result,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final attachments = result.attachments;
    final legacyLink = (result.photoLink ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submitted files',
          style: TextStyle(
            color: _kTextDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: attachments.isEmpty && legacyLink.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No files attached',
                    style: TextStyle(color: _kTextLight, fontWeight: FontWeight.w600),
                  ),
                )
              : Column(
                  children: [
                    if (result.legacyPhoto && legacyLink.isNotEmpty)
                      LegacyPhotoListTile(
                        photoLink: legacyLink,
                        onTap: () => onOpenUrl(legacyLink),
                      ),
                    for (final file in attachments)
                      SubmittedFileListTile(
                        file: file,
                        onTap: () => onOpenUrl(file.url),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ScoreField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;

  const _ScoreField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14, color: _kTextDark),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: _kBg,
      ),
      validator: (value) {
        final t = (value ?? '').trim();
        if (t.isEmpty) return null;
        final p = int.tryParse(t);
        if (p == null || p < 0) return 'Use 0 or higher';
        return null;
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onSubmit;

  const _SubmitButton({required this.saving, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: saving ? _kTextLight : _kPrimary,
        boxShadow: saving
            ? []
            : [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.38),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: saving ? const Color(0xFF9DBAE8) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: saving ? null : onSubmit,
          child: Center(
            child: saving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Submitting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Submit Mock Result',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121A4AF0),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3EDFF), Color(0xFFCFDEFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: _kBorder.withOpacity(0.7), height: 22),
          child,
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _InfoBlock({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _kPrimary, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _RequirementBanner extends StatelessWidget {
  final bool photoRequired;

  const _RequirementBanner({required this.photoRequired});

  @override
  Widget build(BuildContext context) {
    final color = photoRequired ? _kMock : _kSuccess;
    final icon = photoRequired
        ? Icons.photo_camera_back_rounded
        : Icons.task_alt_rounded;
    final title = photoRequired ? 'Proof file required' : 'Proof file optional';
    final message = photoRequired
        ? 'Attach a mock result screenshot or PDF before submitting.'
        : 'You can still attach a screenshot or PDF if you want to show your work.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: _kTextMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _DetailPattern extends StatelessWidget {
  const _DetailPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetailPatternPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _DetailPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kPrimary.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    const step = 84.0;
    for (double y = -20; y < size.height + step; y += step) {
      for (double x = -20; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
