// lib/models/person.dart

import 'dart:ui';

class Person {
  String id;
  String givenName;
  String fatherName;
  String surname;
  String birthName;
  String dob;
  String gender;
  String? motherId;
  String? spouseId;
  Offset position;
  double circleRadius;
  double fontSize;
  Color circleColor;
  Color textColor;

  Person({
    required this.id,
    required this.givenName,
    required this.fatherName,
    required this.surname,
    required this.birthName,
    required this.dob,
    required this.gender,
    this.motherId,
    this.spouseId,
    required this.position,
    this.circleRadius = 30,
    this.fontSize = 14,
    this.circleColor = const Color(0xFF90CAF9),
    this.textColor = const Color(0xFF000000),
  });

  String get fullName => '$givenName $surname';

  Map<String, dynamic> toJson() => {
        'id': id,
        'givenName': givenName,
        'fatherName': fatherName,
        'surname': surname,
        'birthName': birthName,
        'dob': dob,
        'gender': gender,
        'motherId': motherId,
        'spouseId': spouseId,
        'positionX': position.dx,
        'positionY': position.dy,
        'circleRadius': circleRadius,
        'fontSize': fontSize,
        'circleColor': circleColor.value,
        'textColor': textColor.value,
      };

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      givenName: json['givenName'],
      fatherName: json['fatherName'],
      surname: json['surname'],
      birthName: json['birthName'],
      dob: json['dob'],
      gender: json['gender'],
      motherId: json['motherId'],
      spouseId: json['spouseId'],
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      circleRadius: (json['circleRadius'] as num).toDouble(),
      fontSize: (json['fontSize'] as num).toDouble(),
      circleColor: Color(json['circleColor']),
      textColor: Color(json['textColor']),
    );
  }
}
