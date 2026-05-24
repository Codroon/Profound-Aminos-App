import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.data,
    required this.onTap,
    required this.onDismiss,
  });

  static OverlayEntry? _currentEntry;

  static void show({
    required OverlayState overlayState,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required VoidCallback onTap,
  }) {
    // Dismiss the active banner first
    dismiss();

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: InAppNotificationBanner(
              title: title,
              body: body,
              data: data,
              onTap: () {
                dismiss();
                onTap();
              },
              onDismiss: dismiss,
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: -150, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Auto dismiss after 5 seconds
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() async {
    if (mounted) {
      await _animationController.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data['type']?.toString() ?? '';
    final isSupport = type.startsWith('ticket') || type.startsWith('message') || widget.data['channelId'] == 'support_channel';
    final isShipping = type.startsWith('shipment') || type.startsWith('tracking') || widget.data['channelId'] == 'shipping_channel' || type == 'shipping';

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    IconData iconData = Iconsax.shopping_bag_bold;
    Color iconBgColor = const Color(0xFF6B4EFF).withValues(alpha: 0.15); // Deep premium purple background
    Color iconColor = const Color(0xFF9E8BFF);

    if (isSupport) {
      iconData = Iconsax.message_outline;
      iconBgColor = const Color(0xFF00C853).withValues(alpha: 0.15); // Premium green
      iconColor = const Color(0xFF69F0AE);
    } else if (isShipping) {
      iconData = Iconsax.truck_fast_outline;
      iconBgColor = const Color(0xFF00B0FF).withValues(alpha: 0.15); // Premium blue
      iconColor = const Color(0xFF40C4FF);
    }

    // Dynamic adaptive color tokens
    final Color cardBgColor = isDarkMode ? const Color(0xFF1B2030) : Colors.white;
    final Color borderColor = isDarkMode 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.08);
    final Color titleColor = isDarkMode ? Colors.white : const Color(0xFF0F1220);
    final Color bodyColor = isDarkMode ? const Color(0xFF8E92B2) : const Color(0xFF5E6278);
    final Color shadowColor = isDarkMode 
        ? Colors.black.withValues(alpha: 0.4) 
        : Colors.black.withValues(alpha: 0.08);
    final Color chevronColor = isDarkMode ? const Color(0xFF8E92B2) : const Color(0xFF5E6278);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _animationController.value,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -10) {
                  _dismissWithAnimation();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left Circle Icon Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const Gap(12),
                    // Middle titles
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppReusableText(
                            text: widget.title,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                          const Gap(4),
                          AppReusableText(
                            text: widget.body,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: bodyColor,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    // Right Arrow Indicator
                    Icon(
                      Icons.chevron_right_rounded,
                      color: chevronColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
