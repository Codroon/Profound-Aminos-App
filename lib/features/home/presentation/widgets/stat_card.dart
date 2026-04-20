import 'package:flutter/material.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final Color? cardColor;
  final Color? iconColor;
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
    this.subtitle,
    this.subtitleColor,
    this.cardColor,
    this.iconColor,
    this.onTap,
    this.valueFontSize = 28,
    this.titleFontSize = 14,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor ?? AppColors.cardDark,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: iconColor ?? AppColors.textSecondary,
                      size: iconSize,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppReusableText(
                        text: title,
                        maxLines: 2,
                        fontWeight: FontWeight.w500,
                        fontSize: titleFontSize,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppReusableText(
                  text: value,
                  fontWeight: FontWeight.w700,
                  fontSize: valueFontSize,
                  color: AppColors.textPrimary,
                ),
                // Reserve space at the bottom so subtitle doesn't overlap value
                if (subtitle != null) const SizedBox(height: 18),
              ],
            ),

            // Subtitle pinned to bottom-right
            if (subtitle != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: subtitleColor ?? const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AppReusableText(
                      text: subtitle!,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor ?? const Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
