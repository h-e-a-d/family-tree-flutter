// lib/widgets/person_node.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final bool isSelected;
  final Function(Person) onUpdate;
  final Function(Person) onSelect;

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

  @override
  void initState() {
    super.initState();
    position = widget.person.position;
  }

  @override
  void didUpdateWidget(covariant PersonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external code updated position, reflect it:
    position = widget.person.position;
  }

  @override
  Widget build(BuildContext context) {
    // Circle radius
    const double radius = 30;

    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      child: GestureDetector(
        onTap: () {
          widget.onSelect(widget.person);
        },
        onDoubleTap: () async {
          // Open modal to edit this person
          await showPersonModal(
            context: context,
            person: widget.person,
            allPeople: widget.allPeople,
            onSave: (updated) {
              widget.onUpdate(updated);
            },
          );
          setState(() {}); // redraw text if name/dob changed
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
            widget.person.position = position;
            widget.onUpdate(widget.person);
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circle
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: widget.person.circleColor,
                shape: BoxShape.circle,
                border: widget.isSelected
                    ? Border.all(color: Colors.red.shade700, width: 3)
                    : null,
              ),
            ),
            // Name and DOB
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.person.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: widget.person.fontFamily,
                    fontSize: widget.person.fontSize,
                    color: widget.person.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.person.dob,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: widget.person.fontFamily,
                    fontSize: max(8, widget.person.fontSize - 2),
                    color: widget.person.textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
