import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../models/person.dart';

class JsonIO {
  /// Save JSON string to file at given path
  static Future<void> saveToFile(String path, String json) async {
    final file = File(path);
    await file.writeAsString(json);
  }

  /// Load JSON string from file at given path
  static Future<String> loadFromFile(String path) async {
    final file = File(path);
    return await file.readAsString();
  }

  /// Load bundled example (if any)
  static Future<String> loadAsset(String assetPath) async {
    return await rootBundle.loadString(assetPath);
  }

  /// Expose encode/decode helpers:
  static String encodePeople(List<Person> list) => Person.encodeList(list);
  static List<Person> decodePeople(String jsonStr) =>
      Person.decodeList(jsonStr);
}
