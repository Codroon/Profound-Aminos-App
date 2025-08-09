import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  final List<String> tabLabels;
  final int selectedTabIndex;
  final Color selectedTabColor;
  final Color unselectedTabColor;
  final Function(int)? onTabChanged;

  const CustomTabBar({
    super.key,
    required this.tabLabels,
    required this.selectedTabIndex,
    required this.selectedTabColor,
    required this.unselectedTabColor,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          tabLabels.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isSelected = selectedTabIndex == index;

            return GestureDetector(
              onTap: () => onTabChanged?.call(index),
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < tabLabels.length - 1 ? 22 : 0,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? selectedTabColor : unselectedTabColor,
                    fontSize: isSelected ? 16 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
