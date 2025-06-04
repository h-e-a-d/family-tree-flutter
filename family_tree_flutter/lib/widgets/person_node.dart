import 'package:flutter/material.dart';
import '../models/person.dart';

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

  void _onDrag(details) {
    setState(() {
      position += details.delta;
    });
    widget.onUpdate(widget.person..position = position);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: _onDrag,
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(widget.person.name[0]),
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
