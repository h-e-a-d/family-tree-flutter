import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';

///
/// A full “Add/Edit Person” modal.  This takes in a Person object (either an empty
/// “new” Person, or an existing Person to edit), plus the full list of allPeople
/// so that parent/spouse dropdowns can be populated.  When “Save” is tapped, it
/// calls `onSave(...)` with the updated Person.
///
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
  double fontSize = person.fontSize;
  Color fontColor = person.fontColor;
  Color circleColor = person.circleColor;
  double circleSize = person.circleSize;

  final uuid = Uuid();

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(person.id.isEmpty ? 'Add Person' : 'Edit Person'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Given Name
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Given Name'),
              ),

              // Surname
              TextField(
                controller: surnameController,
                decoration: InputDecoration(labelText: 'Surname'),
              ),

              // Birth Name
              TextField(
                controller: birthNameController,
                decoration: InputDecoration(labelText: 'Birth Name'),
              ),

              // Father’s Name (string field—it’s just text, not the relation dropdown)
              TextField(
                controller: fatherNameController,
                decoration: InputDecoration(labelText: "Father's Name (text)"),
              ),

              // Date of Birth
              TextField(
                controller: dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
              ),

              // Gender dropdown
              DropdownButtonFormField<String>(
                value: gender.isEmpty ? null : gender,
                decoration: InputDecoration(labelText: 'Gender'),
                onChanged: (v) {
                  gender = v ?? '';
                },
                items: <String>['', 'male', 'female']
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g.isEmpty ? 'None' : g)))
                    .toList(),
              ),

              SizedBox(height: 12),

              // Parent / Spouse dropdowns
              _RelationDropdown(
                label: 'Mother',
                allPeople: allPeople,
                currentId: selectedMotherId,
                onChanged: (v) => selectedMotherId = v,
                filterGender: 'female',
              ),

              _RelationDropdown(
                label: 'Father',
                allPeople: allPeople,
                currentId: selectedFatherId,
                onChanged: (v) => selectedFatherId = v,
                filterGender: 'male',
              ),

              _RelationDropdown(
                label: 'Spouse',
                allPeople: allPeople,
                currentId: selectedSpouseId,
                onChanged: (v) => selectedSpouseId = v,
                filterGender: 'all',
              ),

              SizedBox(height: 12),

              // Circle size slider
              Row(
                children: [
                  Text('Circle Size'),
                  Expanded(
                    child: Slider(
                      value: circleSize,
                      min: 20,
                      max: 100,
                      divisions: 8,
                      label: circleSize.round().toString(),
                      onChanged: (val) => circleSize = val,
                    ),
                  ),
                ],
              ),

              // Font size slider
              Row(
                children: [
                  Text('Font Size'),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: 8,
                      max: 32,
                      divisions: 12,
                      label: fontSize.round().toString(),
                      onChanged: (val) => fontSize = val,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Color pickers for circle and font
              Row(
                children: [
                  Text('Circle Color'),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<Color>(
                        context: context,
                        builder: (ctx2) {
                          return AlertDialog(
                            title: Text('Pick Circle Color'),
                            content: ColorPicker(
                              color: circleColor,
                              onChanged: (c) => circleColor = c,
                              pickersEnabled: const {
                                ColorPickerType.hsv: true,
                                ColorPickerType.wheel: true,
                                ColorPickerType.hexInput: true,
                              },
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx2).pop(circleColor),
                                  child: Text('Done')),
                            ],
                          );
                        },
                      );
                      if (picked != null) circleColor = picked;
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                        border: Border.all(),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              Row(
                children: [
                  Text('Font Color'),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<Color>(
                        context: context,
                        builder: (ctx2) {
                          return AlertDialog(
                            title: Text('Pick Font Color'),
                            content: ColorPicker(
                              color: fontColor,
                              onChanged: (c) => fontColor = c,
                              pickersEnabled: const {
                                ColorPickerType.hsv: true,
                                ColorPickerType.wheel: true,
                                ColorPickerType.hexInput: true,
                              },
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx2).pop(fontColor),
                                  child: Text('Done')),
                            ],
                          );
                        },
                      );
                      if (picked != null) fontColor = picked;
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fontColor,
                        border: Border.all(),
                      ),
                    ),
                  ),
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
              // If person.id is empty, assign a new UUID
              final newId = person.id.isEmpty ? uuid.v4() : person.id;

              final edited = Person(
                id: newId,
                name: nameController.text.trim(),
                surname: surnameController.text.trim(),
                birthName: birthNameController.text.trim(),
                fatherName: fatherNameController.text.trim(),
                dob: dobController.text.trim(),
                gender: gender,
                motherId: selectedMotherId,
                fatherId: selectedFatherId,
                spouseId: selectedSpouseId,
                position: person.position, // keep same position (for “Add”, initial caller will set center),
                circleSize: circleSize,
                circleColor: circleColor,
                fontColor: fontColor,
                fontSize: fontSize,
              );

              onSave(edited);
              Navigator.of(ctx).pop();
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

///
/// A helper widget that shows a dropdown of allPeople (filtered by gender, if required),
/// plus a “None” option.  It writes back to `currentId`.
///
class _RelationDropdown extends StatelessWidget {
  final String label;
  final List<Person> allPeople;
  final String? currentId;
  final void Function(String?) onChanged;
  final String filterGender; // "male", "female", or "all"

  const _RelationDropdown({
    required this.label,
    required this.allPeople,
    required this.currentId,
    required this.onChanged,
    required this.filterGender,
  });

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: '', child: Text('None')),
      ...allPeople.where((p) {
        if (p.id == currentId) return false;
        if (filterGender == 'male' && p.gender != 'male') return false;
        if (filterGender == 'female' && p.gender != 'female') return false;
        return true;
      }).map((p) {
        return DropdownMenuItem(
          value: p.id,
          child: Text(p.fullName),
        );
      }).toList(),
    ];

    return DropdownButtonFormField<String>(
      value: currentId ?? '',
      decoration: InputDecoration(labelText: label),
      onChanged: (v) {
        onChanged(v == '' ? null : v);
      },
      items: items,
    );
  }
}
