import 'package:flutter/material.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DesmosCalculatorPlaceholder extends StatelessWidget {
  const DesmosCalculatorPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          'Desmos graphing calculator',
          key: Key('desmos-calculator-embed'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TuranColors.textMid,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
