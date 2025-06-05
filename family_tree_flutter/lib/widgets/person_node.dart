import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final Function(Person) onUpdate;
  final bool isSelected;

  /// Global font settings:
  final String fontFamily;
  final double fontSize;
  final Color nameColor;
  final Color dateColor;

  const PersonNode({
    Key? key,
    required this.person,
    required this.allPeople,
    required this.onUpdate,
    required this.isSelected,
    required this.fontFamily,
    required this.fontSize,
    required this.nameColor,
    required this.dateColor,
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
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 30, // adjust so that the center is in correct spot
      top: position.dy - 30,
      child: GestureDetector(
        onTap: () {
          // Notify parent that this person is now selected
          widget.onUpdate(widget.person);
        },
        onDoubleTap: () async {
          // Open modal to edit
          await showPersonModal(
            context: context,
            person: widget.person,
            allPeople: widget.allPeople,
            onSave: (p) {
              widget.onUpdate(p);
            },
          );
          setState(() {}); // redraw
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
            // The circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade200,
                border: Border.all(
                  color: widget.isSelected ? Colors.red : Colors.black54,
                  width: widget.isSelected ? 3 : 1,
                ),
              ),
            ),
            // The text inside the circle
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.person.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: widget.fontFamily,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    color: widget.nameColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.person.dob,
                  style: TextStyle(
                    fontFamily: widget.fontFamily,
                    fontSize: (widget.fontSize - 2).clamp(6.0, widget.fontSize),
                    color: widget.dateColor,
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
