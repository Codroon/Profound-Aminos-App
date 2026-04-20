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

class RevenueAnalyticsCard extends StatefulWidget {
  const RevenueAnalyticsCard({super.key});

  @override
  State<RevenueAnalyticsCard> createState() => _RevenueAnalyticsCardState();
}

class _RevenueAnalyticsCardState extends State<RevenueAnalyticsCard> {
  int selectedTabIndex = 0;
  final Color selectedTabColor = Colors.white;
  final Color unselectedTabColor = const Color(0xFF8B8B9A);
  final tabLabels = const ['Today', 'Last Week', 'Last Months'];

  @override
  void initState() {
    super.initState();
    // Load initial analytics data for the default tab (Today)
    context.read<AnalyticsBloc>().add(FetchAnalytics( selectedTabIndex));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(text: 'Revenue'),
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
                if (state is AnalyticsLoading) {
                  // Only show loading if it's for the current selected tab
                  if (state.tabIndex == selectedTabIndex) {
                    return Center(child: CustomLoadingWidget(text: 'Loading...'));
                  } else {
                    // Show previous data or empty state while other tab is loading
                    return _buildEmptyOrPreviousState();
                  }
                } else if (state is AnalyticsLoaded) {
                  // Check if we have data for the current tab (either current or cached)
                  final currentTabData = state.tabIndex == selectedTabIndex 
                      ? state 
                      : state.tabDataCache[selectedTabIndex];
                      
                  if (currentTabData != null) {
                    final revenue = currentTabData is AnalyticsLoaded 
                        ? currentTabData.revenue 
                        : (currentTabData as AnalyticsTabData).revenue;
                    final netSales = currentTabData is AnalyticsLoaded 
                        ? currentTabData.netSales 
                        : (currentTabData as AnalyticsTabData).netSales;
                    final percentageChange = currentTabData is AnalyticsLoaded 
                        ? currentTabData.percentageChange 
                        : (currentTabData as AnalyticsTabData).percentageChange;
                    final chartData = currentTabData is AnalyticsLoaded 
                        ? currentTabData.chartData 
                        : (currentTabData as AnalyticsTabData).chartData;
                        
                    return Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 200,
                            child: SalesOverviewCard(
                              title: "Revenue",
                              salesAmount: revenue,
                              percentageChange: percentageChange,
                              chartData: chartData,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 200,
                            child: SalesOverviewCard(
                              title: "Net Sales",
                              salesAmount: netSales,
                              percentageChange: percentageChange,
                              chartData: chartData,
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
                } else if (state is AnalyticsError) {
                  return Center(child: Text(state.message));
                }
                return _buildEmptyOrPreviousState();
              },
            ),
            Gap(35),
            CustomButton(text: 'See Reports', onPressed: () {}),
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
              title: "Revenue",
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
              title: "Net Sales",
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
