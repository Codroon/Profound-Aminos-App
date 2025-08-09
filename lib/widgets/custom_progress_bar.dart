import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress; // Value from 0.0 to 1.0
  final String value; // Text to display next to the progress bar (e.g., '45')
  final Color color; // Color of the progress bar itself
  final Color backgroundColor; // Color of the background track

  const CustomProgressBar({
    super.key,
    required this.progress,
    this.value = '',
    this.color = Colors.blue, // Default color
    this.backgroundColor = Colors.white, // Default background color
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4.0, // Height of the progress bar
            ),
          ),
        ),
        if (value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
