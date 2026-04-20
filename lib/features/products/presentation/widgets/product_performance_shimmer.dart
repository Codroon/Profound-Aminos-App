import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class ProductPerformanceShimmer extends StatelessWidget {
  const ProductPerformanceShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final baseColor = isDark ? AppColors.cardDark : Colors.grey[300]!;
    final highlightColor =
        isDark ? AppColors.backgroundDark.withValues(alpha: 0.5) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Top card shimmer ────────────────────────────────────────────
            _ShimmerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: icon + title + dropdown pill
                  Row(
                    children: [
                      _box(w: 22, h: 22, radius: 4),
                      const Gap(8),
                      _box(w: 80, h: 16, radius: 6),
                      const Spacer(),
                      _box(w: 100, h: 32, radius: 20),
                    ],
                  ),
                  const Gap(20),
                  // "Sold" label
                  _box(w: 40, h: 12, radius: 4),
                  const Gap(8),
                  // Big number
                  _box(w: 120, h: 40, radius: 8),
                  const Gap(24),
                  // Chart area
                  _box(w: double.infinity, h: 140, radius: 12),
                  const Gap(12),
                  // X-axis labels row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      7,
                      (_) => _box(w: 28, h: 10, radius: 4),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(16),

            // ── Bottom card shimmer ─────────────────────────────────────────
            _ShimmerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon + title
                  Row(
                    children: [
                      _box(w: 20, h: 20, radius: 4),
                      const Gap(8),
                      _box(w: 90, h: 14, radius: 4),
                    ],
                  ),
                  const Gap(16),
                  // Tab row
                  Row(
                    children: [
                      _box(w: 60, h: 28, radius: 8),
                      const Gap(8),
                      _box(w: 80, h: 28, radius: 8),
                      const Gap(8),
                      _box(w: 90, h: 28, radius: 8),
                    ],
                  ),
                  const Gap(20),
                  // 3 product rows
                  ...List.generate(3, (_) => _productRowShimmer()),
                  const Gap(16),
                  // Button
                  _box(w: double.infinity, h: 48, radius: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productRowShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _box(w: 52, h: 52, radius: 10),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(w: 140, h: 13, radius: 4),
                const Gap(6),
                _box(w: 80, h: 11, radius: 4),
              ],
            ),
          ),
          _box(w: 36, h: 13, radius: 4),
        ],
      ),
    );
  }

  Widget _box({double? w, required double h, double radius = 8}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final Widget child;
  const _ShimmerCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
