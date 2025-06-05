import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import '../models/person.dart';
import 'person_modal.dart';

///
/// Each Person is rendered as a draggable circle with text on top.
/// - Double‐tap opens the PersonModal
/// - Single‐tap selects/unselects
/// - Drag moves it around
///
class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final Function(Person) onUpdate;
  final Function(String?) onSelect; // callback to notify parent which person is selected (or null)

  const PersonNode({
    super.key,
    required this.person,
    required this.allPeople,
    required this.onUpdate,
    required this.onSelect,
  });

  @override
  State<PersonNode> createState() => _PersonNodeState();
}

class _PersonNodeState extends State<PersonNode> {
  late Offset position;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    position = widget.person.position;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - widget.person.circleSize / 2,
      top: position.dy - widget.person.circleSize / 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isSelected = !_isSelected;
            widget.onSelect(_isSelected ? widget.person.id : null);
          });
        },
        onDoubleTap: () async {
          await showPersonModal(
            context: context,
            person: widget.person,
            allPeople: widget.allPeople,
            onSave: (edited) {
              widget.onUpdate(edited);
            },
          );
          if (mounted) setState(() {});
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
              width: widget.person.circleSize,
              height: widget.person.circleSize,
              decoration: BoxDecoration(
                color: widget.person.circleColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSelected ? Colors.redAccent : Colors.black26,
                  width: _isSelected ? 3 : 1,
                ),
              ),
            ),

            // Name text
            Text(
              widget.person.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.person.fontSize,
                color: widget.person.fontColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            // DOB below name (slightly offset)
            Positioned(
              top: widget.person.fontSize + 8,
              child: Text(
                widget.person.dob,
                style: TextStyle(
                  fontSize: (widget.person.fontSize * 0.8).clamp(8.0, widget.person.fontSize),
                  color: widget.person.fontColor.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
