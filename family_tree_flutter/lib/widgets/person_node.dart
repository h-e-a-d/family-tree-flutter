import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final Function(Person) onUpdate;

  const PersonNode({
    required this.person,
    required this.onUpdate,
  });

  @override
  _PersonNodeState createState() => _PersonNodeState();
}

class _PersonNodeState extends State<PersonNode> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.person.position;
  }

  void _onDrag(DragUpdateDetails details) {
    setState(() {
      position += details.delta;
    });
    widget.onUpdate(widget.person..position = position);
  }

  void _editPerson() async {
    await showPersonModal(
      context: context,
      person: widget.person,
      onSave: widget.onUpdate,
    );
    setState(() {}); // Refresh display after edit
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: _onDrag,
        onDoubleTap: _editPerson,
        onTap: () => print('Tapped ${widget.person.name}'),
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(
                widget.person.name.isNotEmpty ? widget.person.name[0] : '?',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Text(widget.person.name),
            if (widget.person.dob.isNotEmpty)
              Text(widget.person.dob, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
