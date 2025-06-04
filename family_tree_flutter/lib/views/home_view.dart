import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../widgets/person_node.dart';

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
          id: DateTime.now().toIso8601String(),
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

  void _exportAsImage() {
    final html.Element svg = html.document.querySelector('flt-glass-pane')!;
    final blob = html.Blob([svg.outerHtml!], 'text/plain', 'native');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "family_tree_export.html")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  List<Widget> _buildRelationshipLines() {
    List<Widget> lines = [];

    for (var person in people) {
      final from = person.position;

      void drawLineTo(String? id, Color color) {
        if (id == null) return;
        final target = people.firstWhere((p) => p.id == id, orElse: () => Person(id: '', name: '', dob: '', gender: '', position: Offset.zero));
        if (target.id.isEmpty) return;

        lines.add(Positioned.fill(
          child: CustomPaint(
            painter: LinePainter(from + Offset(30, 30), target.position + Offset(30, 30), color),
          ),
        ));
      }

      drawLineTo(person.motherId, Colors.pink);
      drawLineTo(person.fatherId, Colors.blue);
      drawLineTo(person.spouseId, Colors.green);
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add Person',
            onPressed: _addPerson,
          ),
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Export as HTML Snapshot',
            onPressed: _exportAsImage,
          )
        ],
      ),
      body: InteractiveViewer(
        boundaryMargin: EdgeInsets.all(1000),
        minScale: 0.1,
        maxScale: 5,
        child: Stack(
          children: [
            ..._buildRelationshipLines(),
            ...people.map((p) => PersonNode(
                  person: p,
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
