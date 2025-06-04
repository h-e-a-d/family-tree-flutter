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
                value: selectedMotherId,
                decoration: InputDecoration(labelText: 'Mother'),
                onChanged: (value) => selectedMotherId = value,
                items: [DropdownMenuItem(value: null, child: Text('None'))] +
                    dropdownItems,
              ),
              DropdownButtonFormField<String>(
                value: selectedFatherId,
                decoration: InputDecoration(labelText: 'Father'),
                onChanged: (value) => selectedFatherId = value,
                items: [DropdownMenuItem(value: null, child: Text('None'))] +
                    dropdownItems,
              ),
              DropdownButtonFormField<String>(
                value: selectedSpouseId,
                decoration: InputDecoration(labelText: 'Spouse'),
                onChanged: (value) => selectedSpouseId = value,
                items: [DropdownMenuItem(value: null, child: Text('None'))] +
                    dropdownItems,
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
