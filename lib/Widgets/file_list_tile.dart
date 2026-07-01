import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/models/homework_result.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class PendingFileListTile extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback? onRemove;
  final bool enabled;

  const PendingFileListTile({
    super.key,
    required this.file,
    required this.onRemove,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final ext = file.extension?.toLowerCase() ?? '';
    final isPdf = ext == 'pdf';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isPdf ? Icons.picture_as_pdf : Icons.image,
        color: isPdf ? TuranColors.mock : TuranColors.primary,
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${(file.size / 1024 / 1024).toStringAsFixed(1)} MB',
        style: const TextStyle(color: TuranColors.textMid),
      ),
      trailing: enabled
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onRemove,
            )
          : null,
    );
  }
}

class SubmittedFileListTile extends StatelessWidget {
  final HomeworkAttachment file;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const SubmittedFileListTile({
    super.key,
    required this.file,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: _SubmittedFileLeading(file: file),
      title: Text(
        file.filename,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${file.sizeMb.toStringAsFixed(1)} MB',
        style: const TextStyle(color: TuranColors.textMid),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onTap != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: TuranColors.primary),
              tooltip: 'Open',
              onPressed: onTap,
            ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class LegacyPhotoListTile extends StatelessWidget {
  final String photoLink;
  final VoidCallback? onTap;

  const LegacyPhotoListTile({
    super.key,
    required this.photoLink,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: photoLink,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
        ),
      ),
      title: const Text(
        'Legacy screenshot',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text(
        'Submitted before multi-file upload',
        style: TextStyle(color: TuranColors.textMid),
      ),
      trailing: onTap != null
          ? const Icon(Icons.open_in_new_rounded, color: TuranColors.primary)
          : null,
    );
  }
}

class _SubmittedFileLeading extends StatelessWidget {
  final HomeworkAttachment file;

  const _SubmittedFileLeading({required this.file});

  @override
  Widget build(BuildContext context) {
    if (file.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: file.url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: TuranColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TuranColors.border),
      ),
      child: Icon(
        file.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined,
        color: file.isPdf ? TuranColors.mock : TuranColors.primary,
      ),
    );
  }
}
