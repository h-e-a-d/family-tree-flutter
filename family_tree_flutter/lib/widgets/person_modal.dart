// lib/widgets/person_modal.dart

import 'package:flutter/material.dart';
import '../models/person.dart';

/// Displays a modal dialog for adding or editing a [Person].
///
/// - If [person.id] is empty (""), we treat it as a new Person and assign
///   a UUID upon saving.
/// - [allPeople] is the list of existing Person objects, used to populate
///   the Mother/Father/Spouse dropdowns.
/// - On Save, we call [onSave] with the edited Person.
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

  // Build a list of dropdown items for every other person
  final dropdownItems = allPeople
      .where((p) => p.id != person.id)
      .map((p) => DropdownMenuItem<String?>(
            value: p.id,
            child: Text(p.fullName),
          ))
      .toList();

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(person.id.isEmpty ? 'Add Person' : 'Edit Person'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Given Name
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Given Name'),
              ),

              SizedBox(height: 12),

              // Surname
              TextField(
                controller: surnameController,
                decoration: InputDecoration(labelText: 'Surname'),
              ),

              SizedBox(height: 12),

              // Birth Name
              TextField(
                controller: birthNameController,
                decoration: InputDecoration(labelText: 'Birth Name'),
              ),

              SizedBox(height: 12),

              // Father's Name (free‐text, not the same as “Father” dropdown)
              TextField(
                controller: fatherNameController,
                decoration: InputDecoration(labelText: "Father’s Name"),
              ),

              SizedBox(height: 12),

              // Date of Birth
              TextField(
                controller: dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'dd.mm.yyyy or yyyy',
                ),
                maxLength: 10,
              ),
              SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter full date (dd.mm.yyyy) or just year (yyyy)',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Gender dropdown (allows null so we can show "Select Gender")
              DropdownButtonFormField<String?>(
                value: gender.isEmpty ? null : gender,
                decoration: InputDecoration(labelText: 'Gender'),
                items: <String?>[null, 'male', 'female']
                    .map((g) => DropdownMenuItem<String?>(
                          value: g,
                          child: Text(
                            g == null
                                ? 'Select Gender'
                                : (g[0].toUpperCase() + g.substring(1)),
                          ),
                        ))
                    .toList(),
                onChanged: (value) => gender = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a gender';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Mother dropdown
              DropdownButtonFormField<String?>(
                value: selectedMotherId,
                decoration: InputDecoration(labelText: 'Mother'),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...dropdownItems,
                ],
                onChanged: (value) => selectedMotherId = value,
              ),

              SizedBox(height: 16),

              // Father dropdown
              DropdownButtonFormField<String?>(
                value: selectedFatherId,
                decoration: InputDecoration(labelText: 'Father'),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...dropdownItems,
                ],
                onChanged: (value) => selectedFatherId = value,
              ),

              SizedBox(height: 16),

              // Spouse dropdown
              DropdownButtonFormField<String?>(
                value: selectedSpouseId,
                decoration: InputDecoration(labelText: 'Spouse'),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...dropdownItems,
                ],
                onChanged: (value) => selectedSpouseId = value,
              ),
            ],
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),

          // Save button
          ElevatedButton(
            onPressed: () {
              // Basic validation: require Given Name and Gender
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Given Name cannot be empty')),
                );
                return;
              }
              if (gender.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a gender')),
                );
                return;
              }

              // Commit changes back to the Person object
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
