import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders the official Express Services brand logo icon:
/// - Red crescent shadow (#E11D48 / #FF1E27)
/// - Deep Navy main circle (#0D2149)
/// - Monogram White "E" calligraphy
class ExpressLogoIcon extends StatelessWidget {
  final double size;

  const ExpressLogoIcon({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ExpressLogoPainter(),
    );
  }
}

class _ExpressLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;

    // 1. Red crescent shadow on the left
    final redPaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(54 * scale, 60 * scale), 44 * scale, redPaint);

    // 2. Main Deep Navy circle
    final navyPaint = Paint()
      ..color = const Color(0xFF0D2149)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(62 * scale, 60 * scale), 44 * scale, navyPaint);

    // 3. Cursive White "E" Calligraphy Monogram
    final path = Path()
      ..moveTo(75 * scale, 38 * scale)
      ..cubicTo(72 * scale, 30 * scale, 64 * scale, 30 * scale, 58 * scale, 33 * scale)
      ..cubicTo(52 * scale, 36 * scale, 48 * scale, 44 * scale, 50 * scale, 48 * scale)
      ..cubicTo(52 * scale, 52 * scale, 58 * scale, 52 * scale, 62 * scale, 48 * scale)
      ..cubicTo(66 * scale, 44 * scale, 64 * scale, 42 * scale, 60 * scale, 44 * scale)
      ..cubicTo(56 * scale, 46 * scale, 50 * scale, 50 * scale, 48 * scale, 56 * scale)
      ..cubicTo(46 * scale, 62 * scale, 48 * scale, 72 * scale, 56 * scale, 76 * scale)
      ..cubicTo(64 * scale, 80 * scale, 72 * scale, 74 * scale, 74 * scale, 66 * scale);

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full Logo Header widget including Icon + Authentic Brand Typography ("EXPRESS SERVICES")
/// Seamlessly transparent on any background (dark navy, white, or light grey).
class ExpressLogoHeader extends StatelessWidget {
  final double iconSize;
  final bool isDarkBackground;

  const ExpressLogoHeader({
    super.key,
    this.iconSize = 48,
    this.isDarkBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final xpressColor = isDarkBackground ? Colors.white : AppColors.navy;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExpressLogoIcon(size: iconSize),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Red "E" + "XPRESS" (white on dark, navy on light)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'E',
                    style: TextStyle(
                      color: const Color(0xFFE11D48), // Brand Red
                      fontSize: iconSize * 0.48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  TextSpan(
                    text: 'XPRESS',
                    style: TextStyle(
                      color: xpressColor,
                      fontSize: iconSize * 0.44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Row: "S E R V I C E S" in bright Red
            Text(
              'SERVICES',
              style: TextStyle(
                color: const Color(0xFFE11D48), // Brand Red
                fontSize: iconSize * 0.25,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
