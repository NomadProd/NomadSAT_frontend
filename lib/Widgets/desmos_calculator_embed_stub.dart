import 'package:flutter/material.dart';
import 'package:flutter_web/Widgets/desmos_calculator_placeholder.dart';

class DesmosCalculatorEmbed extends StatelessWidget {
  final bool ignorePointer;

  const DesmosCalculatorEmbed({
    super.key,
    this.ignorePointer = false,
  });

  static void setIgnorePointer(bool ignore) {}

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: ignorePointer,
      child: const DesmosCalculatorPlaceholder(),
    );
  }
}
