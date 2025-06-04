import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_modal.dart';

class PersonNode extends StatefulWidget {
  final Person person;
  final List<Person> allPeople;
  final Function(Person) onUpdate;
  final double fontSize;
  final Color fontColor;
  final String fontFamily;
  final bool isSelected;

  const PersonNode({
    super.key,
    required this.person,
    required this.allPeople,
    required this.onUpdate,
    required this.fontSize,
    required this.fontColor,
    required this.fontFamily,
    this.isSelected = false,
  });

  @override
  State<PersonNode> createState() => _PersonNodeState();
}

class _PersonNodeState extends State<PersonNode> {
  late Offset position;
  bool _isHighlighted = false;

  @override
  void initState() {
    super.initState();
    position = widget.person.position;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - widget.person.radius,
      top: position.dy - widget.person.radius,
      child: GestureDetector(
        onTap: () {
          setState(() => _isHighlighted = !_isHighlighted);
        },
        onDoubleTap: () async {
          await showPersonModal(
            context: context,
            person: widget.person,
            allPeople: widget.allPeople,
            onSave: widget.onUpdate,
          );
          setState(() {});
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
            widget.person.position = position;
            widget.onUpdate(widget.person);
          });
        },
        child: CustomPaint(
          painter: _CirclePainter(
            color: widget.isSelected || _isHighlighted
                ? Colors.yellow
                : Colors.blue,
            radius: widget.person.radius,
          ),
          child: SizedBox(
            width: widget.person.radius * 2,
            height: widget.person.radius * 2 + (widget.fontSize * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Text(
                  widget.person.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: widget.fontColor,
                    fontFamily: widget.fontFamily,
                  ),
                ),
                Text(
                  widget.person.dob,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.fontSize - 2,
                    color: widget.fontColor,
                    fontFamily: widget.fontFamily,
                  ),
                ),
                Text(
                  widget.person.gender,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.fontSize - 4,
                    color: widget.fontColor,
                    fontFamily: widget.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Color color;
  final double radius;

  _CirclePainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.5);
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
