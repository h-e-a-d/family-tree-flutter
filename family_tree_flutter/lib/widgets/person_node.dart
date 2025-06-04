import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final Function(Person) onUpdate;

  const PersonNode({
    Key? key,
    required this.person,
    required this.allPeople,
    required this.onUpdate,
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
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onDoubleTap: () async {
          await showPersonModal(
            context: context,
            person: widget.person,
            allPeople: widget.allPeople,
            onSave: widget.onUpdate,
          );
          setState(() {});
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
            widget.person.position = position;
            widget.onUpdate(widget.person);
          });
        },
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.person.fullName, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.person.dob),
                Text(widget.person.gender),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
