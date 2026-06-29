import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';

// в”Ђв”Ђв”Ђ Design Tokens в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
const _kPrimary = Color(0xFF1A4AF0);
const _kPrimaryDark = Color(0xFF1A4AF0);
const _kBg = Color(0xFFF2F6FF);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFD7E3FF);
const _kTextDark = Color(0xFF0D1B3E);
const _kTextMid = Color(0xFF4A5A7A);
const _kTextLight = Color(0xFF9AAAC6);
const _kSuccess = Color(0xFF1B873F);
const _kError = Color(0xFFC62828);
const _kWarning = Color(0xFFBF6000);

// в”Ђв”Ђв”Ђ Page в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class HomeworkDetailPage extends StatefulWidget {
  final String title;
  final String className;
  final String deadline;
  final String sessionType;
  final AssignmentInfo assignment;
  final HomeworkResultInfo? result;

  const HomeworkDetailPage({
    super.key,
    required this.title,
    required this.className,
    required this.deadline,
    required this.sessionType,
    required this.assignment,
    this.result,
  });

  @override
  State<HomeworkDetailPage> createState() => _HomeworkDetailPageState();
}

class _HomeworkDetailPageState extends State<HomeworkDetailPage>
    with SingleTickerProviderStateMixin {
  final _classService = ClassService();
  final _formKey = GlobalKey<FormState>();
  final _correctController = TextEditingController();
  final _incorrectController = TextEditingController();
  final _analysisController = TextEditingController();

  String? _photoLink;
  String? _selectedFileName;
  html.File? _selectedPhotoFile;
  bool _dragging = false;
  bool _saving = false;
  String? _error;

  late AnimationController _heroAnim;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  StreamSubscription<html.MouseEvent>? _dragOverSub;
  StreamSubscription<html.MouseEvent>? _dragLeaveSub;
  StreamSubscription<html.MouseEvent>? _dropSub;

  @override
  void initState() {
    super.initState();

    // Hero entrance animation
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
      _correctController.text = result.correctTotal?.toString() ?? '';
      _incorrectController.text = result.incorrectTotal?.toString() ?? '';
      _analysisController.text = result.analysis ?? '';
      _photoLink = result.photoLink;
      if ((_photoLink ?? '').isNotEmpty) {
        _selectedFileName = 'Submitted screenshot';
      }
    }
    _wireBrowserDrop();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _correctController.dispose();
    _incorrectController.dispose();
    _analysisController.dispose();
    _dragOverSub?.cancel();
    _dragLeaveSub?.cancel();
    _dropSub?.cancel();
    super.dispose();
  }

  void _wireBrowserDrop() {
    _dragOverSub = html.document.onDragOver.listen((e) {
      e.preventDefault();
      if (!_saving && mounted) setState(() => _dragging = true);
    });
    _dragLeaveSub = html.document.onDragLeave.listen((e) {
      e.preventDefault();
      if (mounted) setState(() => _dragging = false);
    });
    _dropSub = html.document.onDrop.listen((e) {
      e.preventDefault();
      if (_saving) return;
      final file = e.dataTransfer.files?.isNotEmpty == true
          ? e.dataTransfer.files!.first
          : null;
      if (mounted) setState(() => _dragging = false);
      if (file != null) _setSelectedPhoto(file);
    });
  }

  void _openLink(String url) {
    final t = url.trim();
    if (t.isEmpty) return;
    final withScheme = t.startsWith(RegExp(r'https?://')) ? t : 'https://$t';
    html.window.open(withScheme, '_blank');
  }

  Future<void> _pickScreenshot() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;
    input.click();
    await input.onChange.first;
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) return;
    _setSelectedPhoto(file);
  }

  void _setSelectedPhoto(html.File file) {
    setState(() {
      _selectedFileName = file.name;
      _selectedPhotoFile = file;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final hasPhoto =
        _selectedPhotoFile != null || (_photoLink ?? '').isNotEmpty;
    if (widget.assignment.photoRequired && !hasPhoto) {
      setState(() => _error = 'Please add a screenshot before submitting.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final correct = int.tryParse(_correctController.text.trim());
    final incorrect = int.tryParse(_incorrectController.text.trim());
    final analysis = _analysisController.text.trim();

    final response = widget.result == null
        ? await _classService.createHomeworkResult(
            assignmentId: widget.assignment.assignmentId,
            submitted: true,
            photoFile: _selectedPhotoFile,
            photoLink: _photoLink,
            correctTotal: correct,
            incorrectTotal: incorrect,
            analysis: analysis.isEmpty ? null : analysis,
          )
        : await _classService.updateHomeworkResult(
            resultId: widget.result!.resultId,
            submitted: true,
            photoFile: _selectedPhotoFile,
            photoLink: _photoLink,
            correctTotal: correct,
            incorrectTotal: incorrect,
            analysis: analysis.isEmpty ? null : analysis,
          );

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Homework submitted',
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
      _error = response['message']?.toString() ?? 'Could not submit homework';
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskLink = (widget.assignment.taskLink ?? '').trim();
    final instruction = (widget.assignment.instruction ?? '').trim();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _DetailPattern()),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              // в”Ђв”Ђ Full-bleed Hero в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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
                    hasSubmission: widget.result != null,
                  ),
                ),
              ),

              // в”Ђв”Ђ Body content в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 34),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = _DetailsCard(
                      instruction: instruction,
                      taskLink: taskLink,
                      photoRequired: widget.assignment.photoRequired,
                      onOpenLink: _openLink,
                    );
                    final form = _SubmissionCard(
                      formKey: _formKey,
                      correctController: _correctController,
                      incorrectController: _incorrectController,
                      analysisController: _analysisController,
                      photoLink: _photoLink,
                      selectedFileName: _selectedFileName,
                      dragging: _dragging,
                      saving: _saving,
                      error: _error,
                      existingResult: widget.result,
                      onPickScreenshot: _pickScreenshot,
                      onOpenPhoto: _photoLink == null
                          ? null
                          : () => _openLink(_photoLink!),
                      onSubmit: _submit,
                      onDragChanged: (v) => setState(() => _dragging = v),
                      onDropped: _setSelectedPhoto,
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

// ─── Full-bleed Hero ───────────────────────────────────────────────────────────
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

class _StatusBadge extends StatelessWidget {
  final bool submitted;
  final bool photoRequired;

  const _StatusBadge({required this.submitted, required this.photoRequired});

  @override
  Widget build(BuildContext context) {
    final color = submitted ? _kSuccess : _kWarning;
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

// ─── Details Card ────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final String instruction;
  final String taskLink;
  final bool photoRequired;
  final ValueChanged<String> onOpenLink;

  const _DetailsCard({
    required this.instruction,
    required this.taskLink,
    required this.photoRequired,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Assignment Info',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBlock(
            label: 'Instruction',
            icon: Icons.notes_rounded,
            child: Text(
              instruction.isEmpty ? 'No instruction added yet.' : instruction,
              style: const TextStyle(
                color: _kTextDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _InfoBlock(
            label: 'Task Link',
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
          _RequirementBanner(photoRequired: photoRequired),
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Submission Card в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _SubmissionCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController correctController;
  final TextEditingController incorrectController;
  final TextEditingController analysisController;
  final String? photoLink;
  final String? selectedFileName;
  final bool dragging;
  final bool saving;
  final String? error;
  final HomeworkResultInfo? existingResult;
  final VoidCallback onPickScreenshot;
  final VoidCallback? onOpenPhoto;
  final VoidCallback onSubmit;
  final ValueChanged<bool> onDragChanged;
  final ValueChanged<html.File> onDropped;

  const _SubmissionCard({
    required this.formKey,
    required this.correctController,
    required this.incorrectController,
    required this.analysisController,
    required this.photoLink,
    required this.selectedFileName,
    required this.dragging,
    required this.saving,
    required this.error,
    required this.existingResult,
    required this.onPickScreenshot,
    required this.onOpenPhoto,
    required this.onSubmit,
    required this.onDragChanged,
    required this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    final isUpdate = existingResult != null;
    return _Panel(
      title: isUpdate ? 'Update Submission' : 'Submit Homework',
      icon: isUpdate ? Icons.edit_note_rounded : Icons.upload_file_rounded,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score row
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

            // Analysis
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

            // Drop zone
            _ScreenshotDropZone(
              photoLink: photoLink,
              selectedFileName: selectedFileName,
              dragging: dragging,
              saving: saving,
              onPick: onPickScreenshot,
              onOpenPhoto: onOpenPhoto,
              onDragChanged: onDragChanged,
              onDropped: onDropped,
            ),

            // Error
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

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: _SubmitButton(saving: saving, onSubmit: onSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Score Field в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

// в”Ђв”Ђв”Ђ Submit Button в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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
                        'Submit Homework',
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

// в”Ђв”Ђв”Ђ Screenshot Drop Zone в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _ScreenshotDropZone extends StatelessWidget {
  final String? photoLink;
  final String? selectedFileName;
  final bool dragging;
  final bool saving;
  final VoidCallback onPick;
  final VoidCallback? onOpenPhoto;
  final ValueChanged<bool> onDragChanged;
  final ValueChanged<html.File> onDropped;

  const _ScreenshotDropZone({
    required this.photoLink,
    required this.selectedFileName,
    required this.dragging,
    required this.saving,
    required this.onPick,
    required this.onOpenPhoto,
    required this.onDragChanged,
    required this.onDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<html.File>(
      onWillAcceptWithDetails: (_) {
        if (!saving) onDragChanged(true);
        return !saving;
      },
      onLeave: (_) => onDragChanged(false),
      onAcceptWithDetails: (details) {
        onDragChanged(false);
        onDropped(details.data);
      },
      builder: (context, candidateData, _) {
        final hasPhoto =
            (photoLink ?? '').isNotEmpty || (selectedFileName ?? '').isNotEmpty;
        final hasUploadedPhoto = (photoLink ?? '').isNotEmpty;
        final active = dragging || candidateData.isNotEmpty;

        return GestureDetector(
          onTap: saving ? null : onPick,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: active
                  ? _kPrimary.withOpacity(0.09)
                  : hasPhoto
                  ? _kSuccess.withOpacity(0.06)
                  : _kBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active
                    ? _kPrimary
                    : hasPhoto
                    ? _kSuccess.withOpacity(0.40)
                    : _kBorder,
                width: active ? 2 : 1.5,
              ),
            ),
            child: Column(
              children: [
                // Icon circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasPhoto
                          ? [
                              _kSuccess.withOpacity(0.20),
                              _kSuccess.withOpacity(0.10),
                            ]
                          : [
                              _kPrimary.withOpacity(0.20),
                              _kPrimary.withOpacity(0.10),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasPhoto
                        ? Icons.image_rounded
                        : active
                        ? Icons.file_download_rounded
                        : Icons.cloud_upload_rounded,
                    color: hasPhoto ? _kSuccess : _kPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasPhoto
                      ? selectedFileName ?? 'Screenshot attached'
                      : active
                      ? 'Release to attach'
                      : 'Drag screenshot here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasPhoto ? _kSuccess : _kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasPhoto
                      ? 'Temporary URL generated - tap to replace'
                      : 'or tap to choose an image from your device',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _kTextMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: hasUploadedPhoto ? onOpenPhoto : null,
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: Text(
                      hasUploadedPhoto ? 'Open screenshot' : 'Upload pending',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kBorder, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// в”Ђв”Ђв”Ђ Panel в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: _kBorder, height: 24),
          child,
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Info Block в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: _kTextLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Requirement Banner в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
class _RequirementBanner extends StatelessWidget {
  final bool photoRequired;
  const _RequirementBanner({required this.photoRequired});

  @override
  Widget build(BuildContext context) {
    final color = photoRequired ? _kWarning : _kSuccess;
    final icon = photoRequired
        ? Icons.photo_camera_rounded
        : Icons.task_alt_rounded;
    final text = photoRequired
        ? 'Screenshot proof is required for this homework.'
        : 'Screenshot proof is optional for this homework.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// в”Ђв”Ђв”Ђ Background Pattern в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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
    p.color = _kPrimary.withOpacity(0.035);
    canvas.drawCircle(Offset(size.width * 0.06, 260), 130, p);
    p.color = _kSuccess.withOpacity(0.03);
    canvas.drawCircle(Offset(size.width * 0.96, 480), 160, p);
    p.color = _kWarning.withOpacity(0.028);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.88), 120, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
