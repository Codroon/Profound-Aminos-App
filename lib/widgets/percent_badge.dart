import 'package:flutter/cupertino.dart';

class PercentageBadge extends StatelessWidget {
  final String percentageChange;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const PercentageBadge({
    super.key,
    required this.percentageChange,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Text(
        percentageChange,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
