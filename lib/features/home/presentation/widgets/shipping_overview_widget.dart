import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
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

  bool get _isLoading =>
      pending == null && inTransit == null && delivered == null && total == null;

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
        _isLoading ? _buildShimmer() : _buildStats(),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _buildStat(label: 'Pending', value: pending!, color: Colors.orange)),
        const Gap(12),
        // Expanded(child: _buildStat(label: 'In Transit', value: inTransit!, color: Colors.deepPurpleAccent)),
        // const Gap(12),
        Expanded(child: _buildStat(label: 'Fulfilled', value: delivered!, color: Colors.green)),
        const Gap(12),
        Expanded(child: _buildStat(label: 'Total', value: total!, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: const Color(0xFF2D3142),
      child: Row(
        children: List.generate(3, (i) => [
          Expanded(
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (i < 2) const Gap(12),
        ]).expand((w) => w).toList(),
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required int value,
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
            text: value.toString(),
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
