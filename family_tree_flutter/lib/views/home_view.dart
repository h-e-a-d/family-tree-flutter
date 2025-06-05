// lib/views/home_view.dart

import 'dart:convert';
import 'dart:html' as html;                  // For Web‐only JSON export/import
import 'package:flutter/material.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../models/person.dart';
import '../widgets/person_node.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final List<Person> _people = [];
  final List<String> _historyStack = [];
  int _nextId = 1;

  // Which person is tapped/selected?
  String? _selectedPersonId;

  // Connect‐mode toggles
  bool _connectMode = false;
  String? _firstConnectId;

  // Controller for pan & zoom
  final TransformationController _transformController =
      TransformationController();

  // Painter for the grid background
  final GridPainter _gridPainter = GridPainter();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Push current snapshot onto _historyStack
  void _pushHistory() {
    final jsonString = jsonEncode(
      _people.map((p) => p.toJson()).toList(),
    );
    _historyStack.add(jsonString);
    if (_historyStack.length > 100) {
      _historyStack.removeAt(0);
    }
  }

  /// Undo (pop last snapshot)
  void _undo() {
    if (_historyStack.isEmpty) return;
    final lastJson = _historyStack.removeLast();
    final List<dynamic> decoded = jsonDecode(lastJson);
    _people
      ..clear()
      ..addAll(decoded
          .map((obj) => Person.fromJson(obj as Map<String, dynamic>)));
    // Deselect after undo
    _selectedPersonId = null;
    setState(() {});
  }

  /// Add a new person at the center of the visible canvas
  void _addPerson() {
    _pushHistory();

    // Determine the screen center
    final screenCenter = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    // Map screen coords → canvas coords via transformController’s 4×4 matrix
    final m = _transformController.value;
    final v = m.transform3(Vector3(screenCenter.dx, screenCenter.dy, 0));
    final canvasCenter = Offset(v.x, v.y);

    final newPerson = Person(
      id: 'p${_nextId++}',
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
    _selectedPersonId = newPerson.id;
    setState(() {});
  }

  /// When a circle’s drag begins, we push one history entry
  void _onPersonDragStart() {
    _pushHistory();
  }

  /// Update an entire Person (e.g. after drag or after editing)
  void _updatePerson(Person updated) {
    final idx = _people.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _people[idx] = updated;
      setState(() {});
    }
  }

  /// Handler for tapping/selecting a Person
  void _selectPerson(Person p) {
    setState(() {
      // Toggle connect‐mode if already selected in connect mode
      if (_connectMode) {
        if (_firstConnectId == null) {
          _firstConnectId = p.id;
        } else if (_firstConnectId != p.id) {
          final a = _people.firstWhere((x) => x.id == _firstConnectId);
          final b = p;

          final alreadyRelated = a.motherId == b.id ||
              a.fatherId == b.id ||
              b.motherId == a.id ||
              b.fatherId == a.id ||
              a.spouseId == b.id;

          if (!alreadyRelated) {
            // If two opposite genders (and neither is 'unknown'), make them spouses
            if (a.gender != 'unknown' && b.gender != 'unknown' && a.gender != b.gender) {
              a.spouseId = b.id;
              b.spouseId = a.id;
            } else {
              // Otherwise link as father→child
              b.fatherId = a.id;
              b.fatherName = a.fullName;
            }
          }
          _connectMode = false;
          _firstConnectId = null;
        }
      } else {
        // Just normal selection
        _selectedPersonId = p.id;
      }
    });
  }

  /// “Bring selected circle to front” (move it to end of _people list)
  void _bringToFront() {
    if (_selectedPersonId == null) return;
    final idx = _people.indexWhere((p) => p.id == _selectedPersonId);
    if (idx >= 0) {
      _pushHistory();
      final p = _people.removeAt(idx);
      _people.add(p);
      setState(() {});
    }
  }

  /// Export current people list as JSON (web)
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

  /// Import JSON from file (web)
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
          _selectedPersonId = null;
          setState(() {});
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid JSON. Cannot import.')),
          );
        }
      });
    });
  }

  /// Change color of the selected person
  void _changeSelectedColor(Color newColor) {
    if (_selectedPersonId == null) return;
    final idx = _people.indexWhere((p) => p.id == _selectedPersonId);
    if (idx < 0) return;
    _pushHistory();
    final p = _people[idx];
    p.circleColor = newColor;
    setState(() {});
  }

  /// Change text color of the selected person
  void _changeSelectedTextColor(Color newColor) {
    if (_selectedPersonId == null) return;
    final idx = _people.indexWhere((p) => p.id == _selectedPersonId);
    if (idx < 0) return;
    _pushHistory();
    final p = _people[idx];
    p.textColor = newColor;
    setState(() {});
  }

  /// Change font size of the selected person
  void _changeSelectedFontSize(double newSize) {
    if (_selectedPersonId == null) return;
    final idx = _people.indexWhere((p) => p.id == _selectedPersonId);
    if (idx < 0) return;
    _pushHistory();
    final p = _people[idx];
    p.fontSize = newSize.clamp(8.0, 72.0);
    setState(() {});
  }

  /// Change font family of the selected person
  void _changeSelectedFontFamily(String newFamily) {
    if (_selectedPersonId == null) return;
    final idx = _people.indexWhere((p) => p.id == _selectedPersonId);
    if (idx < 0) return;
    _pushHistory();
    final p = _people[idx];
    p.fontFamily = newFamily;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // If a person is selected, find them:
    Person? selectedPerson;
    if (_selectedPersonId != null) {
      selectedPerson =
          _people.firstWhere((p) => p.id == _selectedPersonId, orElse: () => _people.first);
    }

    // Font family options:
    final fontOptions = <String>[
      'Arial',
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Source Sans Pro',
      'Poppins',
      'Times New Roman',
      'Courier New',
      'Merriweather',
      'PT Serif'
    ];

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
            onPressed: _selectedPersonId == null ? null : _bringToFront,
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
                _selectedPersonId = null;
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
          // Pan/Zoom + Grid + Connectors + PersonNodes:
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
                  // 1) Grid background
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _gridPainter,
                  ),

                  // 2) Connector lines
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: ConnectorPainter(_people),
                  ),

                  // 3) Person nodes
                  for (var person in _people)
                    PersonNode(
                      person: person,
                      allPeople: _people,
                      isSelected: person.id == _selectedPersonId,
                      onSelect: () => _selectPerson(person),
                      onUpdate: (updatedPerson) => _updatePerson(updatedPerson),
                      onDragStart: _onPersonDragStart,
                    ),
                ],
              ),
            ),
          ),

          // 4) Overlay color & font controls (when a circle is selected):
          if (selectedPerson != null)
            Positioned(
              bottom: 100,
              right: 20,
              child: Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        'Stroke & Text Colors',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Lucid HSV Color Picker for circleColor:
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: HsvColorPicker(
                          initialColor: selectedPerson.circleColor,
                          onChanged: (clr) {
                            _changeSelectedColor(clr);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lucid HSV Picker for textColor:
                      const Text(
                        'Text Color',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: HsvColorPicker(
                          initialColor: selectedPerson.textColor,
                          onChanged: (clr) {
                            _changeSelectedTextColor(clr);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Font family + size controls:
                      const Text(
                        'Font Family & Size',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: selectedPerson.fontFamily,
                        items: fontOptions
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) _changeSelectedFontFamily(val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Size:'),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 6),
                              ),
                              style: const TextStyle(fontSize: 14),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                  text:
                                      selectedPerson.fontSize.toInt().toString()),
                              onSubmitted: (text) {
                                final parsed = double.tryParse(text);
                                if (parsed != null) {
                                  _changeSelectedFontSize(parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5) “+” button in bottom‐right:
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              tooltip: 'Add Person',
              child: const Icon(Icons.add, size: 32),
              onPressed: _addPerson,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a light grid in the background (every 50px).
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 50.0;
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
    final parentPaint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..color = Colors.black87;

    final spousePaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = Colors.redAccent;

    for (final child in people) {
      // Mother → child
      if (child.motherId != null) {
        final mother = people.firstWhere(
            (p) => p.id == child.motherId,
            orElse: () => child);
        _drawLine(mother.position, child.position, canvas, parentPaint);
      }
      // Father → child
      if (child.fatherId != null) {
        final father = people.firstWhere(
            (p) => p.id == child.fatherId,
            orElse: () => child);
        _drawLine(father.position, child.position, canvas, parentPaint);
      }
      // Spouse (dashed)
      if (child.spouseId != null) {
        final spouse = people.firstWhere(
            (p) => p.id == child.spouseId,
            orElse: () => child);
        _drawDashedLine(child.position, spouse.position, canvas, spousePaint);
      }
    }
  }

  void _drawLine(
      Offset a, Offset b, Canvas canvas, Paint paint) {
    canvas.drawLine(a, b, paint);
  }

  void _drawDashedLine(
      Offset a, Offset b, Canvas canvas, Paint paint) {
    final totalLen = (b - a).distance;
    if (totalLen < 0.5) return;
    final dashWidth = 8.0;
    final dashSpace = 4.0;
    final dx = (b.dx - a.dx) / totalLen;
    final dy = (b.dy - a.dy) / totalLen;
    double drawn = 0.0;
    while (drawn < totalLen) {
      final x1 = a.dx + dx * drawn;
      final y1 = a.dy + dy * drawn;
      final next = (drawn + dashWidth).clamp(0, totalLen);
      final x2 = a.dx + dx * next;
      final y2 = a.dy + dy * next;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
