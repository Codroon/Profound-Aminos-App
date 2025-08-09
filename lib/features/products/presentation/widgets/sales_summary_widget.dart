import 'package:flutter/material.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/products/presentation/widgets/product_sale_tile.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../../widgets/custom_tab_bar.dart';

class SalesSummary extends StatefulWidget {
  final List<SalesItem> salesData;
  final Color backgroundColor;
  final Color textColor;
  final Color subtitleColor;
  final Color selectedTabColor;
  final Color unselectedTabColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final List<String> tabLabels;
  final Function(int)? onTabChanged;
  final Function(SalesItem)? onItemTap;
  final bool showProductImage;

  const SalesSummary({
    super.key,
    required this.salesData,
    this.backgroundColor = const Color(0xFF2D2D3F),
    this.textColor = Colors.white,
    this.subtitleColor = const Color(0xFF8B8B9A),
    this.selectedTabColor = Colors.white,
    this.unselectedTabColor = const Color(0xFF8B8B9A),
    this.iconBackgroundColor = const Color(0xFFFF8A80),
    this.iconColor = const Color(0xFFFF8A80),
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.tabLabels = const ['Today', 'Last Week', 'Last Months'],
    this.onTabChanged,
    this.onItemTap,
    this.showProductImage = false,
  });

  @override
  State<SalesSummary> createState() => _SalesSummaryState();
}

class _SalesSummaryState extends State<SalesSummary> {
  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar
        CustomTabBar(
          tabLabels: widget.tabLabels,
          selectedTabIndex: selectedTabIndex,
          selectedTabColor: widget.selectedTabColor,
          unselectedTabColor: widget.unselectedTabColor,
          onTabChanged: (index) {
            setState(() {
              selectedTabIndex = index;
            });
            widget.onTabChanged?.call(index);
          },
        ),
        const SizedBox(height: 24),
        // Sales Items List
        ...widget.salesData.map(
          (item) => SalesItemWidget(
            item: item,
            iconBackgroundColor: widget.iconBackgroundColor,
            iconColor: widget.iconColor,
            subtitleColor: widget.subtitleColor,
            onItemTap: () => widget.onItemTap?.call(item),
            showProductImage: widget.showProductImage,
          ),
        ),
      ],
    );
  }
}

class SalesItemWidget extends StatelessWidget {
  final SalesItem item;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color subtitleColor;
  final VoidCallback? onItemTap;
  final bool showProductImage;

  const SalesItemWidget({
    super.key,
    required this.item,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.subtitleColor,
    this.onItemTap,
    this.showProductImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: InkWell(
        onTap: onItemTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Icon or Product Image
              Container(
                width: 61,
                height: 61,
                decoration: BoxDecoration(
                  color: iconBackgroundColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: showProductImage && item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(item.icon, color: iconColor, size: 48),
                        ),
                      )
                    : Icon(item.icon, color: iconColor, size: 48),
              ),
              const SizedBox(width: 10),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppReusableText(
                      text: item.productName,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.greyB3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sales : ${item.formattedSales}',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Sales Count
              AppReusableText(
                text: item.salesCount.toString(),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.greyB3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesItem {
  final String productName;
  final String formattedSales;
  final int salesCount;
  final IconData icon;
  final String? imageUrl;

  const SalesItem({
    required this.productName,
    required this.formattedSales,
    required this.salesCount,
    this.icon = Icons.shopping_bag_outlined,
    this.imageUrl,
  });
}

