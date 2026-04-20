import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_summary_widget.dart';
import 'package:woo_management_app/widgets/custom_button.dart';

import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/custom_loading_widget.dart';
import '../../../../widgets/custom_tab_bar.dart';
import '../../bloc/analytics_bloc.dart';
import '../../bloc/analytics_event.dart';
import '../../bloc/analytics_state.dart';

class OrderAnalyticsCard extends StatefulWidget {
  const OrderAnalyticsCard({super.key});

  @override
  State<OrderAnalyticsCard> createState() => _OrderAnalyticsCardState();
}

class _OrderAnalyticsCardState extends State<OrderAnalyticsCard> {
  int selectedTabIndex = 0;
  final Color selectedTabColor = Colors.white;
  final Color unselectedTabColor = const Color(0xFF8B8B9A);
  final tabLabels = const ['Today', 'Last Week', 'Last Months'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(text: 'Orders'),
            Gap(21),
            CustomTabBar(
              tabLabels: tabLabels,
              selectedTabIndex: selectedTabIndex,
              selectedTabColor: selectedTabColor,
              unselectedTabColor: unselectedTabColor,
              onTabChanged: (index) {
                setState(() {
                  selectedTabIndex = index;
                });
                // Dispatch analytics event with the new tab index
                context.read<AnalyticsBloc>().add(FetchAnalytics( index));
              },
            ),
            Gap(24),
            BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading && state.tabIndex == selectedTabIndex) {
                  return Center(child: CustomLoadingWidget(text: 'Loading...'));
                } else if (state is AnalyticsLoaded) {
                  // Check if we have data for the current tab
                  final currentTabData = state.tabDataCache[selectedTabIndex];
                  
                  if (currentTabData != null) {
                    final totalOrders = currentTabData.chartData.fold<int>(
                      0,
                      (sum, spot) => sum + spot.y.toInt(),
                    );
                    final avgOrderValue =
                        totalOrders > 0 ? currentTabData.revenue / totalOrders : 0.0;
                    return Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 200,
                            child: SalesOverviewCard(
                              title: "Total Orders",
                              salesAmount: totalOrders.toDouble(),
                              percentageChange: currentTabData.percentageChange,
                              chartData: currentTabData.chartData,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 200,
                            child: SalesOverviewCard(
                              title: "Average Order Value",
                              salesAmount: avgOrderValue,
                              percentageChange: currentTabData.percentageChange,
                              chartData: currentTabData.chartData,
                              chartLineColor: const Color(0xff5D2DE6),
                              chartAreaColor: const Color(0xff5D2DE6),
                              percentageChangeBackgroundColor: const Color(
                                0xff5D2DE6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // No data for current tab, show loading
                    return Center(child: CustomLoadingWidget(text: 'Loading...'));
                  }
                } else if (state is AnalyticsError && state.tabIndex == selectedTabIndex) {
                  return Center(child: Text(state.message));
                }
                
                // For other states or when data is not available, show empty state
                return _buildEmptyOrPreviousState();
              },
            ),
            Gap(35),
            CustomButton(text: 'See Reports'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrPreviousState() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 200,
            child: SalesOverviewCard(
              title: "Total Orders",
              salesAmount: 0,
              percentageChange: 0,
              chartData: const [],
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 200,
            child: SalesOverviewCard(
              title: "Average Order Value",
              salesAmount: 0,
              percentageChange: 0,
              chartData: const [],
              chartLineColor: const Color(0xff5D2DE6),
              chartAreaColor: const Color(0xff5D2DE6),
              percentageChangeBackgroundColor: const Color(
                0xff5D2DE6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
