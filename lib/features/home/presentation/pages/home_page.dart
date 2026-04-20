import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../widgets/dashboard_shimmer.dart';
import '../widgets/gorgias_card.dart';
import '../widgets/shipping_overview_widget.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/current_orders_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_event.dart';
import '../../../analytics/bloc/analytics_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Refresh analytics data when home page is opened
    context.read<AnalyticsBloc>().add(const FetchAnalytics(0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const DashboardShimmer();
            }

            String productCount = '0';
            String revenueCount = '\$0.00';
            String monthOrderCount = '0';
            String currentMonthLabel = '';

            if (state is AnalyticsLoaded) {
              final now = DateTime.now();
              // Month name list
              const monthNames = [
                'January',
                'February',
                'March',
                'April',
                'May',
                'June',
                'July',
                'August',
                'September',
                'October',
                'November',
                'December',
              ];
              currentMonthLabel = '${monthNames[now.month - 1]} ${now.year}';

              productCount = state.totalProductCount.toString();
              revenueCount = '\$${state.revenue.toStringAsFixed(0)}';
              monthOrderCount = state.thisMonthOrderCount.toString();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UserAvatarWidget(
                    text: 'Profound Aminos',
                    userImage: 'assets/images/profound_icon.png',
                  ),
                  const Gap(32),
                  AppReusableText(
                    text: 'Dashboard',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          onTap: () {
                            Navigator.pushNamed(context, RouteNames.wooProduct);
                          },
                          icon: Iconsax.tag_outline,
                          title: 'Products',
                          value: productCount,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: StatCard(
                          onTap: () {
                            Navigator.pushNamed(context, RouteNames.analytics);
                          },
                          icon: Iconsax.dollar_circle_bold,
                          title: 'Revenue',
                          value: revenueCount,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Iconsax.message_outline,
                            title: 'WooCommerce \nOrders',
                            value: monthOrderCount,
                            subtitle:
                                currentMonthLabel.isEmpty
                                    ? null
                                    : currentMonthLabel,
                            subtitleColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const Gap(12),
                        const Expanded(child: GorgiasCard()),
                      ],
                    ),
                  ),
                  const Gap(24),
                  const CurrentOrdersWidget(),
                  const Gap(24),
                  const ShippingOverviewWidget(),
                  const Gap(24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
