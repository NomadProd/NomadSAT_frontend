import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/class_service.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'package:flutter_web/widgets/confirm_dialog.dart';

class HomeworkResultDetailScreen extends StatefulWidget {
  final int resultId;
  final int? historyId;
  final String studentName;
  final String sessionLabel;
  final bool isAdmin;

  const HomeworkResultDetailScreen({
    super.key,
    required this.resultId,
    this.historyId,
    required this.studentName,
    required this.sessionLabel,
    required this.isAdmin,
  });

  @override
  State<HomeworkResultDetailScreen> createState() =>
      _HomeworkResultDetailScreenState();
}

class _HomeworkResultDetailScreenState extends State<HomeworkResultDetailScreen> {
  final _classService = ClassService();
  late Future<HomeworkResultDetailInfo> _future;
  final Set<String> _removedPublicIds = {};

  @override
  void initState() {
    super.initState();
    _future = _classService.fetchHomeworkResultDetail(
      widget.resultId,
      historyId: widget.historyId,
    );
  }

  void _reload() {
    setState(() {
      _future = _classService.fetchHomeworkResultDetail(
        widget.resultId,
        historyId: widget.historyId,
      );
    });
  }

  Future<void> _deleteFile(HomeworkFileInfo file) async {
    final publicId = file.publicId;
    if (publicId == null || publicId.isEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete file',
      body: 'Delete «${file.filename}»? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    try {
      final ok = widget.historyId != null
          ? await _classService.deleteHomeworkHistoryAttachment(
              resultId: widget.resultId,
              historyId: widget.historyId!,
              publicId: publicId,
            )
          : await _classService.deleteHomeworkAttachment(
              resultId: widget.resultId,
              publicId: publicId,
            );
      if (!mounted) return;
      if (ok) {
        setState(() => _removedPublicIds.add(publicId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete file')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete file')),
      );
    }
  }

  Future<void> _returnForRevision(HomeworkResultDetailInfo result) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Return for Revision'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TuranColors.warning,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Return'),
          ),
        ],
      ),
    );

    final reasonText = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !mounted) return;

    final response = await _classService.returnHomeworkForRevision(
      resultId: result.id,
      reason: reasonText.isEmpty ? null : reasonText,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Homework returned to student')),
      );
      return;
    }

    final message = switch (response['error']?.toString()) {
      'ALREADY_RETURNED' => 'This homework is already pending revision',
      'NOT_SUBMITTED' => 'Homework has not been submitted yet',
      _ => response['message']?.toString() ??
          'Failed to return homework. Try again.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: widget.historyId != null
                ? 'Previous submission'
                : 'Homework result',
            subtitle: '${widget.studentName} · ${widget.sessionLabel}',
            pageLabel: 'Admin',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: FutureBuilder<HomeworkResultDetailInfo>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: TuranColors.primary),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      snap.error.toString(),
                      style: const TextStyle(color: TuranColors.error),
                    ),
                  );
                }

                final result = snap.data!;
                final files = _visibleFiles(result);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
                  children: [
                    _SummaryCard(result: result),
                    if (widget.isAdmin &&
                        result.submitted &&
                        !result.isHistorical) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: TuranColors.warning,
                            foregroundColor: TuranColors.textDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _returnForRevision(result),
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Return for Revision'),
                        ),
                      ),
                    ],
                    if (result.isReturnedForRevision) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: TuranColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(TuranRadius.lg),
                          border: Border.all(
                            color: TuranColors.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pending student revision',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: TuranColors.textDark,
                              ),
                            ),
                            if ((result.returnReason ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Reason: ${result.returnReason!.trim()}',
                                style: TuranTextStyles.subtitle,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      result.isHistorical
                          ? 'Submission files'
                          : result.isReturnedForRevision
                              ? 'Original submission files'
                              : 'Attachments',
                      style: TuranTextStyles.title.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    if (files.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: TuranColors.surface,
                          borderRadius: BorderRadius.circular(TuranRadius.xl),
                          border: Border.all(color: TuranColors.border),
                        ),
                        child: const Text(
                          'No files uploaded yet.',
                          style: TuranTextStyles.subtitle,
                        ),
                      )
                    else
                      ...files.map(
                        (file) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AttachmentTile(
                            file: file,
                            showDelete: widget.isAdmin &&
                                (result.isHistorical ||
                                    !result.isReturnedForRevision),
                            onOpen: () => html.window.open(file.url, '_blank'),
                            onDelete: () => _deleteFile(file),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<HomeworkFileInfo> _visibleFiles(HomeworkResultDetailInfo result) {
    final source = result.isHistorical
        ? result.attachments
        : result.isReturnedForRevision &&
                result.originalAttachments.isNotEmpty
            ? result.originalAttachments
            : result.attachments;

    if (source.isNotEmpty) {
      return source
          .where(
            (file) =>
                file.publicId == null ||
                !_removedPublicIds.contains(file.publicId),
          )
          .toList();
    }
    if (result.legacyPhoto && (result.photoLink ?? '').isNotEmpty) {
      return [
        HomeworkFileInfo(
          id: 0,
          url: result.photoLink!,
          filename: 'Legacy screenshot',
          contentType: 'image/jpeg',
          sizeBytes: 0,
          uploadedAt: result.submittedAt,
        ),
      ];
    }
    return const [];
  }
}

class _SummaryCard extends StatelessWidget {
  final HomeworkResultDetailInfo result;

  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.xl),
        border: Border.all(color: TuranColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.submitted ? 'Submitted' : 'Not submitted',
            style: TuranTextStyles.title.copyWith(
              color: result.submitted ? TuranColors.success : TuranColors.warning,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Correct: ${result.correctTotal ?? '-'}  |  Incorrect: ${result.incorrectTotal ?? '-'}',
            style: TuranTextStyles.subtitle,
          ),
          if ((result.analysis ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(result.analysis!.trim(), style: TuranTextStyles.body),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final HomeworkFileInfo file;
  final bool showDelete;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _AttachmentTile({
    required this.file,
    required this.showDelete,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = file.isPdf
        ? Icons.picture_as_pdf_rounded
        : file.isImage
        ? Icons.image_rounded
        : Icons.insert_drive_file_rounded;

    return Material(
      color: TuranColors.surface,
      borderRadius: BorderRadius.circular(TuranRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TuranRadius.lg),
            border: Border.all(color: TuranColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: TuranColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TuranTextStyles.label.copyWith(
                        color: TuranColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.contentType,
                      style: TuranTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (showDelete &&
                  file.publicId != null &&
                  file.publicId!.isNotEmpty)
                IconButton(
                  tooltip: 'Delete file',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: TuranColors.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
