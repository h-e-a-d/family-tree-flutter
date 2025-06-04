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
        title: const Text('Edit Person'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: surnameController,
                decoration: const InputDecoration(labelText: 'Surname'),
              ),
              TextField(
                controller: birthNameController,
                decoration: const InputDecoration(labelText: 'Birth Name'),
              ),
              TextField(
                controller: fatherNameController,
                decoration: const InputDecoration(labelText: "Father's Name"),
              ),
              TextField(
                controller: dobController,
                decoration: const InputDecoration(labelText: 'Date of Birth'),
              ),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                onChanged: (value) => gender = value ?? 'unknown',
                items: ['unknown', 'male', 'female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
              ),
              DropdownButtonFormField<String>(
                value: selectedMotherId ?? '',
                decoration: const InputDecoration(labelText: 'Mother'),
                onChanged: (value) => selectedMotherId = (value == '') ? null : value,
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('None')),
                  ...dropdownItems
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedFatherId ?? '',
                decoration: const InputDecoration(labelText: 'Father'),
                onChanged: (value) => selectedFatherId = (value == '') ? null : value,
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('None')),
                  ...dropdownItems
                ],
              ),
              DropdownButtonFormField<String>(
                value: selectedSpouseId ?? '',
                decoration: const InputDecoration(labelText: 'Spouse'),
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
            child: const Text('Cancel'),
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
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
