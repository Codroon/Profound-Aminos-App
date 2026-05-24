import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

/// A reusable pagination control bar pinned to the bottom of the screen.
/// Follows light and dark theme via [AppColors].
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final bool hasNextPage;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.hasNextPage,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bool canGoPrevious = currentPage > 1 && !isLoading;
    final bool canGoNext = hasNextPage && !isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            _PaginationButton(
              icon: Iconsax.arrow_left_2_outline,
              onTap: canGoPrevious ? onPrevious : null,
              isEnabled: canGoPrevious,
            ),
            const SizedBox(width: 24),
            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppReusableText(
                text: 'Page $currentPage',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 24),
            // Next button
            _PaginationButton(
              icon: Iconsax.arrow_right_3_outline,
              onTap: canGoNext ? onNext : null,
              isEnabled: canGoNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _PaginationButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isEnabled
              ? AppColors.primary
              : AppColors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
