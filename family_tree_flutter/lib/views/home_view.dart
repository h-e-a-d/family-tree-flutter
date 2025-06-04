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

  List<Widget> _buildRelationshipLines() {
    List<Widget> lines = [];

    for (var person in people) {
      final from = person.position;

      void addLineTo(String? relatedId, Color color) {
        if (relatedId == null) return;
        final target = people.firstWhere(
          (p) => p.id == relatedId,
          orElse: () => Person(
            id: '',
            name: '',
            dob: '',
            gender: '',
            position: Offset.zero,
          ),
        );
        if (target.id.isEmpty) return;

        lines.add(Positioned.fill(
          child: CustomPaint(
            painter: LinePainter(from + Offset(30, 30), target.position + Offset(30, 30), color),
          ),
        ));
      }

      addLineTo(person.motherId, Colors.pink);
      addLineTo(person.fatherId, Colors.blue);
      addLineTo(person.spouseId, Colors.green);
    }

    return lines;
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
          children: [
            ..._buildRelationshipLines(),
            ...people.map((person) => PersonNode(
                  person: person,
                  onUpdate: _onUpdatePerson,
                )),
          ],
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final Offset p1;
  final Offset p2;
  final Color color;

  LinePainter(this.p1, this.p2, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
