import 'package:flutter/material.dart';
import '../models/person.dart';

///
/// A CustomPainter that draws straight lines (“relations”) between two PersonNodes.
/// We pass their positions, whether it’s a spouse (dashed) or parent-child (solid).
///
class ConnectorLine extends StatelessWidget {
  final Person from;
  final Person to;
  final bool isSpouse; // if true, draw dashed red line; else solid grey

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
      child: Container(),
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
      // Dashed line
      final dashWidth = 8.0;
      final dashSpace = 4.0;
      double distance = (end - start).distance;
      final double dx = (end.dx - start.dx) / distance;
      final double dy = (end.dy - start.dy) / distance;
      double progress = 0;
      while (progress < distance) {
        final x1 = start.dx + dx * progress;
        final y1 = start.dy + dy * progress;
        final x2 = start.dx + dx * (progress + dashWidth);
        final y2 = start.dy + dy * (progress + dashWidth);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        progress += dashWidth + dashSpace;
      }
    } else {
      // Solid line
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
