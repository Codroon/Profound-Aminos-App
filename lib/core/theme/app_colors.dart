import 'package:flutter/material.dart';

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);
  
  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  
  static void toggleTheme() {
    themeModeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }
}

class AppColors {
  // Dark Mode Spec provided by user
  static const Color _bgDark = Color(0xFF0F1220);
  static const Color _cardDark = Color(0xFF15182B);
  static const Color _textDark = Color(0xFFEAF0FF);
  static const Color _subtextDark = Color(0xFF98A0B8);
  static const Color _botBarBgDark = Color(0xFF15182B);
  static const List<Color> _buttonGradientDark = [Color(0xFF6C4CF1), Color(0xFF8E6BFF)];
  
  // Light Mode Spec provided by user
  static const Color _bgLight = Color(0xFFF7F8FA);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _textLight = Color(0xFF1F2937);
  static const Color _subtextLight = Color(0xFF6B7280); // standard grey
  static const Color _buttonSolidLight = Color(0xFF6C3BFF);

  // Dynamic getters based on ThemeManager
  static bool get _isDark => ThemeManager.isDarkMode;

  // Primary Colors
  static Color get primary => _isDark ? const Color(0xFF6C4CF1) : _buttonSolidLight;
  static Color get primaryLight => const Color(0xFF8D79F6);
  static Color get primaryDark => const Color(0xFF3B1ABB);

  // Secondary Colors
  static Color get secondary => const Color(0xFFED5A4C);
  static Color get secondaryLight => const Color(0xFFFF9E68);
  static Color get secondaryDark => const Color(0xFFC43A00);
  static Color get amber300 => const Color(0xFFFFD230);

  // Background Colors (Dynamic)
  static Color get backgroundDark => _isDark ? _bgDark : _bgLight;
  static Color get cardDark => _isDark ? _cardDark : _cardLight;
  static Color get backgroundLight => _isDark ? _bgDark : _bgLight;
  static Color get surfaceDark => _isDark ? _cardDark : _cardLight;
  static Color get surfaceLight => _isDark ? _cardDark : _cardLight;
  static Color get greyB3 => _isDark ? _subtextDark : _subtextLight;

  // Game/Theme Accent Colors
  static Color get multiplierGreen => const Color(0xFF009440);
  static Color get chartRed => const Color(0xFFEB4E4E);
  static Color get planeTrail => primary;
  static Color get gridLine => const Color(0xff5a5384);

  // Status Colors
  static Color get success => const Color(0xFF009440);
  static Color get error => const Color(0xFFE53E3E);
  static Color get warning => const Color(0xFFF1E92B);
  static Color get info => const Color(0xFF6294E6);

  // Text Colors (Dynamic)
  static Color get textPrimary => _isDark ? _textDark : _textLight;
  static Color get textSecondary => _isDark ? _subtextDark : _subtextLight;
  static Color get whiteE4 => _isDark ? const Color(0xFFE3E3E4) : _textLight;

  static Color get greyD9 => const Color(0xFFD9D9D9);
  static Color get greyA9 => _isDark ? const Color(0xFF9F9FA9) : _subtextLight;
  static Color get textDisabled => const Color(0xFF53565B);
  static Color get textPrimaryLight => _isDark ? _textDark : _textLight;
  static Color get textSecondaryLight => _isDark ? _subtextDark : _subtextLight;
  static Color get iconColor => _isDark ? _subtextDark : _subtextLight;
  static Color get grey9B => const Color(0xFF9B9B9B);
  static Color get black28 => _isDark ? _bgDark : _bgLight;

  // Border Colors
  static Color get border => _isDark ? const Color(0xFF2D3748) : const Color(0xFFD1D5DB); // grey border
  static Color get borderLight => _isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

  // Gradient Colors
  static List<Color> get primaryGradient => _isDark ? _buttonGradientDark : [_buttonSolidLight, _buttonSolidLight];
  static List<Color> get secondaryGradient => _isDark ? _buttonGradientDark : [_buttonSolidLight, _buttonSolidLight];
  static List<Color> get backgroundGradient => _isDark ? [_bgDark, _bgDark] : [_bgLight, _bgLight];

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF4299E1),
    Color(0xFF48BB78),
    Color(0xFFF6AD55),
    Color(0xFFED64A6),
    Color(0xFF9F7AEA),
  ];
}
