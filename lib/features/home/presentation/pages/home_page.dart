import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/di/injection_container.dart' as di;
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/auth/presentation/pages/admin_login_screen.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/custom_button.dart';

import '../../../reach_ship/presentation/pages/reach_ship_main_page.dart';
import '../widgets/gorgias_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/current_orders_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_event.dart';
import '../../../analytics/bloc/analytics_state.dart';
import '../../../analytics/repository/analytics_repository.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),

          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatarWidget(
                    text: 'Profound Aminos',
                    userImage: 'assets/images/profound_icon.png',
                  ),
                ],
              ),
              const Gap(20),
              AppReusableText(
                text: 'Dashboard',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.greyB3,
              ),
              const Gap(12),
              BlocBuilder<AnalyticsBloc, AnalyticsState>(
                builder: (context, state) {
                  String productCount = '-';
                  String revenue = '-';
                  if (state is AnalyticsLoaded) {
                    productCount = state.products.length.toString();
                    revenue = '\$${state.revenue.toStringAsFixed(2)}';
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          onTap: () {
                            Navigator.pushNamed(context, RouteNames.wooProduct);
                          },
                          icon: Iconsax.tag_outline,
                          title: 'Products',
                          value: productCount,
                        ),
                      ),
                      const Gap(4),
                      Expanded(
                        child: StatCard(
                          onTap: () {
                            Navigator.pushNamed(context, RouteNames.analytics);
                          },
                          icon: Iconsax.dollar_circle_bold,
                          title: 'Revenue',
                          value: revenue,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Gap(12),

              Row(
                children: [
                  BlocBuilder<AnalyticsBloc, AnalyticsState>(
                    builder: (context, state) {
                      String wooOrders = '-';
                      if (state is AnalyticsLoaded) {
                        // Show total order count (all orders), same as product performance page
                        wooOrders = state.orders.length.toString();
                      }
                      return Expanded(
                        flex: 3,
                        child: StatCard(
                          icon: Iconsax.support_outline,
                          title: 'WooCommerce \nOrders',
                          value: wooOrders,
                        ),
                      );
                    },
                  ),
                  const Gap(4),
                  const Expanded(
                    flex: 2,
                    child: GorgiasCard(), // Dedicated widget for Gorgias
                  ),
                ],
              ),
              const Gap(20),
              const CurrentOrdersWidget(),
              const Gap(20),
              CustomButton(
                text: 'Tracking',
                height: 46,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReachShipMainPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
