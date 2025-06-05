// lib/main.dart
import 'package:flutter/material.dart';
import 'views/home_view.dart';

void main() {
  runApp(const FamilyTreeApp());
}

class FamilyTreeApp extends StatelessWidget {
  const FamilyTreeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Tree Builder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Default font family
        fontFamily: 'Arial',
      ),
      home: const HomeView(),
    );
  }
}
