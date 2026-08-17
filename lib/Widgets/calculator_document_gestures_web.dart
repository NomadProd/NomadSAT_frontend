import 'dart:html' as html;

html.EventListener? _moveListener;
html.EventListener? _upListener;
int _startedAtMs = 0;
bool _seenHeldButton = false;

void startCalculatorDocumentGesture({
  required void Function(double dx, double dy) onMove,
  required void Function() onEnd,
}) {
  stopCalculatorDocumentGesture();
  _startedAtMs = DateTime.now().millisecondsSinceEpoch;
  _seenHeldButton = false;

  _moveListener = (html.Event event) {
    final mouse = event as html.MouseEvent;
    if (mouse.buttons != 0) {
      _seenHeldButton = true;
      onMove(mouse.movement.x.toDouble(), mouse.movement.y.toDouble());
      return;
    }
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startedAtMs;
    if (!_seenHeldButton && elapsed < 120) {
      return;
    }
    _finish(onEnd);
  };
  _upListener = (html.Event event) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startedAtMs;
    if (elapsed < 120 && !_seenHeldButton) {
      return;
    }
    _finish(onEnd);
  };

  html.window.addEventListener('pointermove', _moveListener, true);
  html.window.addEventListener('pointerup', _upListener, true);
  html.window.addEventListener('pointercancel', _upListener, true);
  html.window.addEventListener('mouseup', _upListener, true);
  html.window.addEventListener('lostpointercapture', _upListener, true);
}

void stopCalculatorDocumentGesture() {
  if (_moveListener != null) {
    html.window.removeEventListener('pointermove', _moveListener, true);
    _moveListener = null;
  }
  if (_upListener != null) {
    html.window.removeEventListener('pointerup', _upListener, true);
    html.window.removeEventListener('pointercancel', _upListener, true);
    html.window.removeEventListener('mouseup', _upListener, true);
    html.window.removeEventListener('lostpointercapture', _upListener, true);
    _upListener = null;
  }
  _seenHeldButton = false;
}

void _finish(void Function() onEnd) {
  stopCalculatorDocumentGesture();
  onEnd();
}
