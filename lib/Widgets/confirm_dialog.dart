import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Delete',
  Color confirmColor = const Color(0xFFC62828),
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => ConfirmDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
    ),
  );
  return result == true;
}
