import 'dart:ui';

class Person {
  String id;
  String name;
  String surname;
  String birthName;
  String fatherName; // Just a string field for convenience; not used in connector logic
  String dob;
  String gender;
  String? motherId;
  String? fatherId;
  String? spouseId;
  Offset position;

  Person({
    required this.id,
    required this.name,
    required this.surname,
    required this.birthName,
    required this.fatherName,
    required this.dob,
    required this.gender,
    this.motherId,
    this.fatherId,
    this.spouseId,
    required this.position,
  });

  String get fullName => '$name $surname';

  /// Convert Person to a JSON‐compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'birthName': birthName,
      'fatherName': fatherName,
      'dob': dob,
      'gender': gender,
      'motherId': motherId,
      'fatherId': fatherId,
      'spouseId': spouseId,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
    };
  }

  /// Reconstruct a Person from a Map (the inverse of toJson).
  static Person fromJson(Map<String, dynamic> m) {
    final posMap = m['position'] as Map<String, dynamic>;
    return Person(
      id: m['id'] as String,
      name: m['name'] as String,
      surname: m['surname'] as String,
      birthName: m['birthName'] as String,
      fatherName: m['fatherName'] as String,
      dob: m['dob'] as String,
      gender: m['gender'] as String,
      motherId: (m['motherId'] as String?)?.isNotEmpty == true ? (m['motherId'] as String) : null,
      fatherId: (m['fatherId'] as String?)?.isNotEmpty == true ? (m['fatherId'] as String) : null,
      spouseId: (m['spouseId'] as String?)?.isNotEmpty == true ? (m['spouseId'] as String) : null,
      position: Offset(
        (posMap['dx'] as num).toDouble(),
        (posMap['dy'] as num).toDouble(),
      ),
    );
  }

  /// Create a deep copy (used for undo history).
  Person copy() {
    return Person(
      id: id,
      name: name,
      surname: surname,
      birthName: birthName,
      fatherName: fatherName,
      dob: dob,
      gender: gender,
      motherId: motherId,
      fatherId: fatherId,
      spouseId: spouseId,
      position: Offset(position.dx, position.dy),
    );
  }
}
