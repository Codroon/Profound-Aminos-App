import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/custom_tab_bar.dart';
import 'gogias_donut_chart.dart';

class GorgiasRevenueCard extends StatefulWidget {
  const GorgiasRevenueCard({super.key});

  @override
  State<GorgiasRevenueCard> createState() => _GorgiasRevenueCardState();
}

class _GorgiasRevenueCardState extends State<GorgiasRevenueCard> {
  int selectedTabIndex = 0;
  final tabLabels = const ['Today', 'Last Week', 'Last Month'];

  Color get selectedTabColor => AppColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(
              text: 'Revenue',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
            Gap(21),
            CustomTabBar(
              tabLabels: tabLabels,
              selectedTabIndex: selectedTabIndex,
              selectedTabColor: selectedTabColor,
              unselectedTabColor: AppColors.greyB3,
              onTabChanged: (index) {
                setState(() {
                  selectedTabIndex = index;
                });
              },
            ),
            const Gap(40),
            OrderDonutChart(
              total: 38293,
              values: {'Processed': 12000, 'Shipped': 15000, 'Pending': 11293},
              colors: {
                'Processed': const Color(0xFF6B2CF5),
                'Shipped': const Color(0xFF5B1EA3),
                'Pending': const Color(0xFF9F2BFC),
              },
            ),
          ],
        ),
      ),
    );
  }
}
