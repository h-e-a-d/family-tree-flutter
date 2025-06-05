import 'dart:convert';
import 'dart:html' as html; // for web file upload/download
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'; // for mobile JSON import/export
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../widgets/person_node.dart';
import '../widgets/connector_line.dart';

///
/// The main “canvas” view, containing:
///  - A RepaintBoundary‐wrapped Stack for all PersonNodes & ConnectorLines
///  - Top‐right “+” button to add a new Person at canvas center
///  - Undo, To Front, Color/Font controls shown when a circle is selected
///  - JSON Export/Import buttons
///
class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey _canvasKey = GlobalKey();
  final uuid = Uuid();

  // All persons
  List<Person> _people = [];

  // History stack for “undo”
  final List<List<Person>> _history = [];

  // Currently selected Person id
  String? _selectedId;

  // Are we in “connect mode”?
  bool _connectMode = false;
  String? _firstConnectId;

  // Pan & zoom
  final TransformationController _transformationController =
      TransformationController();
  late final ui.ViewportBoundary _vpBoundary;

  @override
  void initState() {
    super.initState();
    // No need to set vpBoundary manually; we’ll use InteractiveViewer.
  }

  // Push a deep‐copied snapshot into history
  void _pushHistory() {
    final snapshot = _people
        .map((p) => Person.fromJson(p.toJson()))
        .toList();
    _history.add(snapshot);
    if (_history.length > 50) {
      // cap undo‐stack at 50
      _history.removeAt(0);
    }
  }

  // Undo to previous state
  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _people = _history.removeLast();
      _selectedId = null;
      _connectMode = false;
      _firstConnectId = null;
    });
  }

  // Bring selected Person to front (end of list → drawn last)
  void _bringToFront() {
    if (_selectedId == null) return;
    final idx = _people.indexWhere((p) => p.id == _selectedId);
    if (idx == -1) return;
    final person = _people.removeAt(idx);
    _people.add(person);
    setState(() {});
  }

  // Add a new person at canvas center
  void _addPerson() {
    _pushHistory();
    // Compute canvas center in global coordinates
    final matrix = _transformationController.value;
    final renderBox =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final centerLocal = Offset(size.width / 2, size.height / 2);
    // Invert the matrix to map viewport→canvas coordinates
    final inv = Matrix4.inverted(matrix);
    final c = inv.transform3(Vector3(centerLocal.dx, centerLocal.dy, 0));
    final pos = Offset(c.x, c.y);
    final newPerson = Person(
      id: uuid.v4(),
      name: '',
      surname: '',
      birthName: '',
      fatherName: '',
      dob: '',
      gender: '',
      position: pos,
    );
    _people.add(newPerson);
    setState(() {
      _selectedId = newPerson.id;
    });
    // Immediately open edit modal on the new person
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _openModalFor(newPerson.id);
    });
  }

  // Select or unselect
  void _selectPerson(String? id) {
    setState(() {
      if (_selectedId == id) {
        _selectedId = null;
      } else {
        _selectedId = id;
      }
      // Exiting connect mode if someone reselects
      if (_selectedId != null && _connectMode) {
        _connectMode = false;
        _firstConnectId = null;
      }
    });
  }

  // Connect mode tapped
  void _startConnect() {
    if (_selectedId == null) return;
    setState(() {
      if (_connectMode) {
        // if already in connect mode, cancel it
        _connectMode = false;
        _firstConnectId = null;
      } else {
        _connectMode = true;
        _firstConnectId = _selectedId;
      }
    });
  }

  // Complete a connection between two circles
  void _completeConnect(String otherId) {
    if (!_connectMode || _firstConnectId == null) return;
    if (_firstConnectId == otherId) {
      // cannot connect to itself
      setState(() {
        _connectMode = false;
        _firstConnectId = null;
      });
      return;
    }
    _pushHistory();
    final p1 = _people.firstWhere((p) => p.id == _firstConnectId);
    final p2 = _people.firstWhere((p) => p.id == otherId);

    // Decide relation: if genders opposite → parent-child
    // For simplicity: if p1.gender == 'male', then p1 is father of p2. etc.
    // Here we’ll simply set p2.fatherId = p1.id if p1.gender=='male'
    if (p1.gender == 'male') {
      p2.fatherId = p1.id;
    } else if (p1.gender == 'female') {
      p2.motherId = p1.id;
    } else {
      // default: spouse relationship
      p1.spouseId = p2.id;
      p2.spouseId = p1.id;
    }

    setState(() {
      _connectMode = false;
      _firstConnectId = null;
    });
  }

  // Modify a person in place
  void _updatePerson(Person edited) {
    final idx = _people.indexWhere((p) => p.id == edited.id);
    if (idx == -1) return;
    _pushHistory();
    _people[idx] = edited;
    setState(() {});
  }

  // Remove a person and any references to it
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

  // Export all persons (and relations) as JSON, then trigger download
  void _exportToJson() {
    final listMap = _people.map((p) => p.toJson()).toList();
    final jsonStr = jsonEncode(listMap);

    // On web: use a Blob, then an anchor for download
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

  // Import JSON: open file picker (web) or native (mobile)
  Future<void> _importFromJson() async {
    if (kIsWeb) {
      // Web: use an <input type="file"> from dart:html
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
    } else {
      // Mobile (Android/iOS): pick from local file system
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        // In a real app you’d present a file‐picker UI. For brevity:
        // We assume a file named “family_tree_import.json” in documents/
        final file = File('$path/family_tree_import.json');
        if (!await file.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No “family_tree_import.json” found in Documents')),
          );
          return;
        }
        final content = await file.readAsString();
        final List<dynamic> listMap = jsonDecode(content);
        final imported = listMap
            .map((e) => Person.fromJson(e as Map<String, dynamic>))
            .toList();

        _pushHistory();
        setState(() {
          _people = imported;
          _selectedId = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  // Capture canvas and trigger PNG download (web) or save to file (mobile)
  Future<void> _exportToPng() async {
    try {
      final boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([pngBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = 'family_tree.png';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/family_tree.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PNG saved to $filePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PNG: $e')),
      );
    }
  }

  // On double‐tap of blank area, deselect everything and cancel connect
  void _onBackgroundDoubleTap() {
    setState(() {
      _selectedId = null;
      _connectMode = false;
      _firstConnectId = null;
    });
  }

  // Open edit modal for a given Person ID
  Future<void> _openModalFor(String id) async {
    final person = _people.firstWhere((p) => p.id == id);
    await showPersonModal(
      context: context,
      person: person,
      allPeople: _people,
      onSave: (edited) => _updatePerson(edited),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main canvas area with pan & zoom → 
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _onBackgroundDoubleTap,
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
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

                        // Connector lines (parent/child & spouses)
                        ..._generateConnectorLines(),

                        // PersonNodes (in order)
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

            // “+” button (bottom-right)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                onPressed: _addPerson,
                child: Icon(Icons.add),
              ),
            ),

            // Top‐left: Undo / To Front / Connect / Export / Import
            Positioned(
              top: 16,
              left: 16,
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
                    onPressed:
                        (_selectedId == null) ? null : _bringToFront,
                  ),
                  IconButton(
                    icon: Icon(Icons.compare_arrows),
                    tooltip: _connectMode ? 'Cancel Connect' : 'Connect',
                    color: _connectMode ? Colors.orange : null,
                    onPressed:
                        (_selectedId == null) ? null : _startConnect,
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.download_outlined),
                    label: Text('Export JSON'),
                    onPressed: _people.isEmpty ? null : _exportToJson,
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
                    onPressed: _people.isEmpty ? null : _exportToPng,
                  ),
                ],
              ),
            ),

            // When a Person is selected, show font/color controls at top‐right
            if (_selectedId != null) ...[
              Positioned(
                top: 16,
                right: 16,
                child: _SelectedControls(
                  person: _people.firstWhere((p) => p.id == _selectedId),
                  onUpdate: (edited) => _updatePerson(edited),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Generate connector lines based on parent‐child and spouse relations
  List<Widget> _generateConnectorLines() {
    final lines = <Widget>[];
    for (var p in _people) {
      // Mother line
      if (p.motherId != null) {
        final mom = _people.firstWhere((x) => x.id == p.motherId);
        lines.add(ConnectorLine(start: mom.position, end: p.position, isSpouse: false));
      }
      // Father line
      if (p.fatherId != null) {
        final dad = _people.firstWhere((x) => x.id == p.fatherId);
        lines.add(ConnectorLine(start: dad.position, end: p.position, isSpouse: false));
      }
      // Spouse line
      if (p.spouseId != null) {
        final s = _people.firstWhere((x) => x.id == p.spouseId);
        // Only draw if our ID < spouseId to avoid drawing twice
        if (p.id.compareTo(s.id) < 0) {
          lines.add(ConnectorLine(start: p.position, end: s.position, isSpouse: true));
        }
      }
    }
    return lines;
  }
}

///
/// Draws a light grid background (2000×2000).  Adjust as needed.
///
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final step = 50.0;
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
///  - Circle color picker (HSV Popup)
///  - Font color picker (HSV Popup)
///  - Font size slider
///
class _SelectedControls extends StatelessWidget {
  final Person person;
  final Function(Person) onUpdate;

  const _SelectedControls({
    required this.person,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    double fontSize = person.fontSize;
    Color fontColor = person.fontColor;
    Color circleColor = person.circleColor;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        children: [
          // Circle Color Picker
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
                          pickersEnabled: const {
                            ColorPickerType.hsv: true,
                            ColorPickerType.wheel: true,
                            ColorPickerType.hexInput: true,
                          },
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx2).pop(circleColor),
                              child: Text('Done')),
                        ],
                      );
                    },
                  );
                  if (picked != null) {
                    final updated = Person.fromJson(person.toJson())
                      ..circleColor = picked;
                    onUpdate(updated);
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

          // Font Color Picker
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
                          pickersEnabled: const {
                            ColorPickerType.hsv: true,
                            ColorPickerType.wheel: true,
                            ColorPickerType.hexInput: true,
                          },
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx2).pop(fontColor),
                              child: Text('Done')),
                        ],
                      );
                    },
                  );
                  if (picked != null) {
                    final updated = Person.fromJson(person.toJson())
                      ..fontColor = picked;
                    onUpdate(updated);
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
                    fontSize = v;
                    final updated = Person.fromJson(person.toJson())
                      ..fontSize = fontSize;
                    onUpdate(updated);
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
