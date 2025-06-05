// lib/views/home_view.dart
import 'dart:convert';
import 'dart:html' as html; // For Web-only import/export
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart'; // For Vector3
import '../models/person.dart';
import '../widgets/person_node.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // All persons in the tree
  final List<Person> _people = [];

  // History stack for Undo (deep copies)
  final List<String> _historyStack = [];

  // ID-counter
  int _nextId = 1;

  // Currently selected Person ID (for “Bring to Front” or “Connect”)
  String? _selectedPersonId;

  // Are we in “Connect” mode? (click one circle, click another => link them as parent/child or spouse)
  bool _connectMode = false;

  // Temporary first‐selected in “Connect” mode
  String? _firstConnectId;

  // Controller for pan/zoom
  final TransformationController _transformController =
      TransformationController();

  // Grid painter
  final GridPainter _gridPainter = GridPainter();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // Save current state (JSON) onto historyStack
  void _pushHistory() {
    final jsonString = jsonEncode(_people.map((p) => p.toJson()).toList());
    _historyStack.add(jsonString);
    if (_historyStack.length > 50) {
      _historyStack.removeAt(0);
    }
  }

  // Undo last action
  void _undo() {
    if (_historyStack.isEmpty) return;
    final lastJson = _historyStack.removeLast();
    final List<dynamic> decoded = jsonDecode(lastJson);
    _people.clear();
    for (final obj in decoded) {
      _people.add(Person.fromJson(obj as Map<String, dynamic>));
    }
    setState(() {});
  }

  // Add a new person at viewport center
  void _addPerson() {
    _pushHistory();
    final id = 'p${_nextId++}';

    // Compute canvas‐space center by inverse‐transforming the screen center
    final screenCenter = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    final matrix = _transformController.value;
    final v = matrix.transform3(Vector3(
      screenCenter.dx,
      screenCenter.dy,
      0,
    ));
    final canvasCenter = Offset(v.x, v.y);

    final newPerson = Person(
      id: id,
      name: 'First',
      surname: 'Last',
      birthName: '',
      fatherName: '',
      dob: '',
      gender: 'unknown',
      motherId: null,
      fatherId: null,
      spouseId: null,
      position: canvasCenter,
      circleColor: Colors.blue.shade200,
      textColor: Colors.black,
      fontFamily: 'Arial',
      fontSize: 14,
    );
    _people.add(newPerson);
    setState(() {});
  }

  // Select a person (tap)
  void _selectPerson(Person p) {
    setState(() => _selectedPersonId = p.id);
    if (_connectMode) {
      if (_firstConnectId == null) {
        // Pick the first one
        _firstConnectId = p.id;
      } else if (_firstConnectId != p.id) {
        // We have two distinct circles: decide relationship
        final a = _people.firstWhere((x) => x.id == _firstConnectId);
        final b = p;
        // If either is already parent/child or spouse, skip
        if (a.motherId == b.id ||
            a.fatherId == b.id ||
            b.motherId == a.id ||
            b.fatherId == a.id ||
            a.spouseId == b.id) {
          // Already linked
        } else {
          // If genders differ → spouses
          if (a.gender != 'unknown' &&
              b.gender != 'unknown' &&
              a.gender != b.gender) {
            a.spouseId = b.id;
            b.spouseId = a.id;
          } else {
            // Otherwise make 'a' the father of 'b'
            b.fatherId = a.id;
            b.fatherName = a.fullName;
          }
        }
        _connectMode = false;
        _firstConnectId = null;
        setState(() {});
      }
    }
  }

  // Draw connector lines between parents & children, and spouses.
  Widget _buildConnectorCanvas() {
    return CustomPaint(
      size: Size.infinite,
      painter: ConnectorPainter(_people),
    );
  }

  // Update a Person (after edit or drag)
  void _updatePerson(Person updated) {
    final idx = _people.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _people[idx] = updated;
      setState(() {});
    }
  }

  // Bring selected circle to front
  void _bringToFront() {
    if (_selectedPersonId == null) return;
    _pushHistory();
    final idx = _people.indexWhere((p) => p.id == _selectedPersonId);
    if (idx >= 0) {
      final p = _people.removeAt(idx);
      _people.add(p);
      setState(() {});
    }
  }

  // Export current list of people to JSON (Web)
  void _exportJson() {
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(_people.map((p) => p.toJson()).toList());
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement;
    anchor.href = url;
    anchor.download = 'family_tree_export.json';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  // Import JSON (Web)
  void _importJson() {
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();
    uploadInput.onChange.listen((_) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoadEnd.listen((_) {
        try {
          final content = reader.result as String;
          final List<dynamic> data = jsonDecode(content);
          final imported = data
              .map((obj) => Person.fromJson(obj as Map<String, dynamic>))
              .toList();
          _pushHistory();
          _people
            ..clear()
            ..addAll(imported);
          setState(() {});
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid JSON file. Cannot import.')),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Tree Builder'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _historyStack.isEmpty ? null : _undo,
          ),
          IconButton(
            tooltip: 'Bring To Front',
            icon: const Icon(Icons.flip_to_front),
            onPressed:
                _selectedPersonId == null ? null : () => _bringToFront(),
          ),
          IconButton(
            tooltip: 'Connect Mode',
            icon: Icon(
              Icons.link,
              color: _connectMode ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _connectMode = !_connectMode;
                _firstConnectId = null;
              });
            },
          ),
          IconButton(
            tooltip: 'Export as JSON',
            icon: const Icon(Icons.download),
            onPressed: _exportJson,
          ),
          IconButton(
            tooltip: 'Import from JSON',
            icon: const Icon(Icons.upload),
            onPressed: _importJson,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Pan/zoom + grid + connectors + person nodes
          InteractiveViewer(
            transformationController: _transformController,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.2,
            maxScale: 3.0,
            child: Container(
              color: Colors.grey.shade200,
              child: Stack(
                children: [
                  // 1) Grid
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _gridPainter,
                  ),

                  // 2) Connectors
                  _buildConnectorCanvas(),

                  // 3) Person nodes
                  for (var i = 0; i < _people.length; i++)
                    PersonNode(
                      person: _people[i],
                      allPeople: _people,
                      isSelected: _selectedPersonId == _people[i].id,
                      onUpdate: (p) {
                        _pushHistory();
                        _updatePerson(p);
                      },
                      onSelect: (p) {
                        _selectPerson(p);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      // “+” button in lower right
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Person',
        child: const Icon(Icons.add, size: 32),
        onPressed: _addPerson,
      ),
    );
  }
}

/// Paints a light grid in the background (every 50px)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double step = 50;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws connector lines between parents & children, and spouses.
class ConnectorPainter extends CustomPainter {
  final List<Person> people;

  ConnectorPainter(this.people);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..color = Colors.black87;

    final dashPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = Colors.redAccent;

    for (final child in people) {
      // parent-child lines:
      if (child.motherId != null) {
        final mother = people.firstWhere(
            (p) => p.id == child.motherId,
            orElse: () => child);
        _drawLineBetween(parent: mother, child: child, canvas: canvas, paint: paint);
      }
      if (child.fatherId != null) {
        final father = people.firstWhere(
            (p) => p.id == child.fatherId,
            orElse: () => child);
        _drawLineBetween(parent: father, child: child, canvas: canvas, paint: paint);
      }
      // spouse lines:
      if (child.spouseId != null) {
        final spouse = people.firstWhere(
            (p) => p.id == child.spouseId,
            orElse: () => child);
        _drawDashedLineBetween(a: child, b: spouse, canvas: canvas, paint: dashPaint);
      }
    }
  }

  void _drawLineBetween({
    required Person parent,
    required Person child,
    required Canvas canvas,
    required Paint paint,
  }) {
    final Offset start = parent.position;
    final Offset end = child.position;
    canvas.drawLine(start, end, paint);
  }

  void _drawDashedLineBetween({
    required Person a,
    required Person b,
    required Canvas canvas,
    required Paint paint,
  }) {
    final start = a.position;
    final end = b.position;
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final totalLen = (end - start).distance;
    final dx = (end.dx - start.dx) / totalLen;
    final dy = (end.dy - start.dy) / totalLen;
    double drawn = 0.0;
    while (drawn < totalLen) {
      final x1 = start.dx + dx * drawn;
      final y1 = start.dy + dy * drawn;
      final next = drawn + dashWidth;
      final x2 = start.dx + dx * (next.clamp(0, totalLen));
      final y2 = start.dy + dy * (next.clamp(0, totalLen));
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
