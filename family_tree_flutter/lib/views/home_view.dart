// lib/views/home_view.dart

import 'dart:convert';
import 'dart:html' as html;          // For web‐only file import/export
import 'dart:typed_data';
import 'dart:ui' as ui;             // For RepaintBoundary → toImage()

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';
import '../widgets/person_node.dart';
import '../widgets/connector_line.dart';

///
/// The main canvas “Home” screen.  Contains:
///  • An InteractiveViewer + RepaintBoundary stack
///  • A “+” button to add at viewport center
///  • Top bar with Undo / To Front / Connect / ExportJSON / ImportJSON / ExportPNG
///  • Per‐circle font/color controls when selected
///
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey _canvasKey = GlobalKey();
  final uuid = Uuid();

  // All Person objects
  List<Person> _people = [];

  // Undo stack: each entry is a deep copy of the _people list
  final List<List<Person>> _history = [];

  // Currently selected Person.id (or null)
  String? _selectedId;

  // Connect‐mode state
  bool _connectMode = false;
  String? _firstConnectId;

  // Pan & zoom
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
  }

  // Push a snapshot into undo history (deep copy)
  void _pushHistory() {
    final snapshot = _people.map((p) => Person.fromJson(p.toJson())).toList();
    _history.add(snapshot);
    if (_history.length > 50) {
      _history.removeAt(0);
    }
  }

  // Undo
  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _people = _history.removeLast();
      _selectedId = null;
      _connectMode = false;
      _firstConnectId = null;
    });
  }

  // Bring selected to front (i.e. move to end of _people so it draws last)
  void _bringToFront() {
    if (_selectedId == null) return;
    final idx = _people.indexWhere((p) => p.id == _selectedId);
    if (idx == -1) return;
    final p = _people.removeAt(idx);
    _people.add(p);
    setState(() {});
  }

  // Add a new person at the center of the visible viewport
  void _addPerson() {
    _pushHistory();
    final renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final centerLocal = Offset(size.width / 2, size.height / 2);
    // Invert the current matrix: visible viewport → canvas coordinates
    final inv = Matrix4.inverted(_transformationController.value);
    final vec3 = inv.transform3(Vector3(centerLocal.dx, centerLocal.dy, 0));
    final newPos = Offset(vec3.x, vec3.y);

    final newPerson = Person(
      id: '',
      name: '',
      surname: '',
      birthName: '',
      fatherName: '',
      dob: '',
      gender: '',
      position: newPos,
    );

    _people.add(newPerson);
    setState(() {
      _selectedId = '';
    });

    // Immediately open modal for the new person
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _openModalFor('');
    });
  }

  // Select or Deselect a person
  void _selectPerson(String? id) {
    setState(() {
      if (_selectedId == id) {
        _selectedId = null;
      } else {
        _selectedId = id;
      }
      // Cancels connect‐mode if active
      if (_selectedId != null && _connectMode) {
        _connectMode = false;
        _firstConnectId = null;
      }
    });
  }

  // Toggle connect mode
  void _startConnect() {
    if (_selectedId == null) return;
    setState(() {
      if (_connectMode) {
        _connectMode = false;
        _firstConnectId = null;
      } else {
        _connectMode = true;
        _firstConnectId = _selectedId;
      }
    });
  }

  // Attempt to form a relation between two tapped circles
  void _completeConnect(String otherId) {
    if (!_connectMode || _firstConnectId == null) return;
    if (_firstConnectId == otherId) {
      setState(() {
        _connectMode = false;
        _firstConnectId = null;
      });
      return;
    }
    _pushHistory();
    final p1 = _people.firstWhere((p) => p.id == _firstConnectId);
    final p2 = _people.firstWhere((p) => p.id == otherId);

    // If p1.gender is “male” or “female” → parent-child; otherwise spouse
    if (p1.gender == 'male') {
      p2.fatherId = p1.id;
    } else if (p1.gender == 'female') {
      p2.motherId = p1.id;
    } else {
      p1.spouseId = p2.id;
      p2.spouseId = p1.id;
    }

    setState(() {
      _connectMode = false;
      _firstConnectId = null;
    });
  }

  // Update a person in place
  void _updatePerson(Person edited) {
    final idx = _people.indexWhere((p) => p.id == edited.id);
    if (idx == -1) return;
    _pushHistory();
    _people[idx] = edited;
    setState(() {});
  }

  // Delete a person and clear any references
  void _deletePerson(String id) {
    _pushHistory();
    _people.removeWhere((p) => p.id == id);
    for (var p in _people) {
      if (p.motherId == id) p.motherId = null;
      if (p.fatherId == id) p.fatherId = null;
      if (p.spouseId == id) p.spouseId = null;
    }
    setState(() {
      if (_selectedId == id) _selectedId = null;
    });
  }

  // Export JSON (web only)
  void _exportToJson() {
    final listMap = _people.map((p) => p.toJson()).toList();
    final jsonStr = jsonEncode(listMap);
    final bytes = utf8.encode(jsonStr);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..download = 'family_tree_export.json';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  // Import JSON (web only)
  Future<void> _importFromJson() async {
    final input = html.FileUploadInputElement()
      ..accept = '.json'
      ..multiple = false;
    input.click();
    input.onChange.listen((_) {
      final file = input.files!.first;
      final reader = html.FileReader();
      reader.onLoad.first.then((_) {
        final content = reader.result as String;
        final List<dynamic> listMap = jsonDecode(content);
        final imported = listMap
            .map((e) => Person.fromJson(e as Map<String, dynamic>))
            .toList();
        _pushHistory();
        setState(() {
          _people = imported;
          _selectedId = null;
        });
      });
      reader.readAsText(file);
    });
  }

  // Export to PNG (web only)
  Future<void> _exportToPng() async {
    try {
      final boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..download = 'family_tree.png';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PNG: $e')),
      );
    }
  }

  // Deselect and cancel connect on double‐tap of blank area
  void _onBackgroundDoubleTap() {
    setState(() {
      _selectedId = null;
      _connectMode = false;
      _firstConnectId = null;
    });
  }

  // Open “Edit Person” modal for a given ID (or blank ID for a newly added Person)
  Future<void> _openModalFor(String id) async {
    Person target;
    if (id.isEmpty) {
      // Just‐created person has id==""; the Person object in the list also has id==""
      target = _people.firstWhere((p) => p.id == "");
    } else {
      target = _people.firstWhere((p) => p.id == id);
    }
    await showPersonModal(
      context: context,
      person: target,
      allPeople: _people,
      onSave: (edited) {
        // If that Person had no ID, assign the new UUID and replace in list
        if (edited.id.isEmpty) {
          edited.id = uuid.v4();
        }
        _updatePerson(edited);
      },
    );
    // After saving, if it was a “new” person, it now has a real id, so if was showing "" as selected, fix:
    if (_selectedId == "") {
      final newId = _people.firstWhere((p) => p.id != "").id;
      setState(() {
        _selectedId = newId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main canvas: InteractiveViewer + RepaintBoundary ──
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _onBackgroundDoubleTap,
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  transformationController: _transformationController,
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Stack(
                      children: [
                        // Grid background
                        CustomPaint(
                          size: Size(2000, 2000),
                          painter: _GridPainter(),
                        ),

                        // Connector lines
                        ..._generateConnectorLines(),

                        // Person nodes
                        ..._people.map((p) {
                          return PersonNode(
                            key: ValueKey(p.id),
                            person: p,
                            allPeople: _people,
                            onUpdate: (edited) => _updatePerson(edited),
                            onSelect: (selId) {
                              if (_connectMode && _firstConnectId != null) {
                                if (selId != null) {
                                  _completeConnect(selId);
                                }
                              } else {
                                _selectPerson(selId);
                              }
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // “+” button in lower right
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                onPressed: _addPerson,
                child: Icon(Icons.add),
              ),
            ),

            // Top‐left bar: Undo / To Front / Connect / Export/Import JSON / Export PNG
            Positioned(
              top: 16,
              left: 16,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.undo),
                      tooltip: 'Undo',
                      onPressed: _history.isEmpty ? null : _undo,
                    ),
                    IconButton(
                      icon: Icon(Icons.vertical_align_top),
                      tooltip: 'Bring Selected to Front',
                      onPressed: (_selectedId == null) ? null : _bringToFront,
                    ),
                    IconButton(
                      icon: Icon(Icons.compare_arrows),
                      tooltip: _connectMode ? 'Cancel Connect' : 'Connect',
                      color: _connectMode ? Colors.orange : null,
                      onPressed: (_selectedId == null) ? null : _startConnect,
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.download_outlined),
                      label: Text('Export JSON'),
                      onPressed:
                          _people.isEmpty ? null : () => _exportToJson(),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.upload_outlined),
                      label: Text('Import JSON'),
                      onPressed: _importFromJson,
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.image_outlined),
                      label: Text('Export PNG'),
                      onPressed:
                          _people.isEmpty ? null : () => _exportToPng(),
                    ),
                  ],
                ),
              ),
            ),

            // Top‐right: font/color controls when a circle is selected
            if (_selectedId != null)
              Positioned(
                top: 16,
                right: 16,
                child: _SelectedControls(
                  person: _people.firstWhere((p) => p.id == _selectedId),
                  onUpdate: (edited) => _updatePerson(edited),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Builds a list of ConnectorLine widgets for every relation
  List<Widget> _generateConnectorLines() {
    final lines = <Widget>[];
    for (var p in _people) {
      if (p.motherId != null) {
        final mom = _people.firstWhere((x) => x.id == p.motherId);
        lines.add(ConnectorLine(from: mom, to: p, isSpouse: false));
      }
      if (p.fatherId != null) {
        final dad = _people.firstWhere((x) => x.id == p.fatherId);
        lines.add(ConnectorLine(from: dad, to: p, isSpouse: false));
      }
      if (p.spouseId != null) {
        final s = _people.firstWhere((x) => x.id == p.spouseId);
        if (p.id.compareTo(s.id) < 0) {
          lines.add(ConnectorLine(from: p, to: s, isSpouse: true));
        }
      }
    }
    return lines;
  }
}

///
/// Simple grid background painter (2000×2000, 50px step).
///
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const step = 50.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

///
/// When a circle is selected, show these controls:
///  • Circle‐color (HSV) picker
///  • Font‐color (HSV) picker
///  • Font‐size slider
///
class _SelectedControls extends StatefulWidget {
  final Person person;
  final void Function(Person) onUpdate;

  const _SelectedControls({
    required this.person,
    required this.onUpdate,
  });

  @override
  State<_SelectedControls> createState() => _SelectedControlsState();
}

class _SelectedControlsState extends State<_SelectedControls> {
  late double fontSize;
  late Color fontColor;
  late Color circleColor;

  @override
  void initState() {
    super.initState();
    fontSize = widget.person.fontSize;
    fontColor = widget.person.fontColor;
    circleColor = widget.person.circleColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle color
          Row(
            children: [
              Text('Circle:'),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDialog<Color>(
                    context: context,
                    builder: (ctx2) {
                      return AlertDialog(
                        title: Text('Circle Color'),
                        content: ColorPicker(
                          color: circleColor,
                          onChanged: (c) => circleColor = c,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx2).pop(circleColor),
                              child: Text('Done')),
                        ],
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      circleColor = picked;
                    });
                    final updated = Person.fromJson(widget.person.toJson())
                      ..circleColor = circleColor;
                    widget.onUpdate(updated);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: Border.all(),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Font color
          Row(
            children: [
              Text('Font:'),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDialog<Color>(
                    context: context,
                    builder: (ctx2) {
                      return AlertDialog(
                        title: Text('Font Color'),
                        content: ColorPicker(
                          color: fontColor,
                          onChanged: (c) => fontColor = c,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx2).pop(fontColor),
                              child: Text('Done')),
                        ],
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      fontColor = picked;
                    });
                    final updated = Person.fromJson(widget.person.toJson())
                      ..fontColor = fontColor;
                    widget.onUpdate(updated);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: fontColor,
                    shape: BoxShape.circle,
                    border: Border.all(),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Font size slider
          Row(
            children: [
              Text('Size:'),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 8,
                  max: 32,
                  divisions: 12,
                  label: fontSize.round().toString(),
                  onChanged: (v) {
                    setState(() {
                      fontSize = v;
                    });
                    final updated = Person.fromJson(widget.person.toJson())
                      ..fontSize = fontSize;
                    widget.onUpdate(updated);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
