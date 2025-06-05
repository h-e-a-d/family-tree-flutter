// lib/views/home_view.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart'; // Unused now, but kept if needed
import 'package:lucid_color_picker/lucid_color_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../models/person.dart';
import '../widgets/person_node.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  // List of all people
  List<Person> _people = [];

  // For undo stack: we store deep copies of the _people + relationships
  final List<String> _undoStack = [];

  // Relationships: mother-child and spouse pairs by IDs
  // We only track mother-child edges and spouse edges
  List<Map<String, String>> _motherChildEdges = [];
  List<Map<String, String>> _spouseEdges = [];

  // Currently selected person
  Person? _selectedPerson;

  // To toggle connect-mode: user taps two circles to make a relation
  bool _connectMode = false;
  Person? _firstConnectPerson;

  // Keys for screenshot & scrollbar zooming
  final ScreenshotController _screenshotController = ScreenshotController();

  // Controllers for pan & zoom
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    // Initialize with one default person
    _addPersonAt(centerOfCanvas: true);
  }

  // Save current state (JSON string) to undo stack
  void _pushUndoStack() {
    final snapshot = {
      'people': _people.map((p) => p.toJson()).toList(),
      'motherChild': _motherChildEdges,
      'spouse': _spouseEdges,
    };
    _undoStack.add(jsonEncode(snapshot));
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
  }

  // Undo action
  void _undo() {
    if (_undoStack.isEmpty) return;
    final lastSnapshot = _undoStack.removeLast();
    final decoded = jsonDecode(lastSnapshot) as Map<String, dynamic>;

    final peopleJson = (decoded['people'] as List<dynamic>).cast<Map<String, dynamic>>();
    final motherChildJson = (decoded['motherChild'] as List<dynamic>).cast<Map<String, dynamic>>();
    final spouseJson = (decoded['spouse'] as List<dynamic>).cast<Map<String, dynamic>>();

    setState(() {
      _people = peopleJson.map((j) => Person.fromJson(j)).toList();
      _motherChildEdges = motherChildJson.cast<Map<String, String>>();
      _spouseEdges = spouseJson.cast<Map<String, String>>();
      _selectedPerson = null;
    });
  }

  // Bring selected person to front
  void _bringToFront() {
    if (_selectedPerson == null) return;
    _pushUndoStack();
    setState(() {
      final p = _selectedPerson!;
      _people.removeWhere((x) => x.id == p.id);
      _people.add(p);
    });
  }

  // Add a new Person at center or random location
  void _addPersonAt({bool centerOfCanvas = false}) {
    _pushUndoStack();
    final id = 'p${DateTime.now().millisecondsSinceEpoch}';
    Offset pos;
    if (centerOfCanvas) {
      final size = MediaQuery.of(context).size;
      pos = Offset(size.width / 2, size.height / 2 - 80);
    } else {
      pos = Offset(100 + _people.length * 10.0, 100 + _people.length * 10.0);
    }
    final newPerson = Person(
      id: id,
      givenName: 'First',
      fatherName: '',
      surname: 'Last',
      birthName: '',
      dob: '',
      gender: 'unknown',
      motherId: null,
      spouseId: null,
      position: pos,
    );
    setState(() {
      _people.add(newPerson);
      _selectedPerson = newPerson;
    });
  }

  // Delete selected person & all related edges
  void _deleteSelected() {
    if (_selectedPerson == null) return;
    _pushUndoStack();
    final toRemove = _selectedPerson!;
    setState(() {
      _people.removeWhere((p) => p.id == toRemove.id);
      _motherChildEdges.removeWhere(
          (edge) => edge['mother'] == toRemove.id || edge['child'] == toRemove.id);
      _spouseEdges.removeWhere((edge) =>
          edge['spouse1'] == toRemove.id || edge['spouse2'] == toRemove.id);
      _selectedPerson = null;
    });
  }

  // Toggle connect mode
  void _toggleConnectMode() {
    setState(() {
      _connectMode = !_connectMode;
      _firstConnectPerson = null;
    });
  }

  // Handle tapping on a person when in connect mode
  void _handleConnectTap(Person tapped) {
    if (!_connectMode) return;
    if (_firstConnectPerson == null) {
      _firstConnectPerson = tapped;
    } else if (_firstConnectPerson!.id != tapped.id) {
      // Determine relationship type via dialogs
      showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Choose relationship'),
            content: Text(
                'Tap “Mother-Child” if the first person is the mother of the second, or “Spouse” if they are spouses.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop('motherChild');
                },
                child: Text('Mother-Child'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop('spouse');
                },
                child: Text('Spouse'),
              ),
            ],
          );
        },
      ).then((relationType) {
        if (relationType == 'motherChild') {
          _pushUndoStack();
          setState(() {
            _motherChildEdges.add({
              'mother': _firstConnectPerson!.id,
              'child': tapped.id,
            });
          });
        } else if (relationType == 'spouse') {
          _pushUndoStack();
          setState(() {
            _spouseEdges.add({
              'spouse1': _firstConnectPerson!.id,
              'spouse2': tapped.id,
            });
          });
        }
        _firstConnectPerson = null;
      });
    }
  }

  // Export to JSON (downloads a file)
  Future<void> _exportToJson() async {
    final snapshot = {
      'people': _people.map((p) => p.toJson()).toList(),
      'motherChild': _motherChildEdges,
      'spouse': _spouseEdges,
    };
    final jsonString = jsonEncode(snapshot);

    // Write to a temporary file, then open share dialog (web will trigger download)
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/family_tree_export.json');
    await file.writeAsString(jsonString);

    // On Web, FilePicker is not needed – use AnchorElement trick
    if (kIsWeb) {
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'family_tree_export.json')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // On mobile/desktop, just print location (user can open)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to: ${file.path}')),
      );
    }
  }

  // Import from JSON (launch file picker)
  Future<void> _importFromJson() async {
    _pushUndoStack();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return;
    final fileBytes = result.files.single.bytes;
    final uploadedString = utf8.decode(fileBytes!);
    final decoded = jsonDecode(uploadedString) as Map<String, dynamic>;

    final peopleJson = (decoded['people'] as List<dynamic>).cast<Map<String, dynamic>>();
    final motherChildJson = (decoded['motherChild'] as List<dynamic>).cast<Map<String, String>>();
    final spouseJson = (decoded['spouse'] as List<dynamic>).cast<Map<String, String>>();

    setState(() {
      _people = peopleJson.map((j) => Person.fromJson(j)).toList();
      _motherChildEdges = motherChildJson.toList();
      _spouseEdges = spouseJson.toList();
      _selectedPerson = null;
    });
  }

  // Export to PNG via screenshot
  Future<void> _exportToPng() async {
    _pushUndoStack();
    final bytes = await _screenshotController.capture();
    if (bytes == null) return;

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'family_tree.png')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/family_tree.png');
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PNG saved: ${file.path}')),
      );
    }
  }

  // Draw connectors underneath all person nodes
  Widget _buildConnectorCanvas() {
    return CustomPaint(
      size: Size.infinite,
      painter: _ConnectorPainter(
        people: _people,
        motherChildEdges: _motherChildEdges,
        spouseEdges: _spouseEdges,
      ),
    );
  }

  // Main build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Screenshot(
        controller: _screenshotController,
        child: GestureDetector(
          onDoubleTapDown: (details) {
            _doubleTapDetails = details;
          },
          onDoubleTap: () {
            // Zoom in on double tap
            final position = _doubleTapDetails!.localPosition;
            final double scale = 2.0;
            final x = -position.dx * (scale - 1);
            final y = -position.dy * (scale - 1);
            final zoomed = Matrix4.identity()
              ..translate(x, y)
              ..scale(scale);
            _transformationController.value = zoomed;
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: EdgeInsets.all(200),
            minScale: 0.5,
            maxScale: 3.0,
            child: Stack(
              children: [
                // Grid background
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _GridPainter(),
                ),

                // Connector lines
                _buildConnectorCanvas(),

                // Person nodes
                ..._people.map(
                  (person) => PersonNode(
                    person: person,
                    allPeople: _people,
                    isSelected: _selectedPerson?.id == person.id,
                    onUpdate: (updated) => setState(() {}),
                    onSelect: (tapped) {
                      if (_connectMode) {
                        _handleConnectTap(tapped);
                      } else {
                        setState(() {
                          _selectedPerson = tapped;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo
          FloatingActionButton(
            heroTag: 'undoBtn',
            onPressed: _undo,
            tooltip: 'Undo',
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.undo, color: Colors.black87),
          ),
          SizedBox(height: 8),
          // Bring to Front
          FloatingActionButton(
            heroTag: 'frontBtn',
            onPressed: _bringToFront,
            tooltip: 'Bring to Front',
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.vertical_align_top, color: Colors.black87),
          ),
          SizedBox(height: 8),
          // Connect Mode
          FloatingActionButton(
            heroTag: 'connectBtn',
            onPressed: _toggleConnectMode,
            tooltip: 'Connect Persons',
            backgroundColor:
                _connectMode ? Colors.yellow.shade700 : Colors.grey.shade300,
            child: Icon(Icons.link, color: Colors.black87),
          ),
          SizedBox(height: 8),
          // Delete Selected
          FloatingActionButton(
            heroTag: 'deleteBtn',
            onPressed: _deleteSelected,
            tooltip: 'Delete Selected',
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.delete, color: Colors.white),
          ),
          SizedBox(height: 8),
          // Export PNG
          FloatingActionButton(
            heroTag: 'exportPngBtn',
            onPressed: _exportToPng,
            tooltip: 'Export as PNG',
            backgroundColor: Colors.green.shade600,
            child: Icon(Icons.image, color: Colors.white),
          ),
          SizedBox(height: 8),
          // Export JSON
          FloatingActionButton(
            heroTag: 'exportJsonBtn',
            onPressed: _exportToJson,
            tooltip: 'Export to JSON',
            backgroundColor: Colors.blue.shade700,
            child: Icon(Icons.download_rounded, color: Colors.white),
          ),
          SizedBox(height: 8),
          // Import JSON
          FloatingActionButton(
            heroTag: 'importJsonBtn',
            onPressed: _importFromJson,
            tooltip: 'Import from JSON',
            backgroundColor: Colors.orange.shade600,
            child: Icon(Icons.upload_file, color: Colors.white),
          ),
          SizedBox(height: 8),
          // Add Person
          FloatingActionButton(
            heroTag: 'addBtn',
            onPressed: () => _addPersonAt(centerOfCanvas: false),
            tooltip: 'Add Person',
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Painter for the grid
class _GridPainter extends CustomPainter {
  final double _step = 40;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for connectors (mother-child & spouse)
class _ConnectorPainter extends CustomPainter {
  final List<Person> people;
  final List<Map<String, String>> motherChildEdges;
  final List<Map<String, String>> spouseEdges;

  _ConnectorPainter({
    required this.people,
    required this.motherChildEdges,
    required this.spouseEdges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintChild = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2;
    final paintSpouse = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw mother-child lines (straight)
    for (var edge in motherChildEdges) {
      final mom = people.firstWhereOrNull((p) => p.id == edge['mother']);
      final child = people.firstWhereOrNull((p) => p.id == edge['child']);
      if (mom != null && child != null) {
        canvas.drawLine(
          mom.position,
          child.position,
          paintChild,
        );
      }
    }

    // Draw spouse lines (dashed)
    for (var edge in spouseEdges) {
      final p1 = people.firstWhereOrNull((p) => p.id == edge['spouse1']);
      final p2 = people.firstWhereOrNull((p) => p.id == edge['spouse2']);
      if (p1 != null && p2 != null) {
        _drawDashedLine(canvas, p1.position, p2.position, paintSpouse);
      }
    }
  }

  // Helper: draw dashed line
  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final totalLen = (b - a).distance;
    final dx = (b.dx - a.dx) / totalLen;
    final dy = (b.dy - a.dy) / totalLen;
    double start = 0.0;
    while (start < totalLen) {
      final end = math.min(start + dashWidth, totalLen);
      final x1 = a.dx + dx * start;
      final y1 = a.dy + dy * start;
      final x2 = a.dx + dx * end;
      final y2 = a.dy + dy * end;
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        paint,
      );
      start += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension to find element or return null
extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
