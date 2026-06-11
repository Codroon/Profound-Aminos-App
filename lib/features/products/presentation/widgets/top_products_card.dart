import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/products/bloc/product_performance/product_performance_event.dart';
import 'package:woo_management_app/features/products/data/models/top_product_model.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

class TopProductsCard extends StatelessWidget {
  final TopProductsPeriod period;
  final List<TopProductModel> products;
  final bool isLoading;
  final ValueChanged<TopProductsPeriod> onPeriodChanged;
  final VoidCallback? onViewAll;

  final int visibleCount;
  final VoidCallback? onLoadMore;

  const TopProductsCard({
    super.key,
    required this.period,
    required this.products,
    required this.onPeriodChanged,
    this.isLoading = false,
    this.onViewAll,
    this.visibleCount = 10,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
              const Gap(8),
              AppReusableText(
                text: 'PRODUCTS',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              const Spacer(),
              if (onViewAll != null) ...[
                const Gap(12),
                GestureDetector(
                  onTap: onViewAll,
                  child: Row(
                    children: [
                      AppReusableText(
                        text: 'View All Products',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      const Gap(2),
                      Icon(
                        Icons.arrow_right_alt,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const Gap(16),

          // ── Tab row ──────────────────────────────────────────────────────
          // Scrollable so the four chips never overflow on narrow screens.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TabChip(
                  label: 'Today',
                  selected: period == TopProductsPeriod.today,
                  onTap: () => onPeriodChanged(TopProductsPeriod.today),
                ),
                const Gap(8),
                _TabChip(
                  label: 'Last Week',
                  selected: period == TopProductsPeriod.lastWeek,
                  onTap: () => onPeriodChanged(TopProductsPeriod.lastWeek),
                ),
                const Gap(8),
                _TabChip(
                  label: 'Last Month',
                  selected: period == TopProductsPeriod.lastMonth,
                  onTap: () => onPeriodChanged(TopProductsPeriod.lastMonth),
                ),
                const Gap(8),
                _TabChip(
                  label: 'Last Year',
                  selected: period == TopProductsPeriod.lastYear,
                  onTap: () => onPeriodChanged(TopProductsPeriod.lastYear),
                ),
              ],
            ),
          ),
          const Gap(20),

          // ── Product list ─────────────────────────────────────────────────
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: AppReusableText(
                  text: 'No sales data for this period',
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else ...[
            ...products
                .take(visibleCount)
                .map((p) => _ProductRow(sale: p)),
            if (visibleCount < products.length)
              _LoadMoreButton(onTap: onLoadMore),
          ],
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _LoadMoreButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppReusableText(
              text: 'Load More',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            const Gap(6),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Shown while a product thumbnail is still downloading.
class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Shown when a product has no image or the image fails to load.
class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.shopping_bag_outlined,
      color: AppColors.primary,
      size: 28,
    );
  }
}

class _ProductRow extends StatelessWidget {
  final TopProductModel sale;
  const _ProductRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: sale.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: sale.imageUrl!,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (_, __) => const _ThumbPlaceholder(),
                      errorWidget: (_, __, ___) => const _ThumbFallback(),
                    ),
                  )
                : const _ThumbFallback(),
          ),
          const Gap(12),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppReusableText(
                  text: sale.name,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  maxLines: 1,
                ),
                const Gap(3),
                AppReusableText(
                  text: '\$${sale.price}',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          // Units sold badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppReusableText(
              text: '×${sale.itemsSold}',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
