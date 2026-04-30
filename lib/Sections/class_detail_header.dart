// =====================================================================
// class_detail_header.dart  —  part of class_detail library
// Contains: _DetailHeader, _HeaderPill, _LogoMark, _LogoPainter,
//           _BrandPattern, _BrandPatternPainter
// =====================================================================

part of '../Pages/class_detail_page.dart';

class _DetailHeader extends StatelessWidget {
  final UserInfo? user;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onTimetable;
  final VoidCallback onAcademicPlan;
  final String className;

  const _DetailHeader({
    required this.user,
    required this.onBack,
    required this.onLogout,
    required this.onTimetable,
    required this.onAcademicPlan,
    required this.className,
  });

  @override
  Widget build(BuildContext context) => TuranHeader(
    user: user,
    title: className,
    subtitle: 'Class details, sessions, homework, mocks, and students.',
    pageLabel: 'Class Detail',
    onBack: onBack,
    actions: [
      TuranHeaderAction(
        icon: Icons.calendar_view_week_rounded,
        label: 'Timetable',
        onTap: onTimetable,
      ),
      TuranHeaderAction(
        icon: Icons.menu_book_rounded,
        label: 'Academic Plan',
        onTap: onAcademicPlan,
      ),
    ],
  );
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.85), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Logo mark (chevron icon) ─────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  final Color color;
  const _LogoMark({required this.size, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _LogoPainter(color: color),
  );
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.12, h * 0.55)
        ..lineTo(w * 0.50, h * 0.22)
        ..lineTo(w * 0.88, h * 0.55),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.28, h * 0.78)
        ..lineTo(w * 0.50, h * 0.58)
        ..lineTo(w * 0.72, h * 0.78),
      paint,
    );

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.9),
      w * 0.05,
      Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.color != color;
}

// ─── Brand background pattern ─────────────────────────────────────────
class _BrandPattern extends StatelessWidget {
  final Color baseColor;
  final double opacity;
  const _BrandPattern({required this.baseColor, this.opacity = 0.18});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _BrandPatternPainter(color: baseColor, opacity: opacity),
      child: const SizedBox.expand(),
    ),
  );
}

class _BrandPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;
  _BrandPatternPainter({required this.color, required this.opacity});

  void _drawLeaf(
    Canvas c,
    double cx,
    double cy,
    double r,
    double rot,
    Paint p,
  ) {
    c.save();
    c.translate(cx, cy);
    c.rotate(rot);
    c.drawPath(
      Path()
        ..moveTo(0, -r)
        ..cubicTo(r * 0.9, -r * 0.9, r * 0.9, r * 0.4, 0, r)
        ..cubicTo(-r * 0.4, r * 0.4, -r * 0.4, -r * 0.4, 0, -r),
      p,
    );
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color.withOpacity(opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const step = 80.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final seed = ((x ~/ step) * 31 + (y ~/ step) * 17) % 7;
        final ox = (seed % 3) * 8.0, oy = ((seed * 5) % 4) * 7.0;
        _drawLeaf(canvas, x + ox, y + oy, 18, seed * 0.9, fill);
        if (seed % 3 == 0) {
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(x + ox + 24, y + oy + 22),
              radius: 10,
            ),
            0,
            4.5,
            false,
            stroke,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BrandPatternPainter old) =>
      old.color != color || old.opacity != opacity;
}
