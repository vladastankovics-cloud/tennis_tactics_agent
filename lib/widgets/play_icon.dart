import 'package:flutter/material.dart';

class PlayIcon extends StatelessWidget {
  final bool filled;
  final double size;

  const PlayIcon({
    super.key,
    this.filled = false,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PlayIconPainter(
        filled: filled,
        color: filled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color ?? Colors.grey,
      ),
    );
  }
}

class _PlayIconPainter extends CustomPainter {
  final bool filled;
  final Color color;

  _PlayIconPainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double radius = width * 0.45;

    if (filled) {
      // For filled state, fill the tennis ball
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw filled circle
      canvas.drawCircle(Offset(centerX, centerY), radius, fillPaint);

      // Draw curved seam line in white (tennis ball seam)
      final seamPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final path = Path();
      path.moveTo(centerX, centerY - radius);

      // Upper curve (bends right)
      path.quadraticBezierTo(
        centerX + radius * 0.6,
        centerY - radius * 0.5,
        centerX,
        centerY,
      );

      // Lower curve (bends left)
      path.quadraticBezierTo(
        centerX - radius * 0.6,
        centerY + radius * 0.5,
        centerX,
        centerY + radius,
      );

      canvas.drawPath(path, seamPaint);
    } else {
      // For unfilled state, draw stroked outline
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw circle outline
      canvas.drawCircle(Offset(centerX, centerY), radius, strokePaint);

      // Draw curved seam line
      final path = Path();
      path.moveTo(centerX, centerY - radius);

      // Upper curve (bends right)
      path.quadraticBezierTo(
        centerX + radius * 0.6,
        centerY - radius * 0.5,
        centerX,
        centerY,
      );

      // Lower curve (bends left)
      path.quadraticBezierTo(
        centerX - radius * 0.6,
        centerY + radius * 0.5,
        centerX,
        centerY + radius,
      );

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_PlayIconPainter oldDelegate) {
    return oldDelegate.filled != filled || oldDelegate.color != color;
  }
}
