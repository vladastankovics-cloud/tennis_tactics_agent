import 'package:flutter/material.dart';

class PlanIcon extends StatelessWidget {
  final bool filled;
  final double size;

  const PlanIcon({
    super.key,
    this.filled = false,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PlanIconPainter(
        filled: filled,
        color: filled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color ?? Colors.grey,
      ),
    );
  }
}

class _PlanIconPainter extends CustomPainter {
  final bool filled;
  final Color color;

  _PlanIconPainter({required this.filled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    if (filled) {
      // For filled state, fill the entire area
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw rounded rectangle background
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          Radius.circular(width * 0.1),
        ),
        fillPaint,
      );

      // Draw calendar lines in white
      final linePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Top bar (header)
      canvas.drawLine(
        Offset(0, height * 0.25),
        Offset(width, height * 0.25),
        linePaint,
      );

      // Vertical lines for calendar grid
      final columnWidth = width / 3;
      for (int i = 1; i < 3; i++) {
        canvas.drawLine(
          Offset(columnWidth * i, height * 0.25),
          Offset(columnWidth * i, height),
          linePaint,
        );
      }

      // Horizontal lines for calendar grid
      final rowHeight = (height - height * 0.25) / 3;
      for (int i = 1; i < 3; i++) {
        canvas.drawLine(
          Offset(0, height * 0.25 + rowHeight * i),
          Offset(width, height * 0.25 + rowHeight * i),
          linePaint,
        );
      }
    } else {
      // For unfilled state, draw stroked outline
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw rounded rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          Radius.circular(width * 0.1),
        ),
        strokePaint,
      );

      // Top bar (header)
      canvas.drawLine(
        Offset(0, height * 0.25),
        Offset(width, height * 0.25),
        strokePaint,
      );

      // Vertical lines for calendar grid
      final columnWidth = width / 3;
      for (int i = 1; i < 3; i++) {
        canvas.drawLine(
          Offset(columnWidth * i, height * 0.25),
          Offset(columnWidth * i, height),
          strokePaint,
        );
      }

      // Horizontal lines for calendar grid
      final rowHeight = (height - height * 0.25) / 3;
      for (int i = 1; i < 3; i++) {
        canvas.drawLine(
          Offset(0, height * 0.25 + rowHeight * i),
          Offset(width, height * 0.25 + rowHeight * i),
          strokePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PlanIconPainter oldDelegate) {
    return oldDelegate.filled != filled || oldDelegate.color != color;
  }
}
