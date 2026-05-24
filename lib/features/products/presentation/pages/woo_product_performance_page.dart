import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/features/products/presentation/widgets/product_chart_card.dart';
import 'package:woo_management_app/features/products/presentation/widgets/product_performance_shimmer.dart';
import 'package:woo_management_app/features/products/presentation/widgets/top_products_card.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_event.dart';
import '../../../analytics/bloc/analytics_state.dart';

class WooProductPerformancePage extends StatefulWidget {
  const WooProductPerformancePage({super.key});

  @override
  State<WooProductPerformancePage> createState() =>
      _WooProductPerformancePageState();
}

class _WooProductPerformancePageState
    extends State<WooProductPerformancePage> {
  ProductPeriod _period = ProductPeriod.thisWeek;

  @override
  void initState() {
    super.initState();
    // Ensure analytics data is loaded
    final bloc = context.read<AnalyticsBloc>();
    if (bloc.state is! AnalyticsLoaded) {
      bloc.add(const FetchAnalytics(0));
    }
  }

  // ── Date-range helpers ────────────────────────────────────────────────────

  DateTime _periodStart(DateTime now) {
    switch (_period) {
      case ProductPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ProductPeriod.thisWeek:
        // Start of current week (Monday)
        return now.subtract(Duration(days: now.weekday - 1));
      case ProductPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ProductPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case ProductPeriod.allTime:
        return DateTime(2000);
    }
  }

  // ── Sold count ────────────────────────────────────────────────────────────

  int _computeSoldCount(List<dynamic> allOrders) {
    final now = DateTime.now();
    final start = _periodStart(now);
    int total = 0;
    for (final order in allOrders) {
      final date = DateTime.tryParse(order['date_created'] ?? '');
      if (date == null || date.isBefore(start)) continue;
      final lineItems = order['line_items'] as List? ?? [];
      for (final item in lineItems) {
        total += int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  // ── Chart data ────────────────────────────────────────────────────────────

  List<FlSpot> _computeChartSpots(List<dynamic> allOrders) {
    final now = DateTime.now();
    final start = _periodStart(now);

    switch (_period) {
      case ProductPeriod.today:
        // 8 buckets of 3 hours: 0–3, 3–6, 6–9, 9–12, 12–15, 15–18, 18–21, 21–24
        final buckets = List<int>.filled(8, 0);
        for (final order in allOrders) {
          final date = DateTime.tryParse(order['date_created'] ?? '');
          if (date == null || !_sameDay(date, now)) continue;
          final bucket = (date.hour / 3).floor().clamp(0, 7);
          for (final item in (order['line_items'] as List? ?? [])) {
            buckets[bucket] +=
                int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          }
        }
        return buckets
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();

      case ProductPeriod.thisWeek:
        // 7 buckets Mon(1)–Sun(7)
        final buckets = List<int>.filled(7, 0);
        for (final order in allOrders) {
          final date = DateTime.tryParse(order['date_created'] ?? '');
          if (date == null || date.isBefore(start)) continue;
          final idx = (date.weekday - 1).clamp(0, 6);
          for (final item in (order['line_items'] as List? ?? [])) {
            buckets[idx] +=
                int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          }
        }
        return buckets
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();

      case ProductPeriod.thisMonth:
        // 4 week buckets within the current month
        final buckets = List<int>.filled(4, 0);
        final firstDay = DateTime(now.year, now.month, 1);
        for (final order in allOrders) {
          final date = DateTime.tryParse(order['date_created'] ?? '');
          if (date == null || date.isBefore(firstDay) ||
              date.month != now.month || date.year != now.year) continue;
          final weekIdx =
              ((date.day - 1) / 7).floor().clamp(0, 3);
          for (final item in (order['line_items'] as List? ?? [])) {
            buckets[weekIdx] +=
                int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          }
        }
        return buckets
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();

      case ProductPeriod.thisYear:
        // 12 month buckets
        final buckets = List<int>.filled(12, 0);
        final yearStart = DateTime(now.year, 1, 1);
        for (final order in allOrders) {
          final date = DateTime.tryParse(order['date_created'] ?? '');
          if (date == null || date.isBefore(yearStart) ||
              date.year != now.year) continue;
          final idx = (date.month - 1).clamp(0, 11);
          for (final item in (order['line_items'] as List? ?? [])) {
            buckets[idx] +=
                int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          }
        }
        return buckets
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
            .toList();

      case ProductPeriod.allTime:
        // Aggregate by year (last 5 years)
        final Map<int, int> byYear = {};
        for (final order in allOrders) {
          final date = DateTime.tryParse(order['date_created'] ?? '');
          if (date == null) continue;
          byYear[date.year] = (byYear[date.year] ?? 0);
          for (final item in (order['line_items'] as List? ?? [])) {
            byYear[date.year] = byYear[date.year]! +
                (int.tryParse(item['quantity']?.toString() ?? '0') ?? 0);
          }
        }
        final years = byYear.keys.toList()..sort();
        return years
            .asMap()
            .entries
            .map((e) =>
                FlSpot(e.key.toDouble(), (byYear[e.value] ?? 0).toDouble()))
            .toList();
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── X-axis labels ─────────────────────────────────────────────────────────

  List<String> _xLabels() {
    final now = DateTime.now();
    switch (_period) {
      case ProductPeriod.today:
        return [
          '12am', '3am', '6am', '9am', '12pm', '3pm', '6pm', '9pm',
        ];
      case ProductPeriod.thisWeek:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case ProductPeriod.thisMonth:
        return ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      case ProductPeriod.thisYear:
        return [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
      case ProductPeriod.allTime:
        // Build from actual data or just last 5 years
        final start = now.year - 4;
        return List.generate(5, (i) => '${start + i}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppbar(title: 'Product Performance'),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          // ── Shimmer while loading ─────────────────────────────────────────
          if (state is AnalyticsLoading || state is AnalyticsInitial) {
            return const ProductPerformanceShimmer();
          }

          // ── Error ─────────────────────────────────────────────────────────
          if (state is AnalyticsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // ── Data ready ────────────────────────────────────────────────────
          if (state is AnalyticsLoaded) {
            final allOrders = state.allOrders;
            final soldCount = _computeSoldCount(allOrders);
            final chartSpots = _computeChartSpots(allOrders);
            final xLabels = _xLabels();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Chart card ──────────────────────────────────────────
                  ProductChartCard(
                    period: _period,
                    soldCount: soldCount,
                    chartSpots: chartSpots,
                    xLabels: xLabels,
                    onPeriodChanged: (p) => setState(() => _period = p),
                  ),
                  const SizedBox(height: 16),

                  // ── Top products card ───────────────────────────────────
                  TopProductsCard(
                    allOrders: allOrders,
                    products: state.products,
                    onViewAll: () {
                      Navigator.pushNamed(context, RouteNames.wooAllProduct);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
