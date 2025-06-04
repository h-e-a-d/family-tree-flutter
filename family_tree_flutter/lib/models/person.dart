import 'dart:convert';
import 'dart:ui';

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
  double radius;

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
    this.radius = 30,
  });

  String get fullName => '$name $surname';

  /// Serialize to JSON
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
        'x': position.dx,
        'y': position.dy,
        'radius': radius,
      };

  /// Deserialize from JSON
  factory Person.fromJson(Map<String, dynamic> m) => Person(
        id: m['id'],
        name: m['name'],
        surname: m['surname'],
        birthName: m['birthName'],
        fatherName: m['fatherName'],
        dob: m['dob'],
        gender: m['gender'],
        motherId: m['motherId'],
        fatherId: m['fatherId'],
        spouseId: m['spouseId'],
        position: Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()),
        radius: (m['radius'] as num).toDouble(),
      );

  static String encodeList(List<Person> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());

  static List<Person> decodeList(String jsonString) {
    final arr = jsonDecode(jsonString) as List<dynamic>;
    return arr.map((m) => Person.fromJson(m as Map<String, dynamic>)).toList();
  }
}
