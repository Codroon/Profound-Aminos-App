import 'package:flutter/material.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress; // Value from 0.0 to 1.0
  final String value; // Text to display next to the progress bar (e.g., '45')
  final Color color; // Color of the progress bar itself
  final Color backgroundColor; // Color of the background track
  final double height;

  const CustomProgressBar({
    super.key,
    required this.progress,
    this.value = '',
    this.color = Colors.blue, // Default color
    this.backgroundColor = Colors.white, // Default background color
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: backgroundColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: height, // Height of the progress bar
            ),
          ),
        ),
        if (value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
