import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_chart_card.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_orders_card.dart';
import 'package:woo_management_app/features/analytics/presentation/widgets/revenue_performance_shimmer.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import '../../bloc/analytics_bloc.dart';
import '../../bloc/analytics_event.dart';
import '../../bloc/analytics_state.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  RevenuePeriod _period = RevenuePeriod.thisWeek;

  // Per-period revenue cache
  final Map<RevenuePeriod, double> _revenueCache = {};
  double _periodRevenue = 0;
  bool _loadingRevenue = true;

  @override
  void initState() {
    super.initState();
    context.read<AnalyticsBloc>().add(const FetchAnalytics(0));
  }

  // ── Date range ────────────────────────────────────────────────────────────

  (String dateMin, String dateMax) _dateRange() {
    final now = DateTime.now();
    final pad = (int v) => v.toString().padLeft(2, '0');
    final fmt = (DateTime d) => '${d.year}-${pad(d.month)}-${pad(d.day)}';
    final dateMax = fmt(now);

    String dateMin;
    switch (_period) {
      case RevenuePeriod.today:
        dateMin = fmt(now);
        break;
      case RevenuePeriod.thisWeek:
        dateMin = fmt(now.subtract(Duration(days: now.weekday - 1)));
        break;
      case RevenuePeriod.thisMonth:
        dateMin = '${now.year}-${pad(now.month)}-01';
        break;
      case RevenuePeriod.thisYear:
        dateMin = '${now.year}-01-01';
        break;
      case RevenuePeriod.allTime:
        dateMin = '${now.year - 15}-01-01';
        break;
    }
    return (dateMin, dateMax);
  }

  DateTime _periodStart() {
    final now = DateTime.now();
    switch (_period) {
      case RevenuePeriod.today:
        return DateTime(now.year, now.month, now.day);
      case RevenuePeriod.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1));
      case RevenuePeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case RevenuePeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case RevenuePeriod.allTime:
        return DateTime(2000);
    }
  }

  double _revenueFromOrders(List<dynamic> orders) {
    final start = _periodStart();
    return orders.fold(0.0, (sum, o) {
      final d = DateTime.tryParse(o['date_created'] ?? '');
      if (d == null || d.isBefore(start)) return sum;
      return sum + (double.tryParse(o['total']?.toString() ?? '0') ?? 0);
    });
  }

  // ── Fetch revenue ────────────────────────────────────────────────────────

  Future<void> _loadRevenue(List<dynamic> allOrders) async {
    if (_revenueCache.containsKey(_period)) {
      setState(() {
        _periodRevenue = _revenueCache[_period]!;
        _loadingRevenue = false;
      });
      return;
    }

    setState(() => _loadingRevenue = true);

    double totalRevenue = 0;
    try {
      final (min, max) = _dateRange();
      final repo = context.read<AnalyticsBloc>().repository;
      
      // For allTime, we use yearly grouping to avoid pagination issues
      final p = (_period == RevenuePeriod.allTime) ? 'year' : 'day';
      final report = await repo.getSalesReport(dateMin: min, dateMax: max, period: p);

      if (report.isNotEmpty) {
        // Sum all entries (Daily/Weekly/Monthly) to get the true total
        for (var entry in report) {
          final net = double.tryParse(entry['net_sales']?.toString() ?? '');
          final gross = double.tryParse(entry['total_sales']?.toString() ?? '');
          totalRevenue += net ?? gross ?? 0.0;
        }
      }
    } catch (_) {
      // API failed
    }

    // Fallback if API returned 0
    if (totalRevenue == 0 && allOrders.isNotEmpty) {
      totalRevenue = _revenueFromOrders(allOrders);
    }

    _revenueCache[_period] = totalRevenue;
    if (mounted) {
      setState(() {
        _periodRevenue = totalRevenue;
        _loadingRevenue = false;
      });
    }
  }

  // ── Chart Logic ──────────────────────────────────────────────────────────

  List<FlSpot> _computeChartSpots(List<dynamic> allOrders) {
    final now = DateTime.now();
    switch (_period) {
      case RevenuePeriod.today:
        final b = List<double>.filled(8, 0);
        for (final o in allOrders) {
          final d = DateTime.tryParse(o['date_created'] ?? '');
          if (d == null || !_sameDay(d, now)) continue;
          b[(d.hour / 3).floor().clamp(0, 7)] +=
              double.tryParse(o['total']?.toString() ?? '0') ?? 0;
        }
        return _toSpots(b);
      case RevenuePeriod.thisWeek:
        final ws = now.subtract(Duration(days: now.weekday - 1));
        final b = List<double>.filled(7, 0);
        for (final o in allOrders) {
          final d = DateTime.tryParse(o['date_created'] ?? '');
          if (d == null || d.isBefore(ws)) continue;
          b[(d.weekday - 1).clamp(0, 6)] +=
              double.tryParse(o['total']?.toString() ?? '0') ?? 0;
        }
        return _toSpots(b);
      case RevenuePeriod.thisMonth:
        final ms = DateTime(now.year, now.month, 1);
        final b = List<double>.filled(4, 0);
        for (final o in allOrders) {
          final d = DateTime.tryParse(o['date_created'] ?? '');
          if (d == null || d.isBefore(ms) || d.month != now.month) continue;
          b[((d.day - 1) / 7).floor().clamp(0, 3)] +=
              double.tryParse(o['total']?.toString() ?? '0') ?? 0;
        }
        return _toSpots(b);
      case RevenuePeriod.thisYear:
        final ys = DateTime(now.year, 1, 1);
        final b = List<double>.filled(12, 0);
        for (final o in allOrders) {
          final d = DateTime.tryParse(o['date_created'] ?? '');
          if (d == null || d.isBefore(ys)) continue;
          b[(d.month - 1).clamp(0, 11)] +=
              double.tryParse(o['total']?.toString() ?? '0') ?? 0;
        }
        return _toSpots(b);
      case RevenuePeriod.allTime:
        final Map<int, double> byY = {};
        for (final o in allOrders) {
          final d = DateTime.tryParse(o['date_created'] ?? '');
          if (d == null) continue;
          byY[d.year] = (byY[d.year] ?? 0) + (double.tryParse(o['total']?.toString() ?? '0') ?? 0);
        }
        final years = byY.keys.toList()..sort();
        return years.asMap().entries.map((e) => FlSpot(e.key.toDouble(), byY[e.value] ?? 0)).toList();
    }
  }

  List<FlSpot> _toSpots(List<double> b) => b.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<String> _xLabels() {
    final now = DateTime.now();
    switch (_period) {
      case RevenuePeriod.today: return ['12am', '3am', '6am', '9am', '12pm', '3pm', '6pm', '9pm'];
      case RevenuePeriod.thisWeek: return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case RevenuePeriod.thisMonth: return ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      case RevenuePeriod.thisYear: return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      case RevenuePeriod.allTime: return List.generate(5, (i) => '${now.year - 4 + i}');
    }
  }

  void _onPeriodChanged(RevenuePeriod p, List<dynamic> allOrders) {
    setState(() {
      _period = p;
      _loadingRevenue = true;
    });
    _loadRevenue(allOrders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppbar(title: 'Revenue Performance'),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading || state is AnalyticsInitial) return const RevenuePerformanceShimmer();
          if (state is AnalyticsError) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          if (state is AnalyticsLoaded) {
            final allOrders = state.allOrders;
            if (_loadingRevenue && !_revenueCache.containsKey(_period)) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadRevenue(allOrders));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  RevenueChartCard(
                    period: _period,
                    revenue: _periodRevenue,
                    totalOrders: state.totalOrderCount,
                    chartSpots: _computeChartSpots(allOrders),
                    xLabels: _xLabels(),
                    onPeriodChanged: (p) => _onPeriodChanged(p, allOrders),
                    isLoadingRevenue: _loadingRevenue,
                  ),
                  const SizedBox(height: 16),
                  const RevenueOrdersCard(),
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
