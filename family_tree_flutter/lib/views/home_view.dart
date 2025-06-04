import 'package:flutter/material.dart';
import '../models/person.dart';
import '../widgets/person_node.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Person> people = [];
  bool isTableView = false;

  void _addPerson() {
    final person = Person(
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
      people.add(person);
    });
  }

  void _updatePerson(Person updated) {
    setState(() {
      final index = people.indexWhere((p) => p.id == updated.id);
      if (index != -1) people[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree Builder'),
        actions: [
          IconButton(
            icon: Icon(isTableView ? Icons.account_tree : Icons.table_chart),
            tooltip: 'Toggle View',
            onPressed: () {
              setState(() {
                isTableView = !isTableView;
              });
            },
          ),
        ],
      ),
      body: isTableView ? _buildTableView() : _buildTreeView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        tooltip: 'Add Person',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTreeView() {
    return Stack(
      children: people
          .map((person) => PersonNode(
                person: person,
                allPeople: people,
                onUpdate: _updatePerson,
              ))
          .toList(),
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
        rows: people.map((person) {
          return DataRow(cells: [
            DataCell(Text(person.name)),
            DataCell(Text(person.surname)),
            DataCell(Text(person.dob)),
            DataCell(Text(person.gender)),
          ]);
        }).toList(),
      ),
    );
  }
}
