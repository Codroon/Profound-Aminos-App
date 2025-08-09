import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../widgets/custom_loading_widget.dart';
import '../../bloc/product_bloc.dart';
import '../../bloc/product_event.dart';
import '../../bloc/product_state.dart';
import '../../repository/product_repository.dart';
import '../widgets/product_performance_card.dart';
import '../widgets/top_performer_product_summary.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_state.dart';
import 'package:woo_management_app/core/di/injection_container.dart' as di;

class WooProductPerformancePage extends StatelessWidget {
  const WooProductPerformancePage({super.key});

  List<double> _calculateWeeklyOrderData(List<dynamic> orders) {
    final now = DateTime.now();
    final Map<int, int> ordersPerDay = {
      for (var i = 1; i <= 7; i++) i: 0,
    }; // 1=Mon, ..., 7=Sun
    for (var order in orders) {
      final date = DateTime.tryParse(order['date_created'] ?? '') ?? now;
      final weekday = date.weekday; // 1=Mon, ..., 7=Sun
      if (ordersPerDay.containsKey(weekday)) {
        ordersPerDay[weekday] = ordersPerDay[weekday]! + 1;
      }
    }
    final weeklyData = List<double>.generate(
      7,
      (i) => ordersPerDay[i + 1]?.toDouble() ?? 0,
    );
    
    // Debug information
    print('[WooProductPerformancePage] Total orders: ${orders.length}');
    print('[WooProductPerformancePage] Weekly data: $weeklyData');
    print('[WooProductPerformancePage] Orders per day: $ordersPerDay');
    
    return weeklyData;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<ProductBloc>()..add(const FetchProducts()),
        ),
      ],
      child: Scaffold(
        appBar: SharedAppbar(title: 'Product Performance'),
        body: SafeArea(
          child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (context, analyticsState) {
              return BlocBuilder<ProductBloc, ProductState>(
                builder: (context, productState) {
                  if (productState is ProductLoading ||
                      analyticsState is AnalyticsLoading) {
                    return Center(
                      child: CustomLoadingWidget(text: 'Loading... '),
                    );
                  } else if (productState is ProductLoaded &&
                      analyticsState is AnalyticsLoaded) {
                    final products = productState.products;
                    final orders = analyticsState.allOrders;

                    final revenue = products.fold<double>(
                      0,
                      (sum, p) =>
                          sum +
                          (double.tryParse(p['price']?.toString() ?? '0') ?? 0),
                    );

                    // This is calculating total product sales, not order count
                    final totalProductSales = products.fold<int>(
                      0,
                      (sum, p) =>
                          sum +
                          (int.tryParse(p['total_sales']?.toString() ?? '0') ??
                              0),
                    );

                    // For actual order count, use the same source as home page
                    final orderCount = orders.length;
                    print(
                      '[WooProductPerformancePage] Total orders count: $orderCount',
                    );

                    final weeklyData = _calculateWeeklyOrderData(orders);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(12.0),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductPerformanceCard(
                            revenue: revenue,
                            orders: totalProductSales,
                            weeklyData: weeklyData,
                          ),
                          const SizedBox(height: 24),
                          TopPerformerProductSummary(products: products),
                        ],
                      ),
                    );
                  } else if (productState is ProductError ||
                      analyticsState is AnalyticsError) {
                    return Center(
                      child: Text(
                        productState is ProductError
                            ? productState.message
                            : analyticsState is AnalyticsError
                            ? analyticsState.message
                            : 'Error',
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
