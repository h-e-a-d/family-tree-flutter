import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.settings),
      tooltip: 'Font Settings',
      onSelected: (value) {
        double newSize = fontSize;
        Color newColor = fontColor;
        String newFamily = fontFamily;

        if (value == 'font_inc') newSize += 2;
        if (value == 'font_dec') newSize = (fontSize - 2).clamp(8, 40);
        if (value == 'color_red') newColor = Colors.red;
        if (value == 'color_blue') newColor = Colors.blue;
        if (value == 'color_black') newColor = Colors.black;
        if (value == 'font_arial') newFamily = 'Arial';
        if (value == 'font_times') newFamily = 'Times New Roman';

        onChanged(newSize, newColor, newFamily);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'font_inc', child: Text('Font Size +')),
        PopupMenuItem(value: 'font_dec', child: Text('Font Size -')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'color_red', child: Text('Red Text')),
        PopupMenuItem(value: 'color_blue', child: Text('Blue Text')),
        PopupMenuItem(value: 'color_black', child: Text('Black Text')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'font_arial', child: Text('Arial')),
        PopupMenuItem(value: 'font_times', child: Text('Times New Roman')),
      ],
    );
  }
}
