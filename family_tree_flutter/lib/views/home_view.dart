import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
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
  double fontSize = 14;
  Color fontColor = Colors.black;
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
            onPressed: () {
              setState(() {
                isTableView = !isTableView;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'Increase Font') setState(() => fontSize += 2);
              if (val == 'Decrease Font') setState(() => fontSize = (fontSize - 2).clamp(8, 40));
              if (val == 'Color: Red') setState(() => fontColor = Colors.red);
              if (val == 'Color: Blue') setState(() => fontColor = Colors.blue);
              if (val == 'Color: Black') setState(() => fontColor = Colors.black);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'Increase Font', child: Text('Increase Font')),
              PopupMenuItem(value: 'Decrease Font', child: Text('Decrease Font')),
              PopupMenuItem(value: 'Color: Red', child: Text('Font Color: Red')),
              PopupMenuItem(value: 'Color: Blue', child: Text('Font Color: Blue')),
              PopupMenuItem(value: 'Color: Black', child: Text('Font Color: Black')),
            ],
          )
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
        children: people.map<Widget>((person) {
          return PersonNode(
            person: person,
            allPeople: people,
            onUpdate: _updatePerson,
            fontSize: fontSize,
            fontColor: fontColor,
          );
        }).toList(),
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
