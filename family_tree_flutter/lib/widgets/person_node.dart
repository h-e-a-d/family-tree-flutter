// lib/widgets/person_node.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final Function(Person) onUpdate;
  final Function(Person) onSelect;
  final bool isSelected;

  const PersonNode({
    Key? key,
    required this.person,
    required this.allPeople,
    required this.onUpdate,
    required this.onSelect,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<PersonNode> createState() => _PersonNodeState();
}

class _PersonNodeState extends State<PersonNode> {
  late Offset position;
  late double lastScale;
  late double currentScale;

  @override
  void initState() {
    super.initState();
    position = widget.person.position;
    lastScale = 1.0;
    currentScale = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - widget.person.circleRadius,
      top: position.dy - widget.person.circleRadius,
      child: GestureDetector(
        onTap: () {
          widget.onSelect(widget.person);
        },
        onDoubleTap: () async {
          await showPersonModal(
            context: context,
            person: widget.person,
            allPeople: widget.allPeople,
            onSave: widget.onUpdate,
          );
          setState(() {}); // Refresh after editing
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
            widget.person.position = position;
            widget.onUpdate(widget.person);
          });
        },
        onScaleStart: (details) {
          lastScale = 1.0;
        },
        onScaleUpdate: (details) {
          // pinch-to-resize circle
          final scaleDelta = details.scale / lastScale;
          lastScale = details.scale;
          setState(() {
            widget.person.circleRadius =
                (widget.person.circleRadius * scaleDelta).clamp(20.0, 100.0);
            widget.onUpdate(widget.person);
          });
        },
        child: Stack(
          children: [
            // Circle
            Container(
              width: widget.person.circleRadius * 2,
              height: widget.person.circleRadius * 2,
              decoration: BoxDecoration(
                color: widget.person.circleColor,
                shape: BoxShape.circle,
                border: widget.isSelected
                    ? Border.all(color: Colors.redAccent, width: 3)
                    : null,
              ),
            ),
            // Name and DOB
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.person.fullName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.person.fontSize,
                        color: widget.person.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.person.dob,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:
                            math.max(8, widget.person.fontSize - 2),
                        color: widget.person.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
