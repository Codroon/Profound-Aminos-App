import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

class ShippingOverviewWidget extends StatelessWidget {
  const ShippingOverviewWidget({super.key});

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
                value: '24',
                color: Colors.orange,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildShippingStat(
                label: 'In Transit',
                value: '18',
                color: Colors.deepPurpleAccent,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildShippingStat(
                label: 'Fulfilled',
                value: '156',
                color: Colors.green,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildShippingStat(
                label: 'Total',
                value: '198',
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
