import 'package:flutter/material.dart';

class Person {
  final String id;
  String name;
  String dob;
  String gender;
  Offset position;

  Person({
    required this.id,
    required this.name,
    required this.dob,
    required this.gender,
    required this.position,
  });
}
