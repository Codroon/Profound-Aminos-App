import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class ProductsListShimmer extends StatelessWidget {
  final int itemCount;
  const ProductsListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final baseColor = isDark ? AppColors.cardDark : Colors.grey[300]!;
    final highlightColor =
        isDark ? AppColors.backgroundDark.withValues(alpha: 0.5) : Colors.grey[100]!;

    // ExcludeSemantics prevents the shimmer from interfering with the semantics tree
    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) => _productRowShimmer(),
        ),
      ),
    );
  }

  Widget _productRowShimmer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Product image placeholder
            _box(w: 60, h: 60, radius: 12),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  _box(w: double.infinity, h: 14, radius: 4),
                  const Gap(8),
                  // Price
                  _box(w: 80, h: 12, radius: 4),
                  const Gap(8),
                  // Stock status
                  _box(w: 60, h: 10, radius: 4),
                ],
              ),
            ),
            const Gap(8),
            // Action icon
            _box(w: 24, h: 24, radius: 12),
          ],
        ),
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

class ProductSearchShimmer extends StatelessWidget {
  const ProductSearchShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final baseColor = isDark ? AppColors.cardDark : Colors.grey[300]!;
    final highlightColor =
        isDark ? AppColors.backgroundDark.withValues(alpha: 0.5) : Colors.grey[100]!;

    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.primary),
              const Gap(8),
              Expanded(
                child: _box(w: double.infinity, h: 14, radius: 4),
              ),
              const Gap(8),
              _box(w: 20, h: 20, radius: 10),
            ],
          ),
        ),
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
