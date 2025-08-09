import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/features/products/presentation/widgets/product_performace_value.dart';
import 'package:woo_management_app/widgets/custom_button.dart';

import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/performance_bar_chart.dart';

class ProductPerformanceCard extends StatelessWidget {
  final double revenue;
  final int orders;
  final List<double> weeklyData;
  final int? visitors;
  final double? conversions;

  const ProductPerformanceCard({
    super.key,
    required this.revenue,
    required this.orders,
    required this.weeklyData,
    this.visitors,
    this.conversions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(
              text: 'Performance Overview',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            Gap(25),
            AppReusableText(
              text: '\$${revenue.toStringAsFixed(2)}',
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
            Gap(7),
            AppReusableText(
              text: 'Revenue',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            Gap(15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ProductPerformanceValue(
                  title: orders.toString(),
                  value: 'Total product sales',
                ),
                ProductPerformanceValue(
                  title: visitors?.toString() ?? '-',
                  value: 'Visitors',
                ),
                ProductPerformanceValue(
                  title:
                      conversions != null
                          ? '${conversions!.toStringAsFixed(2)}%'
                          : '-',
                  value: 'Conversions',
                ),
              ],
            ),
            Gap(60),
            WeeklyBarChart(data: weeklyData),
            Gap(20),
            CustomButton(text: 'View all Store Analytics ', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
