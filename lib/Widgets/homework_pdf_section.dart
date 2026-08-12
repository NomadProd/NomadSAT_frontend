import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class HomeworkPdfSection extends StatelessWidget {
  final HomeworkDocument? document;
  final PlatformFile? pendingFile;
  final bool canManage;
  final bool uploading;
  final String? message;
  final bool messageIsError;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;
  final VoidCallback? onClearPending;
  final String title;
  final String emptyFilename;
  final String uploadLabel;
  final String sectionKey;

  const HomeworkPdfSection({
    super.key,
    this.document,
    this.pendingFile,
    required this.canManage,
    this.uploading = false,
    this.message,
    this.messageIsError = false,
    this.onPick,
    this.onRemove,
    this.onOpen,
    this.onClearPending,
    this.title = 'Homework PDF',
    this.emptyFilename = 'No PDF selected',
    this.uploadLabel = 'Upload homework PDF',
    this.sectionKey = 'homework-pdf',
  });

  bool get _hasDocument => document != null && document!.url.isNotEmpty;

  String get _filename {
    if (pendingFile != null) return pendingFile!.name;
    return document?.filename ?? emptyFilename;
  }

  String? get _sizeLabel {
    if (pendingFile != null) {
      return '${(pendingFile!.size / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    if (document != null) {
      return '${document!.sizeMb.toStringAsFixed(2)} MB';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: Key('$sectionKey-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: TuranColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 560;
              final info = _FileInfo(
                filename: _filename,
                sizeLabel: _sizeLabel,
                hasFile: _hasDocument || pendingFile != null,
                filenameKey: '$sectionKey-filename',
              );
              final actions = _ActionRow(
                canManage: canManage,
                hasDocument: _hasDocument,
                hasPending: pendingFile != null,
                uploading: uploading,
                onPick: onPick,
                onRemove: onRemove,
                onOpen: _hasDocument ? onOpen : null,
                onClearPending: onClearPending,
                uploadLabel: uploadLabel,
                sectionKey: sectionKey,
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [info, const SizedBox(height: 10), actions],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
          if (uploading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              key: Key('$sectionKey-progress'),
              minHeight: 4,
            ),
          ],
          if ((message ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              key: Key('$sectionKey-message'),
              style: TextStyle(
                color: messageIsError ? TuranColors.error : TuranColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FileInfo extends StatelessWidget {
  final String filename;
  final String? sizeLabel;
  final bool hasFile;
  final String filenameKey;

  const _FileInfo({
    required this.filename,
    required this.sizeLabel,
    required this.hasFile,
    required this.filenameKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TuranColors.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TuranColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            color: hasFile ? TuranColors.mock : TuranColors.textLight,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  key: Key(filenameKey),
                  softWrap: true,
                  style: const TextStyle(
                    color: TuranColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                if (sizeLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sizeLabel!,
                    style: const TextStyle(
                      color: TuranColors.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool canManage;
  final bool hasDocument;
  final bool hasPending;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;
  final VoidCallback? onClearPending;
  final String uploadLabel;
  final String sectionKey;

  const _ActionRow({
    required this.canManage,
    required this.hasDocument,
    required this.hasPending,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
    required this.onOpen,
    required this.onClearPending,
    required this.uploadLabel,
    required this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (onOpen != null)
        _PdfButton(
          key: Key('$sectionKey-open'),
          icon: Icons.open_in_new_rounded,
          label: 'Open PDF',
          onPressed: uploading ? null : onOpen,
        ),
      if (canManage)
        _PdfButton(
          key: Key(hasDocument ? '$sectionKey-replace' : '$sectionKey-upload'),
          icon: Icons.upload_file_rounded,
          label: hasDocument ? 'Replace PDF' : uploadLabel,
          filled: true,
          onPressed: uploading ? null : onPick,
        ),
      if (canManage && hasDocument)
        _PdfButton(
          key: Key('$sectionKey-remove'),
          icon: Icons.delete_outline_rounded,
          label: 'Remove PDF',
          destructive: true,
          onPressed: uploading ? null : onRemove,
        ),
      if (canManage && hasPending && !hasDocument)
        _PdfButton(
          key: Key('$sectionKey-clear-pending'),
          icon: Icons.close_rounded,
          label: 'Remove PDF',
          destructive: true,
          onPressed: uploading ? null : onClearPending,
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: buttons,
    );
  }
}

class _PdfButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool destructive;

  const _PdfButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? TuranColors.error : TuranColors.primary;
    if (filled && !destructive) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
    );
  }
}
