import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;
  final Color textColor;
  final double borderRadius;
  final double fontSize;

  const ActionButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    required this.textColor,
    required this.borderRadius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
      ),
      child: Row(
        spacing: 3,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(color: textColor, fontSize: fontSize)),
          SizedBox(
            width: 5.0,
            height: 25.0,
            child: VerticalDivider(
              color: Colors.white,
              width: 0.5,
              thickness: 0.5,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: textColor,
            size: fontSize * 1.2,
          ),
        ],
      ),
    );
  }
}
