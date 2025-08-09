import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/percent_badge.dart';
import 'gorgias_sale_trend_chart.dart';

class GorgiasSalesTrendCard extends StatelessWidget {
  const GorgiasSalesTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> chartData = [
      FlSpot(0, 1000),
      FlSpot(1, 2000),
      FlSpot(2, 3000),
      FlSpot(3, 1500),
      FlSpot(4, 2500),
      FlSpot(5, 4000), // Dot will be shown here (Saturday)
      FlSpot(6, 3500),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(
              text: 'Sales Trend',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.greyB3,
            ),
            const Gap(25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppReusableText(
                  text: '\$12,345',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
                PercentageBadge(
                  percentageChange: '-21',
                  backgroundColor: AppColors.secondary,
                  textColor: AppColors.surfaceLight,
                ),
              ],
            ),
            const Gap(40),
            SizedBox(
              height: 260,
              child: DailyPerformanceChart(chartData: chartData),
            ),
          ],
        ),
      ),
    );
  }
}
