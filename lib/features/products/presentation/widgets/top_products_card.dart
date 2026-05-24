import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

/// Period options for the bottom "Top Products" card tabs.
enum TopProductsPeriod { today, lastWeek, lastMonth }

class TopProductsCard extends StatefulWidget {
  /// All orders from the bloc — used to extract line_items.
  final List<dynamic> allOrders;

  /// Products list — used to look up product images.
  final List<dynamic> products;

  /// Callback when "View all products" is tapped.
  final VoidCallback? onViewAll;

  const TopProductsCard({
    super.key,
    required this.allOrders,
    required this.products,
    this.onViewAll,
  });

  @override
  State<TopProductsCard> createState() => _TopProductsCardState();
}

class _TopProductsCardState extends State<TopProductsCard> {
  TopProductsPeriod _period = TopProductsPeriod.today;

  // Build product image map from products list
  Map<int, String?> get _productImageMap {
    final map = <int, String?>{};
    for (final p in widget.products) {
      final id = int.tryParse(p['id']?.toString() ?? '');
      if (id != null) {
        final images = p['images'] as List?;
        map[id] = (images != null && images.isNotEmpty)
            ? images[0]['src'] as String?
            : null;
      }
    }
    return map;
  }

  List<_ProductSale> _computeTopProducts() {
    final now = DateTime.now();
    DateTime start;
    switch (_period) {
      case TopProductsPeriod.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TopProductsPeriod.lastWeek:
        start = now.subtract(const Duration(days: 7));
        break;
      case TopProductsPeriod.lastMonth:
        start = DateTime(now.year, now.month - 1, now.day);
        break;
    }

    // Aggregate qty by product id from line_items
    final Map<int, _ProductSale> agg = {};
    final imageMap = _productImageMap;

    for (final order in widget.allOrders) {
      final dateStr = order['date_created'] as String? ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null || date.isBefore(start)) continue;

      final lineItems = order['line_items'] as List? ?? [];
      for (final item in lineItems) {
        final productId = int.tryParse(item['product_id']?.toString() ?? '') ?? 0;
        final name = item['name']?.toString() ?? 'Unknown';
        final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
        final price = item['price']?.toString() ?? '0';

        if (agg.containsKey(productId)) {
          agg[productId] = agg[productId]!.copyWith(
            totalQty: agg[productId]!.totalQty + qty,
          );
        } else {
          agg[productId] = _ProductSale(
            productId: productId,
            name: name,
            totalQty: qty,
            price: price,
            imageUrl: imageMap[productId],
          );
        }
      }
    }

    final sorted = agg.values.toList()
      ..sort((a, b) => b.totalQty.compareTo(a.totalQty));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topProducts = _computeTopProducts();

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
              Icon(Iconsax.box_outline, color: AppColors.primary, size: 20),
              const Gap(8),
              AppReusableText(
                text: 'PRODUCTS',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              Spacer(),
              if (widget.onViewAll != null) ...[
                const Gap(12),
                GestureDetector(
                  onTap: widget.onViewAll,
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
                        Iconsax.arrow_right_3_outline,
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
          Row(
            children: [
              _TabChip(
                label: 'Today',
                selected: _period == TopProductsPeriod.today,
                onTap: () => setState(() => _period = TopProductsPeriod.today),
              ),
              const Gap(8),
              _TabChip(
                label: 'Last Week',
                selected: _period == TopProductsPeriod.lastWeek,
                onTap: () =>
                    setState(() => _period = TopProductsPeriod.lastWeek),
              ),
              const Gap(8),
              _TabChip(
                label: 'Last Month',
                selected: _period == TopProductsPeriod.lastMonth,
                onTap: () =>
                    setState(() => _period = TopProductsPeriod.lastMonth),
              ),
            ],
          ),
          const Gap(20),

          // ── Product list ─────────────────────────────────────────────────
          if (topProducts.isEmpty)
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
          else
            ...topProducts.map((p) => _ProductRow(sale: p)),

          // // ── View all link ─────────────────────────────────────────────────
          // if (widget.onViewAll != null) ...[
          //   const Gap(16),
          //   GestureDetector(
          //     onTap: widget.onViewAll,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         AppReusableText(
          //           text: 'View all products',
          //           fontSize: 13,
          //           fontWeight: FontWeight.w600,
          //           color: AppColors.primary,
          //         ),
          //         const Gap(4),
          //         Icon(
          //           Iconsax.arrow_right_3_outline,
          //           color: AppColors.primary,
          //           size: 16,
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
        ],
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

class _ProductRow extends StatelessWidget {
  final _ProductSale sale;
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
                    child: Image.network(
                      sale.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  )
                : Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
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
              text: '×${sale.totalQty}',
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

// ── Data model ──────────────────────────────────────────────────────────────

class _ProductSale {
  final int productId;
  final String name;
  final int totalQty;
  final String price;
  final String? imageUrl;

  const _ProductSale({
    required this.productId,
    required this.name,
    required this.totalQty,
    required this.price,
    this.imageUrl,
  });

  _ProductSale copyWith({int? totalQty}) => _ProductSale(
        productId: productId,
        name: name,
        totalQty: totalQty ?? this.totalQty,
        price: price,
        imageUrl: imageUrl,
      );
}
