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

  // NEW:
  Color circleColor;
  Color textColor;
  String fontFamily;
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
    required this.circleColor,
    required this.textColor,
    required this.fontFamily,
    required this.fontSize,
  });

  String get fullName => '$name $surname';

  /// Convert to JSON (for export/undo)
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
      'circleColor': circleColor.value,
      'textColor': textColor.value,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
    };
  }

  /// Reconstruct from JSON (for import/undo)
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      birthName: json['birthName'] as String,
      fatherName: json['fatherName'] as String,
      dob: json['dob'] as String,
      gender: json['gender'] as String,
      motherId: json['motherId'] as String?,
      fatherId: json['fatherId'] as String?,
      spouseId: json['spouseId'] as String?,
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      circleColor: Color(json['circleColor'] as int),
      textColor: Color(json['textColor'] as int),
      fontFamily: json['fontFamily'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
    );
  }
}
