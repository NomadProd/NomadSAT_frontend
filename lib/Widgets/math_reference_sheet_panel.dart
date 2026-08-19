import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/math_reference.dart';
import 'package:flutter_web/theme/turan_theme.dart';

Future<void> showMathReferenceSheet(BuildContext context) {
  final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
  if (compact) {
    final sheetHeight = MediaQuery.sizeOf(context).height * kMathReferenceSheetHeightFactor;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: sheetHeight,
        child: const MathReferenceSheetPanel(),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (context) => const Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SizedBox(
        width: kMathReferenceDialogWidth,
        height: kMathReferenceDialogHeight,
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
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: TuranColors.textDark),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Math Reference',
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
            child: InteractiveViewer(
              key: const Key('math-reference-sheet'),
              minScale: 1,
              maxScale: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kMathReferenceImageMaxWidth,
                    ),
                    child: Image.asset(
                      kMathReferenceAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: kMathReferenceItems
                          .map((item) => item.text)
                          .join('. '),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
