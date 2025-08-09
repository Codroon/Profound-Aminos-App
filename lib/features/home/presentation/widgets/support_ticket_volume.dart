import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/widgets/percent_badge.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/custom_tab_bar.dart';
import 'gogias_donut_chart.dart';

class GorgiasSupportTicketCard extends StatefulWidget {
  const GorgiasSupportTicketCard({super.key});

  @override
  State<GorgiasSupportTicketCard> createState() =>
      _GorgiasSupportTicketCardState();
}

class _GorgiasSupportTicketCardState extends State<GorgiasSupportTicketCard> {
  int selectedTabIndex = 0;
  final Color selectedTabColor = Colors.white;
  final Color unselectedTabColor = AppColors.greyB3;
  final tabLabels = const ['Today', 'Last Week', 'Last Month'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(
              text: 'Support Ticket Volume',
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
            Gap(21),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppReusableText(text: '72'),
                PercentageBadge(
                  percentageChange: 'Open',
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.surfaceLight,
                ),
              ],
            ),
            Gap(16),
            CustomTabBar(
              tabLabels: tabLabels,
              selectedTabIndex: selectedTabIndex,
              selectedTabColor: selectedTabColor,
              unselectedTabColor: unselectedTabColor,
              onTabChanged: (index) {
                setState(() {
                  selectedTabIndex = index;
                });
              },
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }
}
