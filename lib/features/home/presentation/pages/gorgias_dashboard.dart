import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';

import '../../../../core/routes/routes_name.dart';
import '../widgets/gorgias_revenue_card.dart';
import '../widgets/gorgias_sales_trend_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/support_ticket_volume.dart';

class Gorgias extends StatelessWidget {
  const Gorgias({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppbar(title: 'Products'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 9,
              children: [
                Expanded(
                  child: StatCard(
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.wooProduct);
                    },
                    padding: EdgeInsets.only(
                      left: 8,
                      top: 10,
                      right: 14,
                      bottom: 12,
                    ),
                    icon: Iconsax.tag_outline,
                    title: 'Products',
                    value: '12',
                    valueFontSize: 26,
                    titleFontSize: 10,
                    iconSize: 24,
                  ),
                ),

                Expanded(
                  child: StatCard(
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.analytics);
                    },
                    padding: EdgeInsets.only(
                      left: 8,
                      top: 10,
                      right: 10,
                      bottom: 12,
                    ),
                    icon: Iconsax.dollar_circle_bold,
                    title: 'Recent \nOrder',
                    value: '5',
                    valueFontSize: 26,
                    titleFontSize: 10,
                    iconSize: 24,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    onTap: () {
                      Navigator.pushNamed(context, RouteNames.analytics);
                    },
                    padding: EdgeInsets.only(
                      left: 8,
                      top: 10,
                      right: 8,
                      bottom: 12,
                    ),
                    icon: Icons.dashboard,
                    title: 'New Blog \nPosts',
                    value: '2',
                    valueFontSize: 26,
                    titleFontSize: 10,
                    iconSize: 24,
                    iconColor: AppColors.whiteE4,
                  ),
                ),
              ],
            ),
            Gap(31),
            GorgiasSalesTrendCard(),
            Gap(31),
            GorgiasRevenueCard(),
            Gap(31),
            GorgiasSupportTicketCard(),
          ],
        ),
      ),
    );
  }
}
