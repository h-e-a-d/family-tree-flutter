// lib/views/home_view.dart
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../widgets/person_node.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Person> people = [];
  bool showTable = false;

  void _addPerson() {
    final newPerson = Person(
      id: DateTime.now().toIso8601String(),
      name: 'New',
      surname: 'Person',
      birthName: '',
      fatherName: '',
      dob: '',
      gender: 'unknown',
      position: Offset(100 + people.length * 50, 100),
    );
    setState(() {
      people.add(newPerson);
    });
  }

  void _updatePerson(Person updatedPerson) {
    setState(() {
      final index = people.indexWhere((p) => p.id == updatedPerson.id);
      if (index != -1) people[index] = updatedPerson;
    });
  }

  Widget _buildCanvasView() {
    return Stack(
      children: [
        ...people.map((person) => PersonNode(
              person: person,
              allPeople: people,
              onUpdate: _updatePerson,
            )),
      ],
    );
  }

  Widget _buildTableView() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Surname')),
          DataColumn(label: Text('DOB')),
          DataColumn(label: Text('Gender')),
        ],
        rows: people.map((p) {
          return DataRow(cells: [
            DataCell(Text(p.name)),
            DataCell(Text(p.surname)),
            DataCell(Text(p.dob)),
            DataCell(Text(p.gender)),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree'),
        actions: [
          IconButton(
            icon: Icon(showTable ? Icons.account_tree : Icons.table_chart),
            onPressed: () => setState(() => showTable = !showTable),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        child: Icon(Icons.add),
      ),
      body: showTable ? _buildTableView() : _buildCanvasView(),
    );
  }
} 
