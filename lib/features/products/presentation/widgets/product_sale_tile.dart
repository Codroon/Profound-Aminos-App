import 'package:flutter/material.dart';
import 'package:woo_management_app/features/products/presentation/widgets/sales_summary_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_reusable_text.dart';

class SalesItemWidget extends StatelessWidget {
  final SalesItem item;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color subtitleColor;
  final VoidCallback? onItemTap;

  const SalesItemWidget({
    super.key,
    required this.item,
    this.iconBackgroundColor = const Color(0xFFFF8A80),
    this.iconColor = const Color(0xFFFF8A80),
    this.subtitleColor = const Color(0xFF8B8B9A),
    this.onItemTap,
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
              // Icon
              Container(
                width: 61,
                height: 61,
                decoration: BoxDecoration(
                  color: iconBackgroundColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: iconColor, size: 48),
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
