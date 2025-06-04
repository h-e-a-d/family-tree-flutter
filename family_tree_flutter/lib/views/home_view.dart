import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/person.dart';
import '../widgets/person_node.dart';
import '../widgets/settings_panel.dart';
import '../utils/json_io.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

enum Mode { view, connect }

class _HomeViewState extends State<HomeView> {
  List<Person> people = [];
  bool isTableView = false;
  Mode mode = Mode.view;
  Person? selectedOne;
  double fontSize = 14;
  Color fontColor = Colors.black;
  String fontFamily = 'Arial';

  final GlobalKey repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree Builder'),
        actions: [
          IconButton(
            icon: Icon(Icons.import_export),
            tooltip: 'Export PNG',
            onPressed: _exportAsPNG,
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportAsPDF,
          ),
          IconButton(
            icon: Icon(Icons.table_chart),
            tooltip: 'Toggle Table',
            onPressed: () => setState(() => isTableView = !isTableView),
          ),
          IconButton(
            icon: Icon(mode == Mode.connect ? Icons.link_off : Icons.link),
            tooltip: mode == Mode.connect ? 'Cancel Connect' : 'Connect Two',
            onPressed: () => setState(() {
              mode = mode == Mode.connect ? Mode.view : Mode.connect;
              selectedOne = null;
            }),
          ),
          SettingsPanel(
            fontSize: fontSize,
            fontColor: fontColor,
            fontFamily: fontFamily,
            onChanged: (sz, col, fam) async {
              setState(() {
                fontSize = sz;
                fontColor = col;
                fontFamily = fam;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'export_json') {
                final json = JsonIO.encodePeople(people);
                await JsonIO.saveToFile('family_tree.json', json);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Exported to family_tree.json')));
              }
              if (val == 'import_json') {
                final contents = await JsonIO.loadFromFile('family_tree.json');
                final loaded = JsonIO.decodePeople(contents);
                setState(() => people = loaded);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'export_json', child: Text('Export JSON')),
              PopupMenuItem(value: 'import_json', child: Text('Import JSON')),
            ],
          ),
        ],
      ),
      body: isTableView ? _buildTable() : _buildCanvas(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildCanvas() {
    return InteractiveViewer(
      boundaryMargin: EdgeInsets.all(200),
      minScale: 0.1,
      maxScale: 2.5,
      child: RepaintBoundary(
        key: repaintKey,
        child: CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(),
          child: Stack(
            children: [
              ..._relationshipLines(),
              ...people.map((p) {
                final isSel = (mode == Mode.connect && selectedOne == p);
                return PersonNode(
                  person: p,
                  allPeople: people,
                  onUpdate: (u) => setState(() {}),
                  fontSize: fontSize,
                  fontColor: fontColor,
                  fontFamily: fontFamily,
                  isSelected: isSel,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _relationshipLines() {
    return people.expand((person) {
      final lines = <Widget>[];
      // Spouse
      if (person.spouseId != null) {
        final spouse = people.firstWhere(
            (x) => x.id == person.spouseId,
            orElse: () => Person(
                  id: '',
                  name: '',
                  surname: '',
                  birthName: '',
                  fatherName: '',
                  dob: '',
                  gender: '',
                  position: Offset.zero,
                ));
        if (spouse.id.isNotEmpty) {
          lines.add(_drawLine(person.position, spouse.position,
              color: Colors.red, dashed: true));
        }
      }
      // Parents
      if (person.fatherId != null) {
        final fa = people.firstWhere(
            (x) => x.id == person.fatherId,
            orElse: () => Person(
                id: '',
                name: '',
                surname: '',
                birthName: '',
                fatherName: '',
                dob: '',
                gender: '',
                position: Offset.zero));
        if (fa.id.isNotEmpty) {
          lines.add(_drawLine(fa.position, person.position, color: Colors.black));
        }
      }
      if (person.motherId != null) {
        final mo = people.firstWhere(
            (x) => x.id == person.motherId,
            orElse: () => Person(
                id: '',
                name: '',
                surname: '',
                birthName: '',
                fatherName: '',
                dob: '',
                gender: '',
                position: Offset.zero));
        if (mo.id.isNotEmpty) {
          lines.add(_drawLine(mo.position, person.position, color: Colors.black));
        }
      }
      return lines;
    }).toList();
  }

  Widget _drawLine(Offset a, Offset b,
      {Color color = Colors.black, bool dashed = false}) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ConnectorPainter(from: a, to: b, color: color, dashed: dashed),
      ),
    );
  }

  void _addPerson() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final person = Person(
      id: id,
      name: 'First',
      surname: 'Last',
      birthName: '',
      fatherName: '',
      dob: '',
      gender: 'unknown',
      position: Offset(100 + people.length * 80, 100),
    );
    setState(() => people.add(person));
  }

  void _exportAsPNG() async {
    final bytes = await _captureImage();
    if (bytes != null) {
      await Printing.sharePdf(bytes: bytes, filename: 'family_tree.png');
    }
  }

  Future<Uint8List?> _captureImage() async {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _exportAsPDF() async {
    final bytes = await _captureImage();
    if (bytes != null) {
      final doc = pw.Document();
      final img = pw.MemoryImage(bytes);
      doc.addPage(pw.Page(build: (c) => pw.Center(child: pw.Image(img))));
      await Printing.sharePdf(bytes: await doc.save(), filename: 'family_tree.pdf');
    }
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Given Name')),
          DataColumn(label: Text("Father's Name")),
          DataColumn(label: Text('Surname')),
          DataColumn(label: Text('Birth Name')),
          DataColumn(label: Text('Date of Birth')),
          DataColumn(label: Text('Gender')),
          DataColumn(label: Text('Mother')),
          DataColumn(label: Text('Father')),
          DataColumn(label: Text('Spouse')),
        ],
        rows: people.map((p) {
          String motherName = '';
          String fatherName = '';
          String spouseName = '';
          if (p.motherId != null) {
            motherName = people
                .firstWhere((x) => x.id == p.motherId!, orElse: () => Person(
                      id: '',
                      name: '',
                      surname: '',
                      birthName: '',
                      fatherName: '',
                      dob: '',
                      gender: '',
                      position: Offset.zero,
                    ))
                .fullName;
          }
          if (p.fatherId != null) {
            fatherName = people
                .firstWhere((x) => x.id == p.fatherId!, orElse: () => Person(
                      id: '',
                      name: '',
                      surname: '',
                      birthName: '',
                      fatherName: '',
                      dob: '',
                      gender: '',
                      position: Offset.zero,
                    ))
                .fullName;
          }
          if (p.spouseId != null) {
            spouseName = people
                .firstWhere((x) => x.id == p.spouseId!, orElse: () => Person(
                      id: '',
                      name: '',
                      surname: '',
                      birthName: '',
                      fatherName: '',
                      dob: '',
                      gender: '',
                      position: Offset.zero,
                    ))
                .fullName;
          }
          return DataRow(cells: [
            DataCell(Text(p.name)),
            DataCell(Text(p.fatherName)),
            DataCell(Text(p.surname)),
            DataCell(Text(p.birthName)),
            DataCell(Text(p.dob)),
            DataCell(Text(p.gender)),
            DataCell(Text(motherName)),
            DataCell(Text(fatherName)),
            DataCell(Text(spouseName)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ConnectorPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;
  final bool dashed;

  _ConnectorPainter(
      {required this.from, required this.to, required this.color, this.dashed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (dashed) {
      const dashWidth = 6.0;
      const dashSpace = 4.0;
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
