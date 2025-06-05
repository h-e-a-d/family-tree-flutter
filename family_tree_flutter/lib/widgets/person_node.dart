// lib/widgets/person_node.dart

import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final bool isSelected;
  final void Function(Person) onUpdate;     // Called when a person’s data changes (e.g. after drag)
  final VoidCallback onSelect;              // Called when tapped/double‐tapped
  final VoidCallback onDragStart;           // Called when the user begins dragging

  const PersonNode({
    Key? key,
    required this.person,
    required this.allPeople,
    required this.isSelected,
    required this.onUpdate,
    required this.onSelect,
    required this.onDragStart,
  }) : super(key: key);

  @override
  State<PersonNode> createState() => _PersonNodeState();
}

class _PersonNodeState extends State<PersonNode> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.person.position;
  }

  @override
  void didUpdateWidget(covariant PersonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent updated the person’s position externally, update local state
    if (widget.person.position != position) {
      position = widget.person.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 40,
      top: position.dy - 40,
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () {
          widget.onSelect();
        },
        onDoubleTap: () async {
          // Open Edit Modal
          await showPersonModal(
            context: context,
            person: widget.person,
            allPeople: widget.allPeople,
            onSave: (updated) {
              widget.onUpdate(updated);
            },
          );
        },
        onPanStart: (details) {
          widget.onDragStart(); // only *once* at drag start
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
            widget.person.position = position;
          });
          // Notify parent that position changed
          widget.onUpdate(widget.person);
        },
        child: CustomPaint(
          size: const Size(80, 80),
          painter: _CirclePainter(
            color: widget.person.circleColor,
            isSelected: widget.isSelected,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.person.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.person.textColor,
                    fontFamily: widget.person.fontFamily,
                    fontSize: widget.person.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.person.dob,
                  style: TextStyle(
                    color: widget.person.textColor.withOpacity(0.7),
                    fontFamily: widget.person.fontFamily,
                    fontSize: widget.person.fontSize - 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  _CirclePainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final fillPaint = Paint()..color = color;
    canvas.drawCircle(center, radius, fillPaint);

    if (isSelected) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.redAccent;
      canvas.drawCircle(center, radius - 2, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CirclePainter old) {
    return old.color != color || old.isSelected != isSelected;
  }
}
