import 'dart:async';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/Models/homework_result.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'package:flutter_web/Utils/homework_pdf.dart';
import 'package:flutter_web/Widgets/file_list_tile.dart';
import 'package:flutter_web/Widgets/homework_pdf_section.dart';

const _kPrimary = TuranColors.primary;
const _kBg = TuranColors.bgAlt;
const _kSurface = TuranColors.surface;
const _kBorder = TuranColors.border;
const _kTextDark = TuranColors.textDark;
const _kTextMid = TuranColors.textMid;
const _kTextLight = TuranColors.textLight;
const _kSuccess = TuranColors.success;
const _kError = TuranColors.error;
const _kWarning = TuranColors.warning;

const _maxFiles = 10;
const _maxFileSizeBytes = 10 * 1024 * 1024;
const _maxFileSizeMessage = 'File size cannot exceed 10mb';
const _allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'pdf'];

class HomeworkSubmitScreen extends StatefulWidget {
  final String title;
  final String className;
  final String deadline;
  final String sessionType;
  final AssignmentInfo assignment;
  final HomeworkResultInfo? result;

  const HomeworkSubmitScreen({
    super.key,
    required this.title,
    required this.className,
    required this.deadline,
    required this.sessionType,
    required this.assignment,
    this.result,
  });

  @override
  State<HomeworkSubmitScreen> createState() => _HomeworkSubmitScreenState();
}

