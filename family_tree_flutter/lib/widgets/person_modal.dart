// lib/widgets/person_modal.dart
import 'package:flutter/material.dart';
import '../models/person.dart';

Future<void> showPersonModal({
  required BuildContext context,
  required Person person,
  required List<Person> allPeople,
  required Function(Person) onSave,
}) async {
  // Clone the person so we can discard changes on cancel
  final temp = Person(
    id: person.id,
    name: person.name,
    surname: person.surname,
    birthName: person.birthName,
    fatherName: person.fatherName,
    dob: person.dob,
    gender: person.gender,
    motherId: person.motherId,
    fatherId: person.fatherId,
    spouseId: person.spouseId,
    position: person.position,
    circleColor: person.circleColor,
    textColor: person.textColor,
    fontFamily: person.fontFamily,
    fontSize: person.fontSize,
  );

  final nameController = TextEditingController(text: temp.name);
  final surnameController = TextEditingController(text: temp.surname);
  final birthNameController = TextEditingController(text: temp.birthName);
  final fatherNameController = TextEditingController(text: temp.fatherName);
  final dobController = TextEditingController(text: temp.dob);

  String gender = temp.gender;
  String? selectedMotherId = temp.motherId;
  String? selectedFatherId = temp.fatherId;
  String? selectedSpouseId = temp.spouseId;

  // Preset color palette:
  final List<Color> presetCircleColors = [
    Colors.blue.shade200,
    Colors.green.shade200,
    Colors.orange.shade200,
    Colors.purple.shade200,
    Colors.brown.shade200,
    Colors.teal.shade200,
    Colors.red.shade200,
  ];
  final List<Color> presetTextColors = [
    Colors.black,
    Colors.white,
    Colors.blueGrey,
    Colors.deepPurple,
    Colors.teal.shade900,
  ];

  final List<String> presetFonts = [
    'Arial',
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Merriweather',
    'PT Serif',
    'Poppins',
    'Fira Code',
  ];

  String chosenCircleColorValue = temp.circleColor.value.toRadixString(16);
  String chosenTextColorValue = temp.textColor.value.toRadixString(16);
  String chosenFont = temp.fontFamily;
  double chosenFontSize = temp.fontSize;

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Edit Person: ${temp.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name / Surname / BirthName / FatherName / DOB
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
                decoration:
                    const InputDecoration(labelText: "Father's Name"),
              ),
              TextField(
                controller: dobController,
                decoration:
                    const InputDecoration(labelText: 'Date of Birth'),
              ),
              const SizedBox(height: 12),

              // Gender
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gender'),
                value: gender.isEmpty ? null : gender,
                items: ['unknown', 'male', 'female']
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(capitalize(g))))
                    .toList(),
                onChanged: (val) {
                  gender = val ?? 'unknown';
                },
              ),
              const SizedBox(height: 12),

              // Mother / Father / Spouse selectors
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Mother'),
                value: selectedMotherId ?? '',
                items: [
                  const DropdownMenuItem<String>(
                      value: '', child: Text('None')),
                  ...allPeople
                      .where((p) => p.id != temp.id && p.gender == 'female')
                      .map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.fullName))),
                ],
                onChanged: (val) {
                  selectedMotherId = (val == '' ? null : val);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Father'),
                value: selectedFatherId ?? '',
                items: [
                  const DropdownMenuItem<String>(
                      value: '', child: Text('None')),
                  ...allPeople
                      .where((p) => p.id != temp.id && p.gender == 'male')
                      .map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.fullName))),
                ],
                onChanged: (val) {
                  selectedFatherId = (val == '' ? null : val);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Spouse'),
                value: selectedSpouseId ?? '',
                items: [
                  const DropdownMenuItem<String>(
                      value: '', child: Text('None')),
                  ...allPeople
                      .where((p) => p.id != temp.id)
                      .map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.fullName))),
                ],
                onChanged: (val) {
                  selectedSpouseId = (val == '' ? null : val);
                },
              ),
              const SizedBox(height: 16),

              // Circle Color Picker
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Circle Color:',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Wrap(
                spacing: 8,
                children: presetCircleColors.map((c) {
                  return GestureDetector(
                    onTap: () {
                      chosenCircleColorValue = c.value.toRadixString(16);
                      temp.circleColor = c;
                      setStateInDialog(ctx);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: (temp.circleColor.value == c.value)
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Text Color Picker
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Text Color:',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Wrap(
                spacing: 8,
                children: presetTextColors.map((c) {
                  return GestureDetector(
                    onTap: () {
                      chosenTextColorValue = c.value.toRadixString(16);
                      temp.textColor = c;
                      setStateInDialog(ctx);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: (temp.textColor.value == c.value)
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Font Picker
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Font Family'),
                value: chosenFont,
                items: presetFonts
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, style: TextStyle(fontFamily: f)),
                        ))
                    .toList(),
                onChanged: (val) {
                  chosenFont = val ?? chosenFont;
                  temp.fontFamily = chosenFont;
                  setStateInDialog(ctx);
                },
              ),
              const SizedBox(height: 12),

              // Font Size field
              TextFormField(
                initialValue: chosenFontSize.toStringAsFixed(0),
                decoration: const InputDecoration(
                    labelText: 'Font Size (e.g. 12, 16, 24)'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final d = double.tryParse(val);
                  if (d != null && d >= 6 && d <= 72) {
                    chosenFontSize = d;
                    temp.fontSize = d;
                    setStateInDialog(ctx);
                  }
                },
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
              // Copy temp back to original person
              person.name = nameController.text.trim();
              person.surname = surnameController.text.trim();
              person.birthName = birthNameController.text.trim();
              person.fatherName = fatherNameController.text.trim();
              person.dob = dobController.text.trim();
              person.gender = gender;
              person.motherId = selectedMotherId;
              person.fatherId = selectedFatherId;
              person.spouseId = selectedSpouseId;
              person.circleColor = temp.circleColor;
              person.textColor = temp.textColor;
              person.fontFamily = temp.fontFamily;
              person.fontSize = temp.fontSize;
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

// Helper to force a rebuild of the AlertDialog
void setStateInDialog(BuildContext context) {
  (context as Element).markNeedsBuild();
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
