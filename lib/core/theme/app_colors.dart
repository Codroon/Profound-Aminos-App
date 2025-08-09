import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Updated)
  static const Color primary = Color(0xFF5D2DE6); // New primary color
  static const Color primaryLight = Color(
    0xFF8D79F6,
  ); // Lighter purple (approx.)
  static const Color primaryDark = Color(0xFF3B1ABB); // Darker purple

  // Secondary Colors (can be customized if needed)
  static const Color secondary = Color(0xFFED5A4C);
  static const Color secondaryLight = Color(0xFFFF9E68);
  static const Color secondaryDark = Color(0xFFC43A00);
  static const Color amber300 = Color(0xFFFFD230);

  // Background Colors
  static const Color backgroundDark = Color(0xFF1e1f28);
  static const Color cardDark = Color(0xFF252533);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF2A2B30);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color greyB3 = Color(0xFFB3B3B3);

  // Game/Theme Accent Colors
  static const Color multiplierGreen = Color(0xFF009440);
  static const Color chartRed = Color(0xFFEB4E4E);
  static const Color planeTrail = primary; // Match with primary
  static const Color gridLine = Color(0xff5a5384);

  // Status Colors
  static const Color success = Color(0xFF009440);
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFF1E92B);
  static const Color info = Color(0xFF6294E6);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE1E3E5);
  static const Color whiteE4 = Color(0xFFE3E3E4);

  static const Color greyD9 = Color(0xFFD9D9D9);
  static const Color greyA9 = Color(0xFF9F9FA9);
  static const Color textDisabled = Color(0xFF53565B);
  static const Color textPrimaryLight = Color(0xFF333333);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color iconColor = Color(0xFF666E79);
  static const Color grey9B = Color(0xFF9B9B9B);
  static const Color black28 = Color(0xFF252628);

  // Border Colors
  static const Color border = Color(0xFF2D3748);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Gradient Colors (Updated to reflect purple theme)
  static const List<Color> primaryGradient = [
    Color(0xFFB09FFF),
    Color(0xFF8D79F6),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xffB09FFF),
    Color(0xff8D79F6),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF1D1E23),
    Color(0xFF2A2B30),
  ];

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF4299E1),
    Color(0xFF48BB78),
    Color(0xFFF6AD55),
    Color(0xFFED64A6),
    Color(0xFF9F7AEA),
  ];
}
