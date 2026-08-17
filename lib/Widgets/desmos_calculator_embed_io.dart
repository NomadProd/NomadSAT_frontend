import 'package:flutter/material.dart';
import 'package:flutter_web/Utils/desmos_config.dart';
import 'package:flutter_web/Widgets/desmos_calculator_placeholder.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class DesmosCalculatorEmbed extends StatefulWidget {
  final bool ignorePointer;

  const DesmosCalculatorEmbed({
    super.key,
    this.ignorePointer = false,
  });

  static void setIgnorePointer(bool ignore) {}

  @override
  State<DesmosCalculatorEmbed> createState() => _DesmosCalculatorEmbedState();
}

class _DesmosCalculatorEmbedState extends State<DesmosCalculatorEmbed> {
  WebViewController? _controller;

  bool get _inWidgetTest {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  void initState() {
    super.initState();
    if (_isFlutterTest || _inWidgetTest) return;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..loadHtmlString(
        desmosCalculatorHtml(),
        baseUrl: 'https://www.desmos.com/',
      );
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_isFlutterTest || _inWidgetTest || controller == null) {
      return IgnorePointer(
        ignoring: widget.ignorePointer,
        child: const DesmosCalculatorPlaceholder(),
      );
    }
    return IgnorePointer(
      ignoring: widget.ignorePointer,
      child: WebViewWidget(
        key: const Key('desmos-calculator-embed'),
        controller: controller,
      ),
    );
  }
}
