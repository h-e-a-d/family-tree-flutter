import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
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
  ScreenshotController screenshotController = ScreenshotController();

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

  void _exportAsPNG() async {
    final image = await screenshotController.capture();
    if (image != null) {
      await Printing.sharePdf(bytes: image, filename: 'family_tree.png');
    }
  }

  void _exportAsPDF() async {
    final image = await screenshotController.capture();
    if (image != null) {
      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(image);
      pdf.addPage(pw.Page(build: (context) => pw.Center(child: pw.Image(pwImage))));
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'family_tree.pdf');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree Builder'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportAsPDF,
          ),
          IconButton(
            icon: Icon(Icons.image),
            tooltip: 'Export PNG',
            onPressed: _exportAsPNG,
          ),
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
              if (val == 'Increase Font') {
                setState(() => fontSize += 2);
              } else if (val == 'Decrease Font') {
                setState(() => fontSize = (fontSize - 2).clamp(8, 40));
              } else if (val == 'Color: Red') {
                setState(() => fontColor = Colors.red);
              } else if (val == 'Color: Blue') {
                setState(() => fontColor = Colors.blue);
              } else if (val == 'Color: Black') {
                setState(() => fontColor = Colors.black);
              }
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
    return Screenshot(
      controller: screenshotController,
      child: Stack(
        children: [
          CustomPaint(
            painter: RelationshipPainter(people: people),
            size: Size.infinite,
          ),
          ...people.map<Widget>((person) {
            return PersonNode(
              person: person,
              allPeople: people,
              onUpdate: _updatePerson,
              fontSize: fontSize,
              fontColor: fontColor,
            );
          }).toList(),
        ],
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

class RelationshipPainter extends CustomPainter {
  final List<Person> people;
  RelationshipPainter({required this.people});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    for (var person in people) {
      final p1 = person.position + const Offset(50, 20);
      if (person.motherId != null) {
        final mother = people.firstWhere((p) => p.id == person.motherId, orElse: () => person);
        final p2 = mother.position + const Offset(50, 20);
        canvas.drawLine(p1, p2, paint);
      }
      if (person.fatherId != null) {
        final father = people.firstWhere((p) => p.id == person.fatherId, orElse: () => person);
        final p2 = father.position + const Offset(50, 20);
        canvas.drawLine(p1, p2, paint);
      }
      if (person.spouseId != null) {
        final spouse = people.firstWhere((p) => p.id == person.spouseId, orElse: () => person);
        final p2 = spouse.position + const Offset(50, 20);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
