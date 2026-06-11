import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/features/analytics/models/revenue_period.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/orders_chart_card.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_orders_card.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_performance_shimmer.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import '../../bloc/analytics_bloc.dart';
import '../../bloc/analytics_event.dart';
import '../../bloc/analytics_state.dart';

class OrdersDetailsPage extends StatefulWidget {
  const OrdersDetailsPage({super.key});

  @override
  State<OrdersDetailsPage> createState() => _OrdersDetailsPageState();
}

class _OrdersDetailsPageState extends State<OrdersDetailsPage> {
  RevenuePeriod _period = RevenuePeriod.today;

  @override
  void initState() {
    super.initState();
    // FetchAnalytics triggers a FetchRevenueReport(today) automatically once
    // the base data resolves, which populates both revenue and order spots.
    context
        .read<AnalyticsBloc>()
        .add(const FetchAnalytics(0, initialPeriod: RevenuePeriod.today));
  }

  void _onPeriodChanged(RevenuePeriod p) {
    setState(() => _period = p);
    context.read<AnalyticsBloc>().add(FetchRevenueReport(p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppbar(title: 'Orders'),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsInitial) {
            return const RevenuePerformanceShimmer();
          }

          if (state is AnalyticsLoading && !state.isRevenueOnly) {
            return const RevenuePerformanceShimmer();
          }

          if (state is AnalyticsError && state.tabIndex == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<AnalyticsBloc>()
                          .add(const FetchAnalytics(0));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AnalyticsLoaded) {
            final isLoading = state.isRevenueLoading;
            final orderSpots = state.reportOrderSpots ?? [];
            final xLabels = state.reportXLabels ?? [];
            final periodOrders = state.revenueReport?.totalOrders ?? 0;
            final displayPeriod = state.selectedPeriod ?? _period;

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<AnalyticsBloc>()
                    .add(FetchRevenueReport(_period));
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    OrdersChartCard(
                      period: displayPeriod,
                      periodOrders: periodOrders,
                      totalOrders: state.totalOrderCount,
                      chartSpots: orderSpots,
                      xLabels: xLabels,
                      onPeriodChanged: _onPeriodChanged,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    const RevenueOrdersCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }

          return const RevenuePerformanceShimmer();
        },
      ),
    );
  }
}
