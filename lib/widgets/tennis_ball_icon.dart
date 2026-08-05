import 'package:flutter/material.dart';

class TennisBallIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const TennisBallIcon({
    super.key,
    this.size = 16.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TennisBallIconPainter(
        color: color ?? Theme.of(context).iconTheme.color ?? Colors.grey,
      ),
    );
  }
}

class _TennisBallIconPainter extends CustomPainter {
  final Color color;

  // Tennis ball colors
  static const Color ballGreen = Color(0xFFB9D613);
  static const Color seamWhite = Color(0xFFF7F7F7);

  _TennisBallIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Draw filled tennis ball (lime green)
    final ballPaint = Paint()
      ..color = ballGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ballPaint);

    // Draw outline
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04;
    canvas.drawCircle(center, radius, outlinePaint);

    // Draw the curved white seams (tennis ball characteristic pattern)
    final seamPaint = Paint()
      ..color = seamWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    // Upper-left curved seam
    final upperSeam = Path();
    upperSeam.moveTo(radius * 0.35, radius * 0.15);
    upperSeam.cubicTo(
      radius * 0.1, radius * 0.6,    // control point 1
      radius * 0.6, radius * 1.1,    // control point 2
      radius * 0.15, radius * 1.35,  // end point
    );
    canvas.drawPath(upperSeam, seamPaint);

    // Lower-right curved seam (mirror)
    final lowerSeam = Path();
    lowerSeam.moveTo(radius * 1.65, radius * 0.65);
    lowerSeam.cubicTo(
      radius * 1.4, radius * 1.1,    // control point 1
      radius * 1.9, radius * 1.4,    // control point 2
      radius * 1.85, radius * 1.85,  // end point
    );
    canvas.drawPath(lowerSeam, seamPaint);

    // Clip the seams to the ball circle
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);
    canvas.drawPath(upperSeam, seamPaint);
    canvas.drawPath(lowerSeam, seamPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TennisBallIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
