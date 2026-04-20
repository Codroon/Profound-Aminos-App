import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/gorgias_dashboard.dart';
import 'package:woo_management_app/features/reach_ship/presentation/pages/shipment_management_page.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

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
    ShipmentManagementPage(),
    GorgiasDashboard(),
    WordPressPostsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          border: Border(
            top: BorderSide(
              color: AppColors.border.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Iconsax.grid_1_bold,
                label: 'Dashboard',
                index: 0,
              ),
              _buildNavItem(
                icon: Iconsax.truck_outline,
                label: 'Shipping',
                index: 1,
              ),
              _buildNavItem(
                icon: Iconsax.support_outline,
                label: 'Support',
                index: 2,
              ),
              _buildNavItem(
                icon: Iconsax.document_text_outline,
                label: 'WordPress',
                index: 3,
              ),
              _buildNavItem(
                icon: Iconsax.setting_2_outline,
                label: 'Settings',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          AppReusableText(
            text: label,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ],
      ),
    );
  }
}
