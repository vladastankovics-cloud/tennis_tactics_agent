import 'package:flutter/material.dart';

class CourtIcon extends StatelessWidget {
  final bool filled;
  final double size;

  const CourtIcon({
    super.key,
    this.filled = false,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CourtIconPainter(
        filled: filled,
        color: filled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color ?? Colors.grey,
      ),
    );
  }
}

class _CourtIconPainter extends CustomPainter {
  final bool filled;
  final Color color;

  _CourtIconPainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double halfHeight = height / 2;
    final double halfWidth = width / 2;

    if (filled) {
      // For filled state, just fill with solid color (no lines)
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        fillPaint,
      );
    } else {
      // For unfilled state, draw stroked outline
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Outer rectangle
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        strokePaint,
      );

      // Horizontal line separating upper and lower sections
      canvas.drawLine(
        Offset(0, halfHeight),
        Offset(width, halfHeight),
        strokePaint,
      );

      // Vertical line in the middle of bottom half
      canvas.drawLine(
        Offset(halfWidth, halfHeight),
        Offset(halfWidth, height),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CourtIconPainter oldDelegate) {
    return oldDelegate.filled != filled || oldDelegate.color != color;
  }
}
