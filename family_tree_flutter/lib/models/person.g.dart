// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
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
      position: Person._offsetFromJson(
          (json['position'] as List<dynamic>).map((e) => (e as num).toDouble()).toList()),
      circleColor: Person._colorFromJson(json['circleColor'] as int),
      textColor: Person._colorFromJson(json['textColor'] as int),
      fontFamily: json['fontFamily'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
    );

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'surname': instance.surname,
      'birthName': instance.birthName,
      'fatherName': instance.fatherName,
      'dob': instance.dob,
      'gender': instance.gender,
      'motherId': instance.motherId,
      'fatherId': instance.fatherId,
      'spouseId': instance.spouseId,
      'position': Person._offsetToJson(instance.position),
      'circleColor': Person._colorToJson(instance.circleColor),
      'textColor': Person._colorToJson(instance.textColor),
      'fontFamily': instance.fontFamily,
      'fontSize': instance.fontSize,
    };
