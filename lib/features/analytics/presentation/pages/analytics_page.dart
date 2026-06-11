import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/features/analytics/models/revenue_period.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_chart_card.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_performance_shimmer.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import '../../bloc/analytics_bloc.dart';
import '../../bloc/analytics_event.dart';
import '../../bloc/analytics_state.dart';

class AnalyticsPage extends StatefulWidget {
  /// Period the chart opens on. The dashboard Revenue card opens it on
  /// [RevenuePeriod.today]; otherwise it defaults to this week.
  final RevenuePeriod initialPeriod;

  const AnalyticsPage({super.key, this.initialPeriod = RevenuePeriod.thisWeek});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late RevenuePeriod _period = widget.initialPeriod;

  @override
  void initState() {
    super.initState();
    // FIX Bug 3: Only dispatch FetchAnalytics here.
    // FetchRevenueReport is now triggered automatically at the end of
    // _onFetchAnalytics in the bloc, so we don't race against the state.
    context
        .read<AnalyticsBloc>()
        .add(FetchAnalytics(0, initialPeriod: widget.initialPeriod));
  }

  void _onPeriodChanged(RevenuePeriod p) {
    setState(() => _period = p);
    context.read<AnalyticsBloc>().add(FetchRevenueReport(p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppbar(title: 'Revenue Performance'),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          // Full shimmer on very first load only
          if (state is AnalyticsInitial) {
            return const RevenuePerformanceShimmer();
          }

          // Full shimmer only when NOT a revenue-only refresh
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
            // FIX Bug 1: read isRevenueLoading directly from state —
            // no context.watch conflict, no stale value
            final isLoadingRevenue = state.isRevenueLoading;

            // FIX Bug 5: use netSales consistently as the displayed revenue
            final revenue = state.revenueReport?.netSales ?? 0.0;
            final chartSpots = state.reportChartSpots ?? [];
            final xLabels = state.reportXLabels ?? [];

            // Keep local _period in sync with what the bloc last resolved
            // (handles the case where bloc triggers the initial period fetch)
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
                    RevenueChartCard(
                      period: displayPeriod,
                      revenue: revenue,
                      chartSpots: chartSpots,
                      xLabels: xLabels,
                      onPeriodChanged: _onPeriodChanged,
                      isLoadingRevenue: isLoadingRevenue,
                    ),
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