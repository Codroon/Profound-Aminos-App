import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/gorgias_dashboard.dart';
import 'package:woo_management_app/features/shipping/bloc/shipping_bloc.dart';
import 'package:woo_management_app/features/shipping/presentation/pages/shipping_dashboard_page.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../profile/presentation/pages/profile_page.dart';
import 'package:woo_management_app/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:woo_management_app/features/notifications/bloc/notifications_bloc.dart';
import 'home_page.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;
  bool _badgeCleared = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomePage(),
      BlocProvider(
        create: (context) => ShippingBloc(),
        child: const ShippingDashboardPage(),
      ),
      const GorgiasDashboard(),
      const NotificationsScreen(),
      const ProfilePage(),
    ];
  }

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
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.local_shipping_outlined,
                label: 'Shipping',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.support_agent_outlined,
                label: 'Support',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.notifications_none_outlined,
                label: 'Alerts',
                index: 3,
                isNotification: true,
              ),
              _buildNavItem(
                icon: Icons.settings_outlined,
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
    bool isNotification = false,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color color =
        isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        final previousIndex = _currentIndex;
        setState(() {
          _currentIndex = index;
          if (index == 3) {
            _badgeCleared = true;
          }
        });

        // Mark all as read ONLY when leaving the Alerts tab
        if (previousIndex == 3 && index != 3) {
          context.read<NotificationsBloc>().add(MarkAllNotificationsAsRead());
          setState(() {
            _badgeCleared = false; // Reset badge state for new future notifications
          });
        }
      },
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
              if (isNotification)
                BlocBuilder<NotificationsBloc, NotificationsState>(
                  builder: (context, state) {
                    if (state is NotificationsLoaded && state.unreadCount > 0 && !_badgeCleared) {
                      return Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cardDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
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
