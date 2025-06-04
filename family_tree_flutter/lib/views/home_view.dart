import 'package:flutter/material.dart';
import '../widgets/person_node.dart';
import '../models/person.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Person> people = [];

  void _addPerson() {
    setState(() {
      people.add(
        Person(
          id: DateTime.now().toString(),
          name: 'New Person',
          dob: '',
          gender: 'unknown',
          position: Offset(100 + people.length * 50, 100),
        ),
      );
    });
  }

  void _onUpdatePerson(Person updated) {
    setState(() {
      final index = people.indexWhere((p) => p.id == updated.id);
      if (index != -1) people[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree (Graphical View)'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addPerson,
          ),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 5.0,
        minScale: 0.1,
        child: Stack(
          children: people
              .map((person) => PersonNode(
                    person: person,
                    onUpdate: _onUpdatePerson,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
