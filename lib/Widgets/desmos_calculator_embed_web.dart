import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/desmos_config.dart';

class DesmosCalculatorEmbed extends StatefulWidget {
  final bool ignorePointer;

  const DesmosCalculatorEmbed({
    super.key,
    this.ignorePointer = false,
  });

  static final _iframes = <int, html.IFrameElement>{};
  static final _hosts = <int, html.Element>{};

  static void setIgnorePointer(bool ignore) {
    final value = ignore ? 'none' : 'auto';
    for (final host in _hosts.values) {
      host.style.pointerEvents = value;
    }
    for (final iframe in _iframes.values) {
      iframe.style.pointerEvents = value;
    }
  }

  @override
  State<DesmosCalculatorEmbed> createState() => _DesmosCalculatorEmbedState();
}

class _DesmosCalculatorEmbedState extends State<DesmosCalculatorEmbed> {
  static const _viewType = 'desmos-calculator-view';
  static bool _registered = false;

  int? _viewId;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final src =
            '/desmos_calculator.html?apiKey=${Uri.encodeQueryComponent(kDesmosApiKey)}';
        final iframe = html.IFrameElement()
          ..src = src
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..allow = 'clipboard-read; clipboard-write';
        iframe.setAttribute('title', 'Desmos graphing calculator');
        final root = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.overflow = 'hidden'
          ..style.position = 'relative';
        root.append(iframe);
        DesmosCalculatorEmbed._hosts[viewId] = root;
        DesmosCalculatorEmbed._iframes[viewId] = iframe;
        return root;
      });
      _registered = true;
    }
  }

  @override
  void didUpdateWidget(DesmosCalculatorEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ignorePointer != widget.ignorePointer) {
      _syncPointerEvents();
    }
  }

  @override
  void dispose() {
    final id = _viewId;
    if (id != null) {
      DesmosCalculatorEmbed._iframes.remove(id);
      DesmosCalculatorEmbed._hosts.remove(id);
    }
    super.dispose();
  }

  void _syncPointerEvents() {
    DesmosCalculatorEmbed.setIgnorePointer(widget.ignorePointer);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewType,
      key: const Key('desmos-calculator-embed'),
      onPlatformViewCreated: (viewId) {
        _viewId = viewId;
        _syncPointerEvents();
      },
    );
  }
}
