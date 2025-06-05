// lib/widgets/person_node.dart

import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

/// A single draggable/selectable circle + text for one Person.
///  • Tap to select/deselect
///  • Double‐tap to edit (opens the PersonModal)
///  • Drag to move, updating the Person’s position
///
class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final void Function(Person) onUpdate;
  final void Function(String?) onSelect;

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

            // Name (centered)
            Text(
              widget.person.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.person.fontSize,
                color: widget.person.fontColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            // DOB below the name (small offset)
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
