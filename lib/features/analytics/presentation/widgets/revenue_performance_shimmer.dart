import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class RevenuePerformanceShimmer extends StatelessWidget {
  const RevenuePerformanceShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final base = isDark ? AppColors.cardDark : Colors.grey[300]!;
    final highlight =
        isDark ? AppColors.backgroundDark.withValues(alpha: 0.5) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Revenue chart card ──────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _box(w: 22, h: 22, r: 4),
                    const Gap(8),
                    _box(w: 80, h: 16, r: 6),
                    const Spacer(),
                    _box(w: 100, h: 32, r: 20),
                  ]),
                  const Gap(20),
                  _box(w: 80, h: 12, r: 4),
                  const Gap(8),
                  _box(w: 150, h: 44, r: 8),
                  const Gap(24),
                  _box(w: double.infinity, h: 140, r: 12),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (_) => _box(w: 28, h: 10, r: 4)),
                  ),
                  const Gap(20),
                  // Total orders stat row
                  Row(children: [
                    _box(w: 90, h: 36, r: 8),
                    const Gap(16),
                    _box(w: 90, h: 36, r: 8),
                  ]),
                ],
              ),
            ),
            const Gap(16),

            // ── Orders card ─────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _box(w: 20, h: 20, r: 4),
                    const Gap(8),
                    _box(w: 70, h: 14, r: 4),
                  ]),
                  const Gap(16),
                  Row(children: [
                    _box(w: 60, h: 28, r: 8),
                    const Gap(8),
                    _box(w: 80, h: 28, r: 8),
                    const Gap(8),
                    _box(w: 90, h: 28, r: 8),
                  ]),
                  const Gap(20),
                  ...List.generate(3, (_) => _orderRowShimmer()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderRowShimmer() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          _box(w: 44, h: 44, r: 10),
          const Gap(12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(w: 120, h: 12, r: 4),
              const Gap(6),
              _box(w: 80, h: 10, r: 4),
            ]),
          ),
          _box(w: 60, h: 14, r: 4),
        ]),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );

  Widget _box({double? w, required double h, double r = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}
