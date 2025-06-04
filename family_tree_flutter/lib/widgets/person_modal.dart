import 'package:flutter/material.dart';
import '../models/person.dart';

Future<void> showPersonModal({
  required BuildContext context,
  required Person person,
  required Function(Person) onSave,
}) async {
  final nameController = TextEditingController(text: person.name);
  final dobController = TextEditingController(text: person.dob);
  String selectedGender = person.gender;

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
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
              ),
              DropdownButtonFormField<String>(
                value: selectedGender,
                onChanged: (value) => selectedGender = value ?? 'unknown',
                items: ['unknown', 'male', 'female']
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g),
                        ))
                    .toList(),
                decoration: InputDecoration(labelText: 'Gender'),
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
              person.dob = dobController.text.trim();
              person.gender = selectedGender;
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
