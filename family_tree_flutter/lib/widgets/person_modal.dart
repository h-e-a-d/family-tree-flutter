// lib/widgets/person_modal.dart

import 'package:flutter/material.dart';
import '../models/person.dart';
import 'package:lucid_color_picker/lucid_color_picker.dart';

Future<void> showPersonModal({
  required BuildContext context,
  required Person person,
  required List<Person> allPeople,
  required Function(Person) onSave,
}) async {
  final givenNameController = TextEditingController(text: person.givenName);
  final fatherNameController = TextEditingController(text: person.fatherName);
  final surnameController = TextEditingController(text: person.surname);
  final birthNameController = TextEditingController(text: person.birthName);
  final dobController = TextEditingController(text: person.dob);

  String gender = person.gender;
  String? selectedMotherId = person.motherId;
  String? selectedSpouseId = person.spouseId;
  double fontSize = person.fontSize;
  Color circleColor = person.circleColor;
  Color textColor = person.textColor;

  final dropdownItems = allPeople
      .where((p) => p.id != person.id)
      .map(
        (p) => DropdownMenuItem<String>(
          value: p.id,
          child: Text(p.fullName),
        ),
      )
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
                controller: givenNameController,
                decoration: InputDecoration(labelText: 'Given Name'),
              ),
              TextField(
                controller: fatherNameController,
                decoration: InputDecoration(labelText: "Father's Name"),
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
                controller: dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
              ),
              SizedBox(height: 8),
              // Gender
              DropdownButtonFormField<String>(
                value: gender,
                decoration: InputDecoration(labelText: 'Gender'),
                onChanged: (value) => gender = value ?? 'unknown',
                items: ['unknown', 'male', 'female']
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g[0].toUpperCase() + g.substring(1)),
                        ))
                    .toList(),
              ),
              SizedBox(height: 8),
              // Mother selector
              DropdownButtonFormField<String>(
                value: selectedMotherId ?? '',
                decoration: InputDecoration(labelText: 'Mother'),
                onChanged: (value) =>
                    selectedMotherId = (value == '') ? null : value,
                items: [
                  const DropdownMenuItem(value: '', child: Text('None')),
                  ...dropdownItems
                ],
              ),
              SizedBox(height: 8),
              // Spouse selector
              DropdownButtonFormField<String>(
                value: selectedSpouseId ?? '',
                decoration: InputDecoration(labelText: 'Spouse'),
                onChanged: (value) =>
                    selectedSpouseId = (value == '') ? null : value,
                items: [
                  const DropdownMenuItem(value: '', child: Text('None')),
                  ...dropdownItems
                ],
              ),
              SizedBox(height: 16),
              // Font Size Slider
              Row(
                children: [
                  Text('Font Size'),
                  Expanded(
                    child: Slider(
                      min: 8,
                      max: 32,
                      divisions: 12,
                      value: fontSize,
                      label: fontSize.toStringAsFixed(0),
                      onChanged: (val) {
                        fontSize = val;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Lucid color picker for circle color
              Text('Circle Color'),
              SizedBox(
                height: 150,
                child: LucidColorPicker(
                  initialColor: circleColor,
                  onColorChanged: (c) => circleColor = c,
                ),
              ),
              SizedBox(height: 16),
              // Lucid color picker for text color
              Text('Text Color'),
              SizedBox(
                height: 150,
                child: LucidColorPicker(
                  initialColor: textColor,
                  onColorChanged: (c) => textColor = c,
                ),
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
              person.givenName = givenNameController.text.trim();
              person.fatherName = fatherNameController.text.trim();
              person.surname = surnameController.text.trim();
              person.birthName = birthNameController.text.trim();
              person.dob = dobController.text.trim();
              person.gender = gender;
              person.motherId = selectedMotherId;
              person.spouseId = selectedSpouseId;
              person.fontSize = fontSize;
              person.circleColor = circleColor;
              person.textColor = textColor;
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
