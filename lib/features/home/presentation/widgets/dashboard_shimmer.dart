import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeManager.isDarkMode;
    Color baseColor = isDark ? AppColors.cardDark : Colors.grey[300]!;
    Color highlightColor = isDark ? AppColors.backgroundDark.withValues(alpha: 0.5) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 12, color: Colors.white),
                    const Gap(8),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ],
            ),
            const Gap(20),
            Container(width: 100, height: 24, color: Colors.white),
            const Gap(12),
            Row(
              children: [
                Expanded(child: _buildCardShimmer(height: 100)),
                const Gap(8),
                Expanded(child: _buildCardShimmer(height: 100)),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(child: _buildCardShimmer(height: 160)),
                const Gap(8),
                Expanded(child: _buildCardShimmer(height: 160)),
              ],
            ),
            const Gap(20),
            _buildCardShimmer(height: 180),
            const Gap(20),
            Container(width: 150, height: 20, color: Colors.white),
            const Gap(16),
            Row(
              children: List.generate(
                4,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                    child: _buildCardShimmer(height: 80),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardShimmer({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
