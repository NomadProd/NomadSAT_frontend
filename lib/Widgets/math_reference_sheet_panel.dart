import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/math_reference.dart';
import 'package:flutter_web/theme/turan_theme.dart';

Future<void> showMathReferenceSheet(BuildContext context) {
  final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
  if (compact) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TuranColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SizedBox(
        height: double.infinity,
        child: MathReferenceSheetPanel(),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (context) => const Dialog(
      insetPadding: EdgeInsets.all(24),
      child: SizedBox(
        width: 560,
        height: 640,
        child: MathReferenceSheetPanel(),
      ),
    ),
  );
}

class MathReferenceSheetPanel extends StatelessWidget {
  const MathReferenceSheetPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TuranColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: TuranColors.math),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Reference',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: TuranColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('math-reference-close'),
                  tooltip: 'Close reference',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TuranColors.border),
          Expanded(
            child: ListView.separated(
              key: const Key('math-reference-sheet'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: kMathReferenceItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = kMathReferenceItems[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 20, color: TuranColors.math),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.text,
                        style: const TextStyle(
                          color: TuranColors.textDark,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
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
}
