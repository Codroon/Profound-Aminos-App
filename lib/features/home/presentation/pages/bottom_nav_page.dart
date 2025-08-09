import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/gorgias_dashboard.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../profile/presentation/pages/credential_set_up_screen.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../word_press/presentation/pages/word_press_posts_page.dart';
import 'home_page.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomePage(),
    GorgiasDashboard(),
    WordPressPostsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF252533),
          borderRadius: BorderRadius.circular(38),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Iconsax.chart_1_outline,
              label: 'Dashboard',
              index: 0,
              context: context,
            ),
            _buildNavItem(
              icon: Iconsax.support_outline,
              label: 'Support',
              index: 1,
              context: context,
            ),
            _buildNavItem(
              icon: Iconsax.tag_outline,
              label: 'WordPress',
              index: 2,
              context: context,
            ),
            _buildNavItem(
              icon: Iconsax.setting_outline,
              label: 'Profile',
              index: 3,
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color selectedColor = AppColors.primary;
    final Color unselectedColor = AppColors.surfaceLight;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding:
            isSelected
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                : const EdgeInsets.all(0),
        decoration:
            isSelected
                ? BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(38),
                )
                : null,
        child:
            isSelected
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: unselectedColor, size: 24),
                    const SizedBox(width: 8),
                    AppReusableText(
                      text: label,
                      fontSize: 15,
                      color: unselectedColor,
                    ),
                  ],
                )
                : CircleAvatar(
                  radius: 20,
                  backgroundColor: unselectedColor,
                  child: Icon(icon, color: Colors.black, size: 24),
                ),
      ),
    );
  }
}
