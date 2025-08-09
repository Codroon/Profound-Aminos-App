import 'package:flutter/material.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color cardColor;
  final Color iconColor;
  final Color titleColor;
  final Color valueColor;
  final VoidCallback? onTap;
  final double? valueFontSize;
  final double? titleFontSize;
  final double? iconSize;
  final EdgeInsets? padding;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.cardColor = AppColors.cardDark,
    this.iconColor = AppColors.whiteE4,
    this.titleColor = Colors.white70,
    this.valueColor = Colors.white,
    this.onTap,
    this.valueFontSize = 28,
    this.titleFontSize = 15,
    this.iconSize = 28,
    this.padding = const EdgeInsets.all(17.0),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(21.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 6),
                AppReusableText(
                  text: title,
                  maxLines: 2,
                  fontWeight: FontWeight.w500,
                  fontSize: titleFontSize,
                  color: titleColor,
                ),
              ],
            ),

            const SizedBox(height: 4),
            AppReusableText(
              text: value,

              fontWeight: FontWeight.w700,
              fontSize: valueFontSize,
              color: valueColor,
            ),
          ],
        ),
      ),
    );
  }
}