class _HomeworkSubmitScreenState extends State<HomeworkSubmitScreen>
    with SingleTickerProviderStateMixin {
  final _classService = ClassService();
  final _formKey = GlobalKey<FormState>();
  final _correctController = TextEditingController();
  final _incorrectController = TextEditingController();
  final _analysisController = TextEditingController();

  HomeworkResult? _result;
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

    final initial = widget.result;
    if (initial != null) {
      _correctController.text = initial.correctTotal?.toString() ?? '';
      _incorrectController.text = initial.incorrectTotal?.toString() ?? '';
      _analysisController.text = initial.analysis ?? '';
      if (initial.resultId > 0) {
        _reloadResult(initial.resultId);
      }
    } else {
      _loadExistingResultIfAny();
    }
  }

  Future<void> _loadExistingResultIfAny() async {
    try {
      final results = await _classService.fetchHomeworkResultsByAssignment(
        widget.assignment.assignmentId,
      );
      if (results.isEmpty) return;

      final existing = results.first;
      if (existing.resultId <= 0) return;
      if (!mounted) return;

      _correctController.text = existing.correctTotal?.toString() ?? '';
      _incorrectController.text = existing.incorrectTotal?.toString() ?? '';
      _analysisController.text = existing.analysis ?? '';
      await _reloadResult(existing.resultId);
    } catch (_) {}
  }

  Future<int?> _resolveExistingResultId() async {
    final results = await _classService.fetchHomeworkResultsByAssignment(
      widget.assignment.assignmentId,
    );
    if (results.isEmpty) return null;
    final id = results.first.resultId;
    return id > 0 ? id : null;
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _heroAnim.dispose();
    _correctController.dispose();
    _incorrectController.dispose();
    _analysisController.dispose();
    super.dispose();
  }

  Future<void> _reloadResult(int resultId) async {
    try {
      final result = await _classService.fetchHomeworkResult(resultId);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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

  Future<void> _pickFiles() async {
    if (!_canEditFiles || _saving) return;

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final existingCount = _result?.attachments.length ?? 0;
    if (_pendingFiles.length + existingCount + picked.files.length > _maxFiles) {
      _showBannerError('Maximum 10 files per submission');
      return;
    }

    for (final file in picked.files) {
      final ext = (file.extension ?? '').toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        _showBannerError('«${file.name}» is not a supported file type');
        return;
      }
      if (file.size > _maxFileSizeBytes) {
        _showBannerError(_maxFileSizeMessage);
        return;
      }
    }

    setState(() {
      _pendingFiles.addAll(picked.files);
      _error = null;
      _saving = true;
    });

    final resultId = await _ensureResultId();
    if (resultId == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    final filesToUpload = List<PlatformFile>.from(_pendingFiles);
    final upload = await _classService.uploadHomeworkResultFiles(
      resultId: resultId,
      files: filesToUpload,
    );

    if (!mounted) return;

    if (upload['success'] == true) {
      setState(() {
        _result = upload['result'] as HomeworkResult?;
        _pendingFiles.clear();
        _saving = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _saving = false;
      _error = upload['message']?.toString() ?? 'Upload failed';
    });
  }

  void _removePendingFile(int index) {
    setState(() => _pendingFiles.removeAt(index));
  }

  Future<void> _deleteUploadedFile(HomeworkAttachment file) async {
    if (_saving || !_canEditFiles) return;
    final resultId = _result?.id;
    final publicId = file.publicId.trim();
    if (resultId == null || publicId.isEmpty) {
      setState(() => _error = 'Could not delete file');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final ok = await _classService.deleteHomeworkAttachment(
      resultId: resultId,
      publicId: publicId,
    );

    if (!mounted) return;

    if (ok) {
      await _reloadResult(resultId);
      if (mounted) setState(() => _saving = false);
      return;
    }

    setState(() {
      _saving = false;
      _error = 'Could not delete file';
    });
  }

  Future<int?> _ensureResultId() async {
    final existing = _result;
    if (existing != null && existing.id > 0) {
      return existing.id;
    }

    final initial = widget.result;
    if (initial != null && initial.resultId > 0) return initial.resultId;

    final correct = int.tryParse(_correctController.text.trim());
    final incorrect = int.tryParse(_incorrectController.text.trim());
    final analysis = _analysisController.text.trim();

    final created = await _classService.createHomeworkResult(
      assignmentId: widget.assignment.assignmentId,
      submitted: false,
      correctTotal: correct,
      incorrectTotal: incorrect,
      analysis: analysis.isEmpty ? null : analysis,
    );

    if (created['success'] != true) {
      final msg = created['message']?.toString() ?? 'Could not create result';
      if (msg.toLowerCase().contains('already exists')) {
        final resultId = await _resolveExistingResultId();
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

    if (_pendingFiles.isEmpty && !_hasExistingFiles) {
      setState(() => _error = 'Add at least one file');
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
      final upload = await _classService.uploadHomeworkResultFiles(
        resultId: resultId,
        files: List<PlatformFile>.from(_pendingFiles),
      );

      if (upload['success'] != true) {
        setState(() {
          _saving = false;
          _error = upload['message']?.toString() ??
              (upload['status_code'] == 500
                  ? 'Upload failed. Please try again.'
                  : 'Upload failed');
        });
        return;
      }

      _result = upload['result'] as HomeworkResult?;
      _pendingFiles.clear();
    }

    final correct = int.tryParse(_correctController.text.trim());
    final incorrect = int.tryParse(_incorrectController.text.trim());
    final analysis = _analysisController.text.trim();

    final response = await _classService.updateHomeworkResult(
      resultId: resultId,
      submitted: true,
      correctTotal: correct,
      incorrectTotal: incorrect,
      analysis: analysis.isEmpty ? null : analysis,
      photoLink: _result?.photoLink,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      await _reloadResult(resultId);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Submitted!'),
          backgroundColor: _kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _saving = false;
      _error = response['message']?.toString() ?? 'Could not submit homework';
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskLink = (widget.assignment.taskLink ?? '').trim();
    final instruction = (widget.assignment.instruction ?? '').trim();
    final result = _result;
    final showRevisionBanner = result?.isReturnedForRevision == true;

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
                    hasSubmission: result?.submitted == true,
                  ),
                ),
              ),
              if (showRevisionBanner)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _ReturnRevisionBanner(
                    reason: result?.returnReason,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 34),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = _DetailsCard(
                      instruction: instruction,
                      taskLink: taskLink,
                      homeworkDocument: widget.assignment.homeworkDocument,
                      photoRequired: widget.assignment.photoRequired,
                      onOpenLink: _openLink,
                      onOpenHomeworkPdf: _openHomeworkPdf,
                    );
                    final form = _SubmissionCard(
                      formKey: _formKey,
                      correctController: _correctController,
                      incorrectController: _incorrectController,
                      analysisController: _analysisController,
                      saving: _saving,
                      error: _error,
                      bannerError: _bannerError,
                      canEditFiles: _canEditFiles,
                      pendingFiles: _pendingFiles,
                      result: result,
                      onPickFiles: _pickFiles,
                      onRemovePending: _removePendingFile,
                      onOpenUrl: _openLink,
                      onDeleteUploaded: _deleteUploadedFile,
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

class _ReturnRevisionBanner extends StatelessWidget {
  final String? reason;

  const _ReturnRevisionBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kWarning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your homework was returned for revision.',
            style: TextStyle(
              color: _kTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${reason!.trim()}',
              style: const TextStyle(
                color: _kTextMid,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController correctController;
  final TextEditingController incorrectController;
  final TextEditingController analysisController;
  final bool saving;
  final String? error;
  final String? bannerError;
  final bool canEditFiles;
  final List<PlatformFile> pendingFiles;
  final HomeworkResult? result;
  final VoidCallback onPickFiles;
  final ValueChanged<int> onRemovePending;
  final ValueChanged<String> onOpenUrl;
  final ValueChanged<HomeworkAttachment> onDeleteUploaded;
  final VoidCallback onSubmit;

  const _SubmissionCard({
    required this.formKey,
    required this.correctController,
    required this.incorrectController,
    required this.analysisController,
    required this.saving,
    required this.error,
    required this.bannerError,
    required this.canEditFiles,
    required this.pendingFiles,
    required this.result,
    required this.onPickFiles,
    required this.onRemovePending,
    required this.onOpenUrl,
    required this.onDeleteUploaded,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isUpdate = result != null;
    final showReadOnly = result != null && !canEditFiles;

    return _Panel(
      title: isUpdate ? 'Update Submission' : 'Submit Homework',
      icon: isUpdate ? Icons.edit_note_rounded : Icons.upload_file_rounded,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ScoreField(
                    controller: correctController,
                    label: 'Correct',
                    icon: Icons.check_circle_rounded,
                    color: _kSuccess,
                    enabled: !saving,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreField(
                    controller: incorrectController,
                    label: 'Wrong',
                    icon: Icons.cancel_rounded,
                    color: _kError,
                    enabled: !saving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: analysisController,
              enabled: !saving,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(fontSize: 14, color: _kTextDark),
              decoration: InputDecoration(
                labelText: 'Analysis / Notes',
                hintText: 'What was hard? What should your teacher know?',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.psychology_rounded),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                  color: _kError.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kError.withValues(alpha: 0.25)),
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
              _SubmittedFilesSection(result: result!, onOpenUrl: onOpenUrl)
            else ...[
              if (result != null &&
                  (result!.attachments.isNotEmpty ||
                      (result!.photoLink ?? '').trim().isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubmittedFilesSection(
                    result: result!,
                    onOpenUrl: onOpenUrl,
                    onDeleteUploaded: canEditFiles ? onDeleteUploaded : null,
                    saving: saving,
                    title: 'Uploaded files',
                  ),
                ),
              _PendingFilesSection(
                pendingFiles: pendingFiles,
                saving: saving,
                onPickFiles: onPickFiles,
                onRemovePending: onRemovePending,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kError.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kError.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: _kError, size: 18),
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

class _PendingFilesSection extends StatelessWidget {
  final List<PlatformFile> pendingFiles;
  final bool saving;
  final VoidCallback onPickFiles;
  final ValueChanged<int> onRemovePending;

  const _PendingFilesSection({
    required this.pendingFiles,
    required this.saving,
    required this.onPickFiles,
    required this.onRemovePending,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Files',
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
          child: pendingFiles.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No files selected',
                    style: TextStyle(color: _kTextLight, fontWeight: FontWeight.w600),
                  ),
                )
              : Column(
                  children: [
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

class _SubmittedFilesSection extends StatelessWidget {
  final HomeworkResult result;
  final ValueChanged<String> onOpenUrl;
  final ValueChanged<HomeworkAttachment>? onDeleteUploaded;
  final bool saving;
  final String title;

  const _SubmittedFilesSection({
    required this.result,
    required this.onOpenUrl,
    this.onDeleteUploaded,
    this.saving = false,
    this.title = 'Submitted files',
  });

  @override
  Widget build(BuildContext context) {
    final attachments = result.attachments;
    final legacyLink = (result.photoLink ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
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
          child: attachments.isNotEmpty
              ? Column(
                  children: [
                    for (final file in attachments)
                      SubmittedFileListTile(
                        file: file,
                        onTap: () => onOpenUrl(file.url),
                        onRemove: onDeleteUploaded == null || saving
                            ? null
                            : () => onDeleteUploaded!(file),
                      ),
                  ],
                )
              : legacyLink.isNotEmpty
              ? LegacyPhotoListTile(
                  photoLink: legacyLink,
                  onTap: () => onOpenUrl(legacyLink),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No files uploaded',
                    style: TextStyle(color: _kTextLight, fontWeight: FontWeight.w600),
                  ),
                ),
        ),
      ],
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
    pageLabel: 'Homework Details',
    onBack: () => Navigator.of(context).maybePop(),
    bottom: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusBadge(submitted: hasSubmission, photoRequired: photoRequired),
        _HeroChip(icon: Icons.menu_book_rounded, label: sessionType),
        _HeroChip(icon: Icons.schedule_rounded, label: deadline),
      ],
    ),
  );
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.84), size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.90),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
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
    final color = submitted ? _kSuccess : _kWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            submitted ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            submitted ? 'Submitted' : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String instruction;
  final String taskLink;
  final HomeworkDocument? homeworkDocument;
  final bool photoRequired;
  final ValueChanged<String> onOpenLink;
  final ValueChanged<String> onOpenHomeworkPdf;

  const _DetailsCard({
    required this.instruction,
    required this.taskLink,
    required this.homeworkDocument,
    required this.photoRequired,
    required this.onOpenLink,
    required this.onOpenHomeworkPdf,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Assignment Info',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction.isEmpty ? 'No instruction added yet.' : instruction,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          if (taskLink.isNotEmpty)
            InkWell(
              onTap: () => onOpenLink(taskLink),
              child: Text(
                taskLink,
                style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          if (homeworkDocument != null) ...[
            const SizedBox(height: 14),
            HomeworkPdfSection(
              document: homeworkDocument,
              canManage: false,
              onOpen: () => onOpenHomeworkPdf(homeworkDocument!.url),
            ),
          ],
          const SizedBox(height: 14),
          _RequirementBanner(photoRequired: photoRequired),
        ],
      ),
    );
  }
}

class _RequirementBanner extends StatelessWidget {
  final bool photoRequired;
  const _RequirementBanner({required this.photoRequired});

  @override
  Widget build(BuildContext context) {
    final color = photoRequired ? _kWarning : _kSuccess;
    final text = photoRequired
        ? 'File proof is required for this homework.'
        : 'File proof is optional for this homework.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
      ),
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
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onSubmit;
  const _SubmitButton({required this.saving, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: saving ? null : onSubmit,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded),
        label: Text(saving ? 'Submitting...' : 'Submit Homework'),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kPrimary, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(color: _kBorder, height: 24),
          child,
        ],
      ),
    );
  }
}

class _DetailPattern extends StatelessWidget {
  const _DetailPattern();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DetailPatternPainter());
}

class _DetailPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = _kPrimary.withValues(alpha: 0.035);
    canvas.drawCircle(Offset(size.width * 0.06, 260), 130, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
