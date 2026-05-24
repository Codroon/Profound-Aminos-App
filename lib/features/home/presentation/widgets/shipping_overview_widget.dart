import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

class ShippingOverviewWidget extends StatelessWidget {
  final int? pending;
  final int? inTransit;
  final int? delivered;
  final int? total;

  const ShippingOverviewWidget({
    super.key,
    this.pending,
    this.inTransit,
    this.delivered,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppReusableText(
          text: 'Shipping Overview',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: _buildShippingStat(
                label: 'Pending',
                value: (pending ?? 0).toString(),
                color: Colors.orange,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildShippingStat(
                label: 'In Transit',
                value: (inTransit ?? 0).toString(),
                color: Colors.deepPurpleAccent,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildShippingStat(
                label: 'Fulfilled',
                value: (delivered ?? 0).toString(),
                color: Colors.green,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildShippingStat(
                label: 'Total',
                value: (total ?? 0).toString(),
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShippingStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AppReusableText(
            text: value,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          const Gap(4),
          AppReusableText(
            text: label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
