// lib/widgets/connector_line.dart

import 'package:flutter/material.dart';
import '../models/person.dart';

/// Draws a straight line between two Person nodes:
///  • Solid grey for parent‐child
///  • Dashed red for spouse
///
class ConnectorLine extends StatelessWidget {
  final Person from;
  final Person to;
  final bool isSpouse;

  const ConnectorLine({
    super.key,
    required this.from,
    required this.to,
    this.isSpouse = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConnectorPainter(
        start: from.position,
        end: to.position,
        isSpouse: isSpouse,
      ),
      size: Size.infinite,
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final bool isSpouse;

  _ConnectorPainter({
    required this.start,
    required this.end,
    required this.isSpouse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSpouse ? Colors.redAccent : Colors.grey.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isSpouse) {
      // Draw a dashed line between start and end
      final totalDist = (end - start).distance;
      if (totalDist == 0) return;
      final dx = (end.dx - start.dx) / totalDist;
      final dy = (end.dy - start.dy) / totalDist;
      double progress = 0;
      const dashWidth = 8.0;
      const dashSpace = 4.0;
      while (progress < totalDist) {
        final x1 = start.dx + dx * progress;
        final y1 = start.dy + dy * progress;
        final x2 = start.dx + dx * (progress + dashWidth);
        final y2 = start.dy + dy * (progress + dashWidth);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        progress += dashWidth + dashSpace;
      }
    } else {
      // Solid line for parent‐child
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) {
    return old.start != start ||
        old.end != end ||
        old.isSpouse != isSpouse;
  }
}
