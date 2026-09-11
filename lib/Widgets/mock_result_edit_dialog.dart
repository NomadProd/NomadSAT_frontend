import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Models/mock_result.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/class_service.dart';

/// Staff correction dialog for an already-submitted mock result.
/// Shared by the control panel and the class detail page, so tutors reach the
/// same editor admins do (the backend PATCH already allows teacher/mentor/admin).
Future<void> showMockResultEditDialog({
  required BuildContext context,
  required MockResultInfo result,
  required ClassService classService,
  required VoidCallback onChanged,
}) async {
  bool submitted = result.submitted;
  final verbalController = TextEditingController(
    text: result.verbalPoints?.toString() ?? '',
  );
  final mathController = TextEditingController(
    text: result.mathPoints?.toString() ?? '',
  );
  final weakAreasController = TextEditingController(
    text: result.weakAreas ?? '',
  );
  final verbalIncorrectController = TextEditingController(
    text: result.verbalIncorrect?.toString() ?? '',
  );
  final mathIncorrectController = TextEditingController(
    text: result.mathIncorrect?.toString() ?? '',
  );
  MockResultDetail? detail;
  String? filesError;

  try {
    detail = await classService.fetchMockResult(result.resultId);
  } catch (e) {
    filesError = userFacingError(e);
  }

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit mock result'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 170,
                  child: SwitchListTile(
                    value: submitted,
                    onChanged: (value) => setDialogState(() => submitted = value),
                    title: const Text('Submitted'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                _Field(width: 120, controller: verbalController, label: 'Verbal'),
                _Field(width: 120, controller: mathController, label: 'Math'),
                _Field(
                  width: 160,
                  controller: verbalIncorrectController,
                  label: 'Verbal incorrect',
                ),
                _Field(
                  width: 160,
                  controller: mathIncorrectController,
                  label: 'Math incorrect',
                ),
                SizedBox(
                  width: 440,
                  child: TextField(
                    controller: weakAreasController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Weak areas'),
                  ),
                ),
                SizedBox(
                  width: 440,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attached files',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (filesError != null)
                        Text(filesError!, style: const TextStyle(color: Colors.red))
                      else if (detail == null)
                        const Text('Loading files...')
                      else if (detail!.attachments.isEmpty &&
                          !(detail!.legacyPhoto && (detail!.photoLink ?? '').isNotEmpty))
                        const Text('No files attached')
                      else ...[
                        if (detail!.legacyPhoto && (detail!.photoLink ?? '').isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Legacy proof'),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () => html.window.open(detail!.photoLink!, '_blank'),
                            ),
                          ),
                        for (final file in detail!.attachments)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(file.filename, overflow: TextOverflow.ellipsis),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => html.window.open(file.url, '_blank'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    final fileId = file.id;
                                    if (fileId == null) return;
                                    final ok = await classService.deleteMockFile(fileId);
                                    if (!context.mounted) return;
                                    if (ok) {
                                      detail = await classService.fetchMockResult(
                                        result.resultId,
                                      );
                                      setDialogState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final update = await classService.updateMockResult(
                resultId: result.resultId,
                submitted: submitted,
                verbalPoints: int.tryParse(verbalController.text.trim()),
                mathPoints: int.tryParse(mathController.text.trim()),
                verbalIncorrect: int.tryParse(verbalIncorrectController.text.trim()),
                mathIncorrect: int.tryParse(mathIncorrectController.text.trim()),
                weakAreas: weakAreasController.text.trim(),
              );
              if (!context.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(update['message']?.toString() ?? 'Done'),
                  backgroundColor: update['success'] == true
                      ? const Color(0xFF1B873F)
                      : const Color(0xFFC62828),
                ),
              );
              if (update['success'] == true) onChanged();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final String label;

  const _Field({
    required this.width,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
