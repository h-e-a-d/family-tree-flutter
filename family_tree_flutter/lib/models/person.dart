// lib/models/person.dart

import 'package:flutter/material.dart';

class Person {
  String id;
  String name;
  String surname;
  String birthName;
  String fatherName;
  String dob;
  String gender;
  String? motherId;
  String? fatherId;
  String? spouseId;
  Offset position;
  double circleSize;
  Color circleColor;
  Color fontColor;
  double fontSize;

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
    this.circleSize = 40.0,
    this.circleColor = const Color(0xFF90CAF9),
    this.fontColor = Colors.black,
    this.fontSize = 14.0,
  });

  String get fullName => '$name $surname';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
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
        'position': {'dx': position.dx, 'dy': position.dy},
        'circleSize': circleSize,
        'circleColor': circleColor.value,
        'fontColor': fontColor.value,
        'fontSize': fontSize,
      };

  /// Create from JSON
  factory Person.fromJson(Map<String, dynamic> m) {
    final posMap = m['position'] as Map<String, dynamic>;
    return Person(
      id: m['id'] as String,
      name: m['name'] as String,
      surname: m['surname'] as String,
      birthName: m['birthName'] as String,
      fatherName: m['fatherName'] as String,
      dob: m['dob'] as String,
      gender: m['gender'] as String,
      motherId: m['motherId'] as String?,
      fatherId: m['fatherId'] as String?,
      spouseId: m['spouseId'] as String?,
      position: Offset(
        (posMap['dx'] as num).toDouble(),
        (posMap['dy'] as num).toDouble(),
      ),
      circleSize: (m['circleSize'] as num).toDouble(),
      circleColor: Color((m['circleColor'] as num).toInt()),
      fontColor: Color((m['fontColor'] as num).toInt()),
      fontSize: (m['fontSize'] as num).toDouble(),
    );
  }
}
