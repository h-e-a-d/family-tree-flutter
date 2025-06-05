// lib/models/person.dart
import 'dart:ui';
import 'package:json_annotation/json_annotation.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {
  String id;
  String name;
  String surname;
  String birthName;
  String fatherName;
  String dob;
  String gender; // 'male' / 'female' / 'unknown'
  String? motherId;
  String? fatherId;
  String? spouseId;

  // screen position of the circle
  @JsonKey(fromJson: _offsetFromJson, toJson: _offsetToJson)
  Offset position;

  // circle color
  @JsonKey(
    fromJson: _colorFromJson,
    toJson: _colorToJson,
  )
  Color circleColor;

  // text color (for name/dob)
  @JsonKey(
    fromJson: _colorFromJson,
    toJson: _colorToJson,
  )
  Color textColor;

  // fontFamily
  String fontFamily;

  // fontSize (in pixels)
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

  factory Person.fromJson(Map<String, dynamic> json) =>
      _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  // Helpers to (de)serialize Offset <-> [x, y]
  static Offset _offsetFromJson(List<double> coords) =>
      Offset(coords[0], coords[1]);
  static List<double> _offsetToJson(Offset o) => [o.dx, o.dy];

  // Helpers to (de)serialize Color <-> ARGB int
  static Color _colorFromJson(int argb) => Color(argb);
  static int _colorToJson(Color c) => c.value;
}
