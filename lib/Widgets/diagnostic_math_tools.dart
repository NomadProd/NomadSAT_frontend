import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/desmos_config.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticMathToolsBar extends StatelessWidget {
  final bool calculatorOpen;
  final VoidCallback onToggleCalculator;
  final VoidCallback onOpenReference;

  const DiagnosticMathToolsBar({
    super.key,
    required this.calculatorOpen,
    required this.onToggleCalculator,
    required this.onOpenReference,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            key: const Key('diagnostic-reference-button'),
            onPressed: onOpenReference,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
            ),
            child: Text(
              compact ? 'Ref' : 'Reference',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            key: const Key('diagnostic-calculator-button'),
            tooltip: calculatorOpen ? 'Hide calculator' : 'Show calculator',
            onPressed: onToggleCalculator,
            icon: Icon(
              calculatorOpen
                  ? Icons.calculate_rounded
                  : Icons.calculate_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosticMathToolsHint extends StatelessWidget {
  final VoidCallback onDismiss;

  const DiagnosticMathToolsHint({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE0F2F1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: TuranColors.math, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                kDesmosCalculatorHint,
                key: Key('diagnostic-math-tools-hint'),
                style: TextStyle(
                  color: TuranColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
