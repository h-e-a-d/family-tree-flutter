// main.dart
import 'package:flutter/material.dart';
import 'views/home_view.dart';

void main() {
  runApp(FamilyTreeApp());
}

class FamilyTreeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Tree Builder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeView(),
    );
  }
}

// models/person.dart
import 'package:flutter/material.dart';

class Person {
  final String id;
  String name;
  String surname;
  String birthName;
  String fatherName;
  String dob;
  String gender;
  Offset position;
  String? motherId;
  String? fatherId;
  String? spouseId;

  Person({
    required this.id,
    required this.name,
    required this.surname,
    required this.birthName,
    required this.fatherName,
    required this.dob,
    required this.gender,
    required this.position,
    this.motherId,
    this.fatherId,
    this.spouseId,
  });

  String get fullName => '$name $surname';
}

// widgets/person_node.dart
import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final Function(Person) onUpdate;

  const PersonNode({
    required this.person,
    required this.allPeople,
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
      allPeople: widget.allPeople,
      onSave: widget.onUpdate,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: _onDrag,
        onDoubleTap: _editPerson,
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
            Text(widget.person.fullName),
            if (widget.person.dob.isNotEmpty)
              Text(widget.person.dob, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// widgets/person_modal.dart
import 'package:flutter/material.dart';
import '../models/person.dart';

Future<void> showPersonModal({
  required BuildContext context,
  required Person person,
  required List<Person> allPeople,
  required Function(Person) onSave,
}) async {
  final nameController = TextEditingController(text: person.name);
  final surnameController = TextEditingController(text: person.surname);
  final birthNameController = TextEditingController(text: person.birthName);
  final fatherNameController = TextEditingController(text: person.fatherName);
  final dobController = TextEditingController(text: person.dob);

  String gender = person.gender;
  String? selectedMotherId = person.motherId;
  String? selectedFatherId = person.fatherId;
  String? selectedSpouseId = person.spouseId;

  final dropdownItems = allPeople
      .where((p) => p.id != person.id)
      .map((p) => DropdownMenuItem<String>(
            value: p.id,
            child: Text(p.fullName),
          ))
      .toList();

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Edit Person'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: surnameController,
                decoration: InputDecoration(labelText: 'Surname'),
              ),
              TextField(
                controller: birthNameController,
                decoration: InputDecoration(labelText: 'Birth Name'),
              ),
              TextField(
                controller: fatherNameController,
                decoration: InputDecoration(labelText: "Father's Name"),
              ),
              TextField(
                controller: dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
              ),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: InputDecoration(labelText: 'Gender'),
                onChanged: (value) => gender = value ?? 'unknown',
                items: ['unknown', 'male', 'female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
              ),
              DropdownButtonFormField<String>(
                value: selectedMotherId ?? '',
                decoration: InputDecoration(labelText: 'Mother'),
                onChanged: (value) => selectedMotherId = (value == '') ? null : value,
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('None')),
                  ...dropdownItems
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedFatherId ?? '',
                decoration: InputDecoration(labelText: 'Father'),
                onChanged: (value) => selectedFatherId = (value == '') ? null : value,
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('None')),
                  ...dropdownItems
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedSpouseId ?? '',
                decoration: InputDecoration(labelText: 'Spouse'),
                onChanged: (value) => selectedSpouseId = (value == '') ? null : value,
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('None')),
                  ...dropdownItems
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              person.name = nameController.text.trim();
              person.surname = surnameController.text.trim();
              person.birthName = birthNameController.text.trim();
              person.fatherName = fatherNameController.text.trim();
              person.dob = dobController.text.trim();
              person.gender = gender;
              person.motherId = selectedMotherId;
              person.fatherId = selectedFatherId;
              person.spouseId = selectedSpouseId;
              onSave(person);
              Navigator.of(ctx).pop();
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}