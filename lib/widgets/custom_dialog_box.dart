import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'app_reusable_text.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? negativeButtonText;
  final String? positiveButtonText;
  final VoidCallback? onNegativePressed;
  final VoidCallback? onPositivePressed;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? messageColor;
  final Color? negativeButtonColor;
  final Color? positiveButtonColor;
  final Color? negativeButtonTextColor;
  final Color? positiveButtonTextColor;
  final double borderRadius;
  final double titleFontSize;
  final double messageFontSize;
  final double buttonTextFontSize;
  final EdgeInsetsGeometry contentPadding;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.negativeButtonText = 'No',
    this.positiveButtonText = 'Yes',
    this.onNegativePressed,
    this.onPositivePressed,
    this.backgroundColor,
    this.titleColor,
    this.messageColor,
    this.negativeButtonColor,
    this.positiveButtonColor,
    this.negativeButtonTextColor,
    this.positiveButtonTextColor,
    this.borderRadius = 12.0,
    this.titleFontSize = 20.0,
    this.messageFontSize = 14.0,
    this.buttonTextFontSize = 16.0,
    this.contentPadding = const EdgeInsets.all(
      20.0,
    ), // Padding inside the dialog content
  });

  @override
  Widget build(BuildContext context) {
    final Color defaultBackgroundColor =
        backgroundColor ?? AppColors.backgroundDark; // Dark background
    final Color defaultTitleColor =
        titleColor ?? AppColors.primary; // Red title
    final Color defaultMessageColor =
        messageColor ?? AppColors.surfaceLight; // Muted message
    final Color defaultNegativeButtonColor =
        negativeButtonColor ?? AppColors.primary;
    final Color defaultPositiveButtonColor =
        positiveButtonColor ?? AppColors.primary;
    final Color defaultNegativeButtonTextColor =
        negativeButtonTextColor ?? Colors.white;
    final Color defaultPositiveButtonTextColor =
        positiveButtonTextColor ?? Colors.white;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      backgroundColor: defaultBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(
          24.0,
        ), // Overall padding for the dialog content area
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: defaultTitleColor,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            AppReusableText(
              text: message,
              color: defaultMessageColor,
              fontSize: messageFontSize,
              fontWeight: FontWeight.w400,
              maxLines: 3,
              textAlignment: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onNegativePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: defaultNegativeButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          25.0,
                        ), // Rounded pill shape
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: Text(
                      negativeButtonText!,
                      style: TextStyle(
                        color: defaultNegativeButtonTextColor,
                        fontSize: buttonTextFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPositivePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: defaultPositiveButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          25.0,
                        ), // Rounded pill shape
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: Text(
                      positiveButtonText!,
                      style: TextStyle(
                        color: defaultPositiveButtonTextColor,
                        fontSize: buttonTextFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
