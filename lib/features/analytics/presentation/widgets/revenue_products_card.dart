import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/products/presentation/widgets/sales_summary_widget.dart'
    as summary;
import 'package:woo_management_app/widgets/custom_button.dart';

import '../../../../widgets/app_reusable_text.dart';
import '../../../../widgets/custom_loading_widget.dart';
import '../../../../widgets/custom_tab_bar.dart';
import '../../../../widgets/percent_badge.dart';
import '../../bloc/analytics_bloc.dart';
import '../../bloc/analytics_event.dart';
import '../../bloc/analytics_state.dart';

class RevenueProductsCard extends StatefulWidget {
  const RevenueProductsCard({super.key});

  @override
  State<RevenueProductsCard> createState() => _RevenueProductsCardState();
}

class _RevenueProductsCardState extends State<RevenueProductsCard> {
  int selectedTabIndex = 0;
  final Color selectedTabColor = Colors.white;
  final Color unselectedTabColor = const Color(0xFF8B8B9A);
  final tabLabels = const ['Today', 'Last Week', 'Last Month'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(text: 'Products'),
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
                    final now = DateTime.now();
                    DateTime start, prevStart, prevEnd;
                    if (selectedTabIndex == 0) {
                      // Today
                      start = DateTime(now.year, now.month, now.day);
                      prevStart = start.subtract(const Duration(days: 1));
                      prevEnd = start;
                    } else if (selectedTabIndex == 1) {
                      // Last week
                      start = now.subtract(const Duration(days: 7));
                      prevStart = now.subtract(const Duration(days: 14));
                      prevEnd = now.subtract(const Duration(days: 7));
                    } else {
                      // Last month
                      start = DateTime(now.year, now.month - 1, now.day);
                      prevStart = DateTime(now.year, now.month - 2, now.day);
                      prevEnd = DateTime(now.year, now.month - 1, now.day);
                    }
                    // Current period products
                    final filteredProducts =
                        List<Map<String, dynamic>>.from(currentTabData.products).where((
                          p,
                        ) {
                          final dateStr = p['date_created'] ?? '';
                          final date = DateTime.tryParse(dateStr);
                          if (date == null) return false;
                          return date.isAfter(start);
                        }).toList();
                    filteredProducts.sort(
                      (a, b) =>
                          (int.tryParse(b['total_sales']?.toString() ?? '0') ?? 0)
                              .compareTo(
                                int.tryParse(
                                      a['total_sales']?.toString() ?? '0',
                                    ) ??
                                    0,
                              ),
                    );
                    final topProducts =
                        filteredProducts
                            .take(3)
                            .map(
                              (p) => summary.SalesItem(
                                productName: p['name'] ?? '',
                                formattedSales: '\$${p['price'] ?? '0'}',
                                salesCount:
                                    int.tryParse(
                                      p['total_sales']?.toString() ?? '0',
                                    ) ??
                                    0,
                                icon: Icons.shopping_bag_outlined,
                                imageUrl:
                                    (p['images'] != null &&
                                            p['images'].isNotEmpty)
                                        ? p['images'][0]['src']
                                        : null,
                              ),
                            )
                            .toList();
                    final totalSold = topProducts.fold<int>(
                      0,
                      (sum, p) => sum + p.salesCount,
                    );
                    // Previous period products
                    final prevProducts =
                        List<Map<String, dynamic>>.from(currentTabData.products).where((
                          p,
                        ) {
                          final dateStr = p['date_created'] ?? '';
                          final date = DateTime.tryParse(dateStr);
                          if (date == null) return false;
                          return date.isAfter(prevStart) &&
                              date.isBefore(prevEnd);
                        }).toList();
                    final prevTopProducts =
                        prevProducts
                            .take(3)
                            .map(
                              (p) => summary.SalesItem(
                                productName: p['name'] ?? '',
                                formattedSales: '\$${p['price'] ?? '0'}',
                                salesCount:
                                    int.tryParse(
                                      p['total_sales']?.toString() ?? '0',
                                    ) ??
                                    0,
                                icon: Icons.shopping_bag_outlined,
                                imageUrl:
                                    (p['images'] != null &&
                                            p['images'].isNotEmpty)
                                        ? p['images'][0]['src']
                                        : null,
                              ),
                            )
                            .toList();
                    final prevTotalSold = prevTopProducts.fold<int>(
                      0,
                      (sum, p) => sum + p.salesCount,
                    );
                    // Calculate percent change
                    double percentChange = 0.0;
                    if (prevTotalSold > 0) {
                      percentChange =
                          ((totalSold - prevTotalSold) / prevTotalSold) * 100;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _itemSoldWidget(totalSold, percentChange),
                        Gap(35),
                        if (topProducts.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(
                              maxHeight: 300,
                              minHeight: 100,
                            ),
                            child: CustomScrollView(
                              slivers: [
                                SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final item = topProducts[index];
                                    return summary.SalesItemWidget(
                                      item: item,
                                      onItemTap: () {
                                        print('Tapped on ${item.productName}');
                                      },
                                      iconBackgroundColor: Colors.white,
                                      iconColor: Colors.black,
                                      subtitleColor: Colors.grey,
                                      showProductImage: true,
                                    );
                                  }, childCount: topProducts.length),
                                ),
                              ],
                            ),
                          ),
                        if (topProducts.isEmpty) const SizedBox.shrink(),
                        CustomButton(text: 'See Reports'),
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
          ],
        ),
      ),
    );
  }

  Widget _itemSoldWidget(int totalSold, double percentChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(
              text: totalSold.toString(),
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w400,
            ),
            Gap(4),
            AppReusableText(
              text: 'Item Sold',
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 10,
            ),
          ],
        ),
        PercentageBadge(
          percentageChange: percentChange.toStringAsFixed(1),
          backgroundColor: AppColors.secondary,
          textColor: AppColors.surfaceLight,
          fontSize: 12,
        ),
      ],
    );
  }

  Widget _buildEmptyOrPreviousState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _itemSoldWidget(0, 0.0),
        Gap(35),
        Container(
          constraints: const BoxConstraints(
            maxHeight: 300,
            minHeight: 100,
          ),
          child: const Center(
            child: Text(
              'No products data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        CustomButton(text: 'See Reports'),
      ],
    );
  }
}
