import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/desmos_config.dart';

class DesmosCalculatorEmbed extends StatefulWidget {
  const DesmosCalculatorEmbed({super.key});

  @override
  State<DesmosCalculatorEmbed> createState() => _DesmosCalculatorEmbedState();
}

class _DesmosCalculatorEmbedState extends State<DesmosCalculatorEmbed> {
  static const _viewType = 'desmos-calculator-view';
  static bool _registered = false;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final src =
            'desmos_calculator.html?apiKey=${Uri.encodeQueryComponent(kDesmosApiKey)}';
        final iframe = html.IFrameElement()
          ..src = src
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'clipboard-read; clipboard-write';
        iframe.setAttribute('title', 'Desmos graphing calculator');
        return iframe;
      });
      _registered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(
      viewType: _viewType,
      key: Key('desmos-calculator-embed'),
    );
  }
}
