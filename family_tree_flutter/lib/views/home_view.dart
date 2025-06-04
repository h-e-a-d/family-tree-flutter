import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/person.dart';
import '../widgets/person_node.dart';
import '../widgets/settings_panel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Person> people = [];
  bool isTableView = false;
  double fontSize = 14;
  Color fontColor = Colors.black;
  String fontFamily = 'Arial';
  final GlobalKey repaintKey = GlobalKey();

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
    setState(() => people.add(person));
  }

  void _updatePerson(Person updated) {
    setState(() {
      final index = people.indexWhere((p) => p.id == updated.id);
      if (index != -1) people[index] = updated;
    });
  }

  Future<Uint8List?> _captureAsImage() async {
    RenderRepaintBoundary boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _exportAsPNG() async {
    final bytes = await _captureAsImage();
    if (bytes != null) {
      await Printing.sharePdf(bytes: bytes, filename: 'family_tree.png');
    }
  }

  void _exportAsPDF() async {
    final bytes = await _captureAsImage();
    if (bytes != null) {
      final pdf = pw.Document();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(pw.Page(build: (context) => pw.Center(child: pw.Image(image))));
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'family_tree.pdf');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree Builder'),
        actions: [
          IconButton(icon: Icon(Icons.image), tooltip: 'Export PNG', onPressed: _exportAsPNG),
          IconButton(icon: Icon(Icons.picture_as_pdf), tooltip: 'Export PDF', onPressed: _exportAsPDF),
          IconButton(
            icon: Icon(isTableView ? Icons.account_tree : Icons.table_chart),
            tooltip: 'Toggle View',
            onPressed: () => setState(() => isTableView = !isTableView),
          ),
          SettingsPanel(
            fontSize: fontSize,
            fontColor: fontColor,
            fontFamily: fontFamily,
            onChanged: (size, color, family) {
              setState(() {
                fontSize = size;
                fontColor = color;
                fontFamily = family;
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
    return RepaintBoundary(
      key: repaintKey,
      child: Stack(
        children: [
          ..._buildRelationshipLines(),
          ...people.map((person) => PersonNode(
                person: person,
                allPeople: people,
                onUpdate: _updatePerson,
                fontSize: fontSize,
                fontColor: fontColor,
                fontFamily: fontFamily,
              )),
        ],
      ),
    );
  }

  List<Widget> _buildRelationshipLines() {
    return people.expand((person) {
      final lines = <Widget>[];

      // Spouse connector
      final spouse = people.firstWhere(
        (p) => p.id == person.spouseId,
        orElse: () => Person(id: '', name: '', surname: '', birthName: '', fatherName: '', dob: '', gender: '', position: Offset.zero),
      );
      if (spouse.id.isNotEmpty) {
        lines.add(_buildLine(person.position, spouse.position, color: Colors.red, dashed: true));
      }

      // Parent-child connectors
      final parents = [
        if (person.fatherId != null)
          people.firstWhere((p) => p.id == person.fatherId, orElse: () => Person(id: '', name: '', surname: '', birthName: '', fatherName: '', dob: '', gender: '', position: Offset.zero)),
        if (person.motherId != null)
          people.firstWhere((p) => p.id == person.motherId, orElse: () => Person(id: '', name: '', surname: '', birthName: '', fatherName: '', dob: '', gender: '', position: Offset.zero)),
      ];
      for (final parent in parents) {
        if (parent.id.isNotEmpty) {
          lines.add(_buildLine(parent.position, person.position, color: Colors.black));
        }
      }

      return lines;
    }).toList();
  }

  Widget _buildLine(Offset from, Offset to, {Color color = Colors.black, bool dashed = false}) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ConnectorPainter(from: from, to: to, color: color, dashed: dashed),
      ),
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

class _ConnectorPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;
  final bool dashed;

  _ConnectorPainter({required this.from, required this.to, required this.color, this.dashed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (dashed) {
      const dashWidth = 5.0;
      const dashSpace = 3.0;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final distance = sqrt(dx * dx + dy * dy);
      final steps = distance ~/ (dashWidth + dashSpace);
      for (int i = 0; i < steps; i++) {
        final start = Offset(
          from.dx + (dx / steps) * i,
          from.dy + (dy / steps) * i,
        );
        final end = Offset(
          from.dx + (dx / steps) * i + dashWidth,
          from.dy + (dy / steps) * i + dashWidth,
        );
        canvas.drawLine(start, end, paint);
      }
    } else {
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
