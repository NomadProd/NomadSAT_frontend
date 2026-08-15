import 'package:flutter/material.dart';
import 'package:flutter_web/Widgets/desmos_calculator_embed.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DesmosCalculatorPanel extends StatelessWidget {
  final VoidCallback onClose;
  final bool expanded;

  const DesmosCalculatorPanel({
    super.key,
    required this.onClose,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TuranColors.surface,
      elevation: expanded ? 0 : 8,
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: TuranColors.panelBg,
              border: Border(bottom: BorderSide(color: TuranColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_rounded, color: TuranColors.math),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Calculator',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: TuranColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('desmos-calculator-close'),
                  tooltip: 'Close calculator',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Expanded(
            child: DesmosCalculatorEmbed(),
          ),
        ],
      ),
    );
  }
}
