import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/Widgets/calculator_document_gestures.dart';
import 'package:flutter_web/Widgets/desmos_calculator_embed.dart';
import 'package:flutter_web/theme/turan_theme.dart';

const _kMinCalculatorSize = Size(280, 240);
const _kDefaultCalculatorSize = Size(480, 420);
const _kResizeGutter = 32.0;

enum _WindowGesture { none, drag, resize }

class DesmosCalculatorPanel extends StatefulWidget {
  final VoidCallback onClose;

  const DesmosCalculatorPanel({
    super.key,
    required this.onClose,
  });

  @override
  State<DesmosCalculatorPanel> createState() => _DesmosCalculatorPanelState();
}

class _DesmosCalculatorPanelState extends State<DesmosCalculatorPanel> {
  Offset _offset = const Offset(16, 16);
  Size _size = _kDefaultCalculatorSize;
  Size _parentSize = Size.zero;
  bool _placed = false;
  bool _blockingEmbed = false;
  _WindowGesture _gesture = _WindowGesture.none;

  double _bounded(double value, double minExtent, double maxExtent) {
    if (!maxExtent.isFinite || maxExtent <= 0) {
      return 0;
    }
    final lower = math.min(minExtent, maxExtent);
    return value.clamp(lower, maxExtent);
  }

  void _placeIfNeeded(BoxConstraints constraints) {
    if (_placed) return;
    _placed = true;
    final maxWidth = math.max(0.0, constraints.maxWidth - 24);
    final maxHeight = math.max(0.0, constraints.maxHeight - 24);
    _size = Size(
      _bounded(
        _kDefaultCalculatorSize.width,
        _kMinCalculatorSize.width,
        maxWidth,
      ),
      _bounded(
        _kDefaultCalculatorSize.height,
        _kMinCalculatorSize.height,
        maxHeight,
      ),
    );
    _offset = Offset(
      _bounded(16, 0, constraints.maxWidth - _size.width),
      _bounded(16, 0, constraints.maxHeight - _size.height),
    );
  }

  Offset _clampedOffset(Offset next, Size parentSize, Size windowSize) {
    return Offset(
      _bounded(next.dx, 0, parentSize.width - windowSize.width),
      _bounded(next.dy, 0, parentSize.height - windowSize.height),
    );
  }

  Size _clampedSize(Size next, Size parentSize, Offset origin) {
    return Size(
      _bounded(
        next.width,
        _kMinCalculatorSize.width,
        parentSize.width - origin.dx,
      ),
      _bounded(
        next.height,
        _kMinCalculatorSize.height,
        parentSize.height - origin.dy,
      ),
    );
  }

  void _onDocumentMove(double dx, double dy) {
    if (_gesture == _WindowGesture.none) return;
    setState(() {
      if (_gesture == _WindowGesture.drag) {
        _offset = _clampedOffset(
          _offset + Offset(dx, dy),
          _parentSize,
          _size,
        );
      } else if (_gesture == _WindowGesture.resize) {
        _size = _clampedSize(
          Size(_size.width + dx, _size.height + dy),
          _parentSize,
          _offset,
        );
      }
    });
  }

  void _beginWindowGesture(_WindowGesture gesture) {
    _gesture = gesture;
    DesmosCalculatorEmbed.setIgnorePointer(true);
    startCalculatorDocumentGesture(
      onMove: _onDocumentMove,
      onEnd: _endWindowGesture,
    );
    setState(() => _blockingEmbed = true);
  }

  void _endWindowGesture() {
    stopCalculatorDocumentGesture();
    DesmosCalculatorEmbed.setIgnorePointer(false);
    if (!mounted) return;
    setState(() {
      _blockingEmbed = false;
      _gesture = _WindowGesture.none;
    });
  }

  @override
  void dispose() {
    stopCalculatorDocumentGesture();
    DesmosCalculatorEmbed.setIgnorePointer(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _placeIfNeeded(constraints);
        _parentSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        final offset = _clampedOffset(_offset, _parentSize, _size);
        final size = _clampedSize(_size, _parentSize, offset);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              height: size.height,
              child: Material(
                key: const Key('desmos-calculator-window'),
                color: TuranColors.surface,
                elevation: 12,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        border: Border(
                          bottom: BorderSide(color: TuranColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.move,
                              child: Listener(
                                onPointerDown: (_) {
                                  _beginWindowGesture(_WindowGesture.drag);
                                },
                                child: GestureDetector(
                                  key: const Key('desmos-calculator-drag-handle'),
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: kIsWeb
                                      ? null
                                      : (_) {
                                          _beginWindowGesture(_WindowGesture.drag);
                                        },
                                  onPanUpdate: kIsWeb
                                      ? null
                                      : (details) {
                                          setState(() {
                                            _offset = _clampedOffset(
                                              _offset + details.delta,
                                              _parentSize,
                                              _size,
                                            );
                                          });
                                        },
                                  onPanEnd: kIsWeb ? null : (_) => _endWindowGesture(),
                                  onPanCancel: kIsWeb ? null : _endWindowGesture,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'Graphing Calculator',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: TuranColors.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('desmos-calculator-close'),
                            tooltip: 'Close calculator',
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: _kResizeGutter,
                                bottom: _kResizeGutter,
                              ),
                              child: DesmosCalculatorEmbed(
                                ignorePointer: _blockingEmbed,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            width: _kResizeGutter,
                            height: _kResizeGutter,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeDownRight,
                              child: Listener(
                                onPointerDown: (_) {
                                  _beginWindowGesture(_WindowGesture.resize);
                                },
                                child: GestureDetector(
                                  key: const Key('desmos-calculator-resize-handle'),
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: kIsWeb
                                      ? null
                                      : (_) {
                                          _beginWindowGesture(_WindowGesture.resize);
                                        },
                                  onPanUpdate: kIsWeb
                                      ? null
                                      : (details) {
                                          setState(() {
                                            _size = _clampedSize(
                                              Size(
                                                _size.width + details.delta.dx,
                                                _size.height + details.delta.dy,
                                              ),
                                              _parentSize,
                                              _offset,
                                            );
                                          });
                                        },
                                  onPanEnd: kIsWeb ? null : (_) => _endWindowGesture(),
                                  onPanCancel: kIsWeb ? null : _endWindowGesture,
                                  child: const CustomPaint(
                                    painter: _ResizeGripPainter(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResizeGripPainter extends CustomPainter {
  const _ResizeGripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final start = Offset(size.width * 0.28, size.height * 0.72);
    final end = Offset(size.width * 0.72, size.height * 0.28);
    canvas.drawLine(start, end, paint);
    canvas.drawLine(start, start + const Offset(6, 0), paint);
    canvas.drawLine(start, start + const Offset(0, -6), paint);
    canvas.drawLine(end, end + const Offset(-6, 0), paint);
    canvas.drawLine(end, end + const Offset(0, 6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
