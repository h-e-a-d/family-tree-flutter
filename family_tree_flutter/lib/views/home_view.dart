import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../widgets/person_node.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// List of all persons
  List<Person> people = [];

  /// Keep a stack of previous states (for undo)
  final List<List<Person>> _undoHistory = [];

  /// ID of the currently selected person (if any)
  String? _selectedPersonId;

  /// Whether we are in “connect mode” (not fully implemented for auto‐connect)
  bool _connectMode = false;
  String? _firstConnectId;

  /// Font settings (global)
  String _fontFamily = 'Roboto';
  double _fontSize = 12.0;
  Color _nameColor = Colors.black;
  Color _dateColor = Colors.grey.shade700;

  /// Controller for import/export dialogs
  final TextEditingController _jsonController = TextEditingController();

  /// Add a deep copy of current state to history
  void _pushToHistory() {
    final snapshot = people.map((p) => p.copy()).toList();
    _undoHistory.add(snapshot);
    // Cap history size if desired (e.g. last 20)
    if (_undoHistory.length > 50) _undoHistory.removeAt(0);
  }

  /// Undo last action
  void _undo() {
    if (_undoHistory.isEmpty) return;
    final prev = _undoHistory.removeLast();
    setState(() {
      people = prev.map((p) => p.copy()).toList();
      _selectedPersonId = null;
    });
  }

  /// Bring selected person to front (end of the list)
  void _bringToFront() {
    if (_selectedPersonId == null) return;
    final idx = people.indexWhere((p) => p.id == _selectedPersonId);
    if (idx < 0) return;
    _pushToHistory();
    final p = people.removeAt(idx);
    people.add(p);
    setState(() {});
  }

  /// Add a new Person at center
  void _addPerson() {
    _pushToHistory();
    final newId = 'p${people.length + 1}';
    final centerPosition = Offset(MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2 - 100);
    final newPerson = Person(
      id: newId,
      name: 'First$newId',
      surname: 'Last$newId',
      birthName: '',
      fatherName: '',
      dob: '',
      gender: 'unknown',
      position: centerPosition,
    );
    setState(() {
      people.add(newPerson);
      _selectedPersonId = newId;
    });
  }

  /// Serialize to JSON and show in dialog for copy.
  void _exportToJson() {
    final List<Map<String, dynamic>> listMap =
        people.map((p) => p.toJson()).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(listMap);
    _jsonController.text = jsonString;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export JSON'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(jsonString),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Import from JSON (pasted into a dialog)
  void _importFromJson() {
    _jsonController.text = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Import JSON'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: _jsonController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Paste valid JSON here and press Import',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final raw = jsonDecode(_jsonController.text) as List<dynamic>;
                  final imported = raw
                      .map((e) =>
                          Person.fromJson(e as Map<String, dynamic>))
                      .toList();
                  _pushToHistory();
                  setState(() {
                    people = imported;
                    _selectedPersonId = null;
                  });
                  Navigator.of(ctx).pop();
                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON: $err')),
                  );
                }
              },
              child: Text('Import'),
            ),
          ],
        );
      },
    );
  }

  /// Draw connector lines between parent‐child and spouse
  Widget _buildConnectorPainter() {
    return CustomPaint(
      size: Size.infinite,
      painter: ConnectorPainter(people),
    );
  }

  /// Center all nodes in the viewport
  void _centerAll() {
    if (people.isEmpty) return;
    _pushToHistory();
    final width = MediaQuery.of(context).size.width;
    final height =
        MediaQuery.of(context).size.height - 160; // account for controls
    // Spread out horizontally for simplicity
    final dxStep = width / (people.length + 1);
    for (var i = 0; i < people.length; i++) {
      people[i].position = Offset((i + 1) * dxStep, height / 2);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree Builder'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: Icon(Icons.undo),
            onPressed: _undoHistory.isEmpty ? null : _undo,
          ),
          IconButton(
            tooltip: 'Bring to Front',
            icon: Icon(Icons.vertical_align_top),
            onPressed:
                _selectedPersonId == null ? null : _bringToFront,
          ),
          IconButton(
            tooltip: 'Export JSON',
            icon: Icon(Icons.download),
            onPressed: people.isEmpty ? null : _exportToJson,
          ),
          IconButton(
            tooltip: 'Import JSON',
            icon: Icon(Icons.upload),
            onPressed: _importFromJson,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _addPerson,
                  child: Text('Add Person'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _connectMode = !_connectMode;
                      _firstConnectId = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _connectMode ? Colors.redAccent : null,
                  ),
                  child:
                      Text(_connectMode ? 'Cancel Connect' : 'Connect'),
                ),
                ElevatedButton(
                  onPressed: _centerAll,
                  child: Text('Center'),
                ),
                // Font family picker
                DropdownButton<String>(
                  value: _fontFamily,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _fontFamily = val;
                      });
                    }
                  },
                  items: [
                    'Roboto',
                    'Open Sans',
                    'Lato',
                    'Montserrat',
                    'Merriweather',
                    'Arial',
                    'Courier New',
                  ]
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f, style: TextStyle(fontFamily: f)),
                          ))
                      .toList(),
                ),
                // Font size input
                SizedBox(
                  width: 60,
                  child: TextField(
                    decoration:
                        InputDecoration(labelText: 'Font Size'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onSubmitted: (txt) {
                      final v = double.tryParse(txt);
                      if (v != null && v > 0) {
                        setState(() {
                          _fontSize = v;
                        });
                      }
                    },
                  ),
                ),
                // Name color picker
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Name Color'),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDialog<Color>(
                          context: context,
                          builder: (ctx) {
                            Color tmp = _nameColor;
                            return AlertDialog(
                              title: Text('Pick Name Color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  initialColor: tmp,
                                  onColorChanged: (c) => tmp = c,
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(null),
                                    child: Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(tmp),
                                  child: Text('Select'),
                                ),
                              ],
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _nameColor = picked;
                          });
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _nameColor,
                          border: Border.all(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                // Date color picker
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Date Color'),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDialog<Color>(
                          context: context,
                          builder: (ctx) {
                            Color tmp = _dateColor;
                            return AlertDialog(
                              title: Text('Pick Date Color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  initialColor: tmp,
                                  onColorChanged: (c) => tmp = c,
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(null),
                                    child: Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(tmp),
                                  child: Text('Select'),
                                ),
                              ],
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _dateColor = picked;
                          });
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _dateColor,
                          border: Border.all(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: Colors.grey),
          // Canvas area
          Expanded(
            child: Stack(
              children: [
                // Draw connector lines under everything
                _buildConnectorPainter(),
                // Draw each PersonNode
                ...people.map((p) {
                  final isSelected = (p.id == _selectedPersonId);
                  return PersonNode(
                    key: ValueKey(p.id),
                    person: p,
                    allPeople: people,
                    onUpdate: (updated) {
                      // If update came from selecting:
                      if (_selectedPersonId == updated.id) {
                        setState(() {
                          // Either drag or just a tap: we simply replace the person in the list
                          final idx = people.indexWhere((x) => x.id == updated.id);
                          if (idx >= 0) people[idx] = updated;
                        });
                      } else {
                        // A tap to select:
                        setState(() {
                          _selectedPersonId = updated.id;
                        });
                      }
                    },
                    isSelected: isSelected,
                    fontFamily: _fontFamily,
                    fontSize: _fontSize,
                    nameColor: _nameColor,
                    dateColor: _dateColor,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter to draw connectors (parent→child and spouse lines).
class ConnectorPainter extends CustomPainter {
  final List<Person> people;
  ConnectorPainter(this.people);

  @override
  void paint(Canvas canvas, Size size) {
    final paintParent = Paint()
      ..color = Colors.black54
      ..strokeWidth = 2.0;
    final paintSpouse = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final p in people) {
      final from = p.position;

      // Draw parent→child: mother
      if (p.motherId != null) {
        final mom = people.firstWhere(
            (x) => x.id == p.motherId,
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
        if (mom.id.isNotEmpty) {
          canvas.drawLine(mom.position, from, paintParent);
        }
      }
      // father→child
      if (p.fatherId != null) {
        final dad = people.firstWhere(
            (x) => x.id == p.fatherId,
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
        if (dad.id.isNotEmpty) {
          canvas.drawLine(dad.position, from, paintParent);
        }
      }
      // spouse line (draw a dashed/solid line horizontally)
      if (p.spouseId != null) {
        final spouse = people.firstWhere(
            (x) => x.id == p.spouseId,
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
          // Draw straight line between centers
          canvas.drawLine(from, spouse.position, paintSpouse);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter old) {
    return old.people != people;
  }
}

/// A simple color picker.
/// You can replace this with any color‐picker package if desired.
/// This widget lets you choose a color via sliders for R/G/B.
class ColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  const ColorPicker({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late double r, g, b;
  @override
  void initState() {
    super.initState();
    r = widget.initialColor.red.toDouble();
    g = widget.initialColor.green.toDouble();
    b = widget.initialColor.blue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSlider('R', r, (val) {
          setState(() => r = val);
          widget.onColorChanged(Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt()));
        }),
        _buildSlider('G', g, (val) {
          setState(() => g = val);
          widget.onColorChanged(Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt()));
        }),
        _buildSlider('B', b, (val) {
          setState(() => b = val);
          widget.onColorChanged(Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt()));
        }),
      ],
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 24, child: Text(label)),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            divisions: 255,
            value: value,
            onChanged: onChanged,
            activeColor: Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt()),
            label: value.toInt().toString(),
          ),
        ),
      ],
    );
  }
}
