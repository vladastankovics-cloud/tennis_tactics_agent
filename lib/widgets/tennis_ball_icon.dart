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

  _TennisBallIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Draw outer circle
    canvas.drawCircle(center, radius, paint);

    // Draw curved seam line (S-shaped curve)
    final path = Path();

    // Start from top
    path.moveTo(radius, 0);

    // Upper curve (bends right)
    path.quadraticBezierTo(
      radius + radius * 0.6, // control point x
      radius * 0.5,           // control point y
      radius,                 // end point x
      radius,                 // end point y (middle)
    );

    // Lower curve (bends left)
    path.quadraticBezierTo(
      radius - radius * 0.6, // control point x
      radius * 1.5,          // control point y
      radius,                // end point x
      size.height,           // end point y (bottom)
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TennisBallIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
