import 'package:flutter/material.dart';

class SettingsPanel extends StatefulWidget {
  final double fontSize;
  final Color fontColor;
  final String fontFamily;
  final Function(double, Color, String) onChanged;

  const SettingsPanel({
    super.key,
    required this.fontSize,
    required this.fontColor,
    required this.fontFamily,
    required this.onChanged,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late TextEditingController _sizeController;
  late Color _color;
  late String _family;

  final List<String> _families = [
    'Arial',
    'Times New Roman',
    'Roboto',
    'Open Sans',
    'Lato',
  ];

  @override
  void initState() {
    super.initState();
    _sizeController =
        TextEditingController(text: widget.fontSize.toInt().toString());
    _color = widget.fontColor;
    _family = widget.fontFamily;
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: Icon(Icons.settings),
      tooltip: 'Font & Import/Export',
      onSelected: (value) async {
        // Handled inside each menu item via setState
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _sizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Font size'),
                  onSubmitted: (v) {
                    final newSize = double.tryParse(v) ?? widget.fontSize;
                    widget.onChanged(newSize, _color, _family);
                  },
                ),
              ),
              SizedBox(width: 10),
              Text('px'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          child: Row(
            children: [
              Text('Color: '),
              DropdownButton<Color>(
                value: _color,
                items: [
                  DropdownMenuItem(
                    value: Colors.black,
                    child: Text('Black', style: TextStyle(color: Colors.black)),
                  ),
                  DropdownMenuItem(
                    value: Colors.red,
                    child: Text('Red', style: TextStyle(color: Colors.red)),
                  ),
                  DropdownMenuItem(
                    value: Colors.blue,
                    child: Text('Blue', style: TextStyle(color: Colors.blue)),
                  ),
                ],
                onChanged: (c) {
                  if (c == null) return;
                  setState(() => _color = c);
                  widget.onChanged(widget.fontSize, _color, _family);
                },
              ),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          child: Row(
            children: [
              Text('Font: '),
              DropdownButton<String>(
                value: _family,
                items: _families
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, style: TextStyle(fontFamily: f)),
                        ))
                    .toList(),
                onChanged: (f) {
                  if (f == null) return;
                  setState(() => _family = f);
                  widget.onChanged(widget.fontSize, _color, _family);
                },
              ),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 1,
          child: Text('Export JSON'),
          onTap: () {
            // Handled in HomeView via callback
          },
        ),
        PopupMenuItem(
          value: 2,
          child: Text('Import JSON'),
          onTap: () {
            // Handled in HomeView via callback
          },
        ),
      ],
    );
  }
}
