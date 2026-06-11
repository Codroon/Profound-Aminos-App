import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:woo_management_app/core/utils/app_logger.dart';
import 'package:woo_management_app/core/utils/store_time.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';
import '../repository/analytics_repository.dart';
import '../models/sales_report_model.dart';
import '../models/revenue_period.dart';
import '../utils/nullable.dart'; // adjust path to wherever you put nullable.dart

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;
  final Map<int, AnalyticsTabData> _tabDataCache = {};

  // Shared cache — refreshed once per 5-minute window
  List<dynamic>? _ordersCache;
  int? _ordersTotalCache;
  int? _thisMonthOrdersCache;
  int? _totalProductCountCache;
  int? _itemsSoldTodayCache;
  double? _allTimeRevenueCache;
  DateTime? _sharedCacheUpdated;

  // Guards against duplicate concurrent fetches. Several screens (home,
  // profile) fire FetchAnalytics on startup; without this each would spawn a
  // full network fan-out, overwhelming the host. The in-flight fetch emits to
  // all listeners, so duplicates can safely be skipped.
  bool _isFetching = false;

  AnalyticsBloc({required this.repository}) : super(AnalyticsInitial()) {
    on<FetchAnalytics>(_onFetchAnalytics);
    on<FetchRevenueReport>(_onFetchRevenueReport);
  }

  bool get _sharedCacheValid =>
      _sharedCacheUpdated != null &&
      DateTime.now().difference(_sharedCacheUpdated!).inMinutes < 5 &&
      _ordersCache != null &&
      _ordersTotalCache != null &&
      _thisMonthOrdersCache != null &&
      _totalProductCountCache != null &&
      _itemsSoldTodayCache != null &&
      _allTimeRevenueCache != null;

  String _formatDate(DateTime d) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)}';
  }

  // ── Fetch Global Dashboard Data ───────────────────────────────────────────
  Future<void> _onFetchAnalytics(
      FetchAnalytics event, Emitter<AnalyticsState> emit) async {
    // Make sure the store's timezone offset is loaded before we build any
    // "today/this week" date window — otherwise we'd query the device's day.
    await StoreTime.ensureLoaded();
    final now = DateTime.now();

    if (_tabDataCache[event.tabIndex] != null &&
        now
                .difference(_tabDataCache[event.tabIndex]!.lastUpdated)
                .inMinutes <
            5 &&
        _sharedCacheValid) {
      AppLog.cache('Analytics',
          'tab ${event.tabIndex} → serving in-memory cache (instant)');
      final cached = _tabDataCache[event.tabIndex]!;
      emit(AnalyticsLoaded(
        cached.totalOrders,
        revenue: _allTimeRevenueCache!,
        netSales: cached.netSales,
        percentageChange: cached.percentageChange,
        chartData: cached.chartData,
        products: cached.products,
        orders: cached.orders,
        allOrders: _ordersCache!,
        totalOrderCount: _ordersTotalCache!,
        thisMonthOrderCount: _thisMonthOrdersCache!,
        totalProductCount: _totalProductCountCache!,
        itemsSoldToday: _itemsSoldTodayCache!,
        tabIndex: event.tabIndex,
        tabDataCache: Map.from(_tabDataCache),
        isRevenueLoading: true,
      ));
      // Trigger revenue fetch after cache hit
      add(FetchRevenueReport(event.initialPeriod));
      return;
    }

    if (_isFetching) {
      AppLog.cache('Analytics',
          'tab ${event.tabIndex} → fetch already in flight, skipping duplicate');
      return;
    }
    _isFetching = true;

    emit(AnalyticsLoading(tabIndex: event.tabIndex));

    final sw = Stopwatch()..start();
    AppLog.net('Analytics',
        'tab ${event.tabIndex} → background refresh START (fetching from network)');

    try {
      // Date windows are built from the store's wall-clock time so "today"
      // matches the store's calendar day, not the device's.
      final storeNow = StoreTime.now();
      DateTime start;
      if (event.tabIndex == 0) {
        start = DateTime(storeNow.year, storeNow.month, storeNow.day);
      } else if (event.tabIndex == 1) {
        start = storeNow.subtract(const Duration(days: 7));
      } else {
        start = DateTime(storeNow.year, storeNow.month - 1, storeNow.day);
      }

      final tz = StoreTime.offsetSuffix;
      final dateMin = _formatDate(start);
      final dateMax = _formatDate(storeNow);
      final allTimeMin = '${storeNow.year - 15}-01-01';
      final perPage = (event.tabIndex == 0) ? 10 : 20;

      final results = await Future.wait([
        repository.getRevenueStats(
          after: '${dateMin}T00:00:00$tz',
          before: '${dateMax}T23:59:59$tz',
          interval: 'day',
        ),
        repository.getOrders(page: 1, perPage: perPage),
        repository.getProducts(page: 1, perPage: perPage),
        if (_sharedCacheValid)
          Future.value(<String, dynamic>{})
        else
          repository.getRevenueStats(
            after: '${allTimeMin}T00:00:00$tz',
            before: '${dateMax}T23:59:59$tz',
            interval: 'year',
          ),
        Future<dynamic>.value(0), // Placeholder to maintain indexes
        if (_sharedCacheValid)
          Future.value(<String, dynamic>{})
        else
          repository.getRevenueStats(
            after: '${_formatDate(storeNow)}T00:00:00$tz',
            before: '${dateMax}T23:59:59$tz',
          ),
        if (_sharedCacheValid)
          Future<dynamic>.value(0)
        else
          repository.getProductsTotalCount(),
      ]);

      final tabRevenueStats = results[0] as Map<String, dynamic>;
      _ordersCache = results[1] as List<dynamic>;
      final products = results[2] as List<dynamic>;

      if (!_sharedCacheValid) {
        final allTimeStats = results[3] as Map<String, dynamic>;
        final allTimeTotals = allTimeStats['totals'] as Map<String, dynamic>? ?? {};
        
        _allTimeRevenueCache = double.tryParse(allTimeTotals['net_revenue']?.toString() ?? '0') ?? 0.0;
        _ordersTotalCache = int.tryParse(allTimeTotals['orders_count']?.toString() ?? '0') ?? 0;
        
        // results[5] is the store-local "today" window, so both the order
        // count and items-sold count below are for today in the store's
        // timezone (not the device's).
        final thisMonthStats = results[5] as Map<String, dynamic>;
        final thisMonthTotals = thisMonthStats['totals'] as Map<String, dynamic>? ?? {};
        _thisMonthOrdersCache = int.tryParse(thisMonthTotals['orders_count']?.toString() ?? '0') ?? 0;
        _itemsSoldTodayCache = int.tryParse(thisMonthTotals['num_items_sold']?.toString() ?? '0') ?? 0;

        _totalProductCountCache = results[6] as int;
        _sharedCacheUpdated = now;
      }

      final filteredOrders = _ordersCache!.where((o) {
        final date = DateTime.tryParse(o['date_created'] ?? '') ?? storeNow;
        return date.isAfter(start);
      }).toList();

      final tabTotals = tabRevenueStats['totals'] as Map<String, dynamic>? ?? {};
      final double netSales = double.tryParse(tabTotals['net_revenue']?.toString() ?? '0') ?? 0.0;

      AppLog.ok('Analytics',
          'tab ${event.tabIndex} → refresh DONE in ${sw.elapsedMilliseconds}ms '
          '(revenue:\$${_allTimeRevenueCache?.toStringAsFixed(0)}, '
          'itemsSoldToday:$_itemsSoldTodayCache, orders:$_ordersTotalCache)');

      emit(AnalyticsLoaded(
        0,
        revenue: _allTimeRevenueCache!,
        netSales: netSales,
        percentageChange: 0,
        chartData: const [],
        products: products,
        orders: filteredOrders,
        allOrders: _ordersCache!,
        totalOrderCount: _ordersTotalCache!,
        thisMonthOrderCount: _thisMonthOrdersCache!,
        totalProductCount: _totalProductCountCache!,
        itemsSoldToday: _itemsSoldTodayCache!,
        tabIndex: event.tabIndex,
        tabDataCache: Map.from(_tabDataCache),
        // Mark revenue as loading — bloc will trigger fetch next
        isRevenueLoading: true,
      ));

      // Trigger revenue fetch automatically after initial load
      // so there is no race condition from initState
      add(FetchRevenueReport(event.initialPeriod));
    } catch (e) {
      AppLog.error('Analytics',
          'tab ${event.tabIndex} → refresh FAILED in ${sw.elapsedMilliseconds}ms: $e');
      emit(AnalyticsError('Failed to fetch analytics.',
          tabIndex: event.tabIndex));
    } finally {
      _isFetching = false;
    }
  }

  // ── Fetch Specific Revenue Report ─────────────────────────────────────────
  Future<void> _onFetchRevenueReport(
      FetchRevenueReport event, Emitter<AnalyticsState> emit) async {
    final currentState = state;

    if (currentState is! AnalyticsLoaded) return;

    emit(currentState.copyWith(
      isRevenueLoading: true,
      selectedPeriod: Nullable<RevenuePeriod?>(event.period),
      revenueReport: const Nullable<SalesReportModel?>(null),
      reportChartSpots: const Nullable<List<FlSpot>?>(null),
      reportOrderSpots: const Nullable<List<FlSpot>?>(null),
      reportXLabels: const Nullable<List<String>?>(null),
    ));

    try {
      await StoreTime.ensureLoaded();
      // Store wall-clock "now" so chart buckets and the query window align with
      // the store's calendar day (the analytics intervals come back in store
      // time too).
      final now = StoreTime.now();
      final tz = StoreTime.offsetSuffix;
      final (start, interval) = _chartRange(event.period, now);

      final reportMap = await repository.getRevenueStats(
        after: '${_formatDate(start)}T00:00:00$tz',
        before: '${_formatDate(now)}T23:59:59$tz',
        interval: interval,
        // Cover the full window: 24 hours / 31 days / 12 months — the stats
        // intervals array defaults to only 10 rows otherwise (max is 100).
        perPage: 100,
      );

      final combinedReport = SalesReportModel.fromAnalyticsJson(reportMap);
      final intervals = reportMap['intervals'] as List<dynamic>? ?? const [];
      // Fixed time buckets (same approach as the product-performance chart) so
      // today/this-week/this-month always render the full detailed range.
      final (spots, orderSpots, labels) =
          _buildChart(event.period, intervals, now);

      emit(currentState.copyWith(
        isRevenueLoading: false,
        revenueReport: Nullable<SalesReportModel?>(combinedReport),
        reportChartSpots: Nullable<List<FlSpot>?>(spots),
        reportOrderSpots: Nullable<List<FlSpot>?>(orderSpots),
        reportXLabels: Nullable<List<String>?>(labels),
        selectedPeriod: Nullable<RevenuePeriod?>(event.period),
      ));
    } catch (_) {
      // On error, stop spinner and show empty — don't crash to full error screen
      emit(currentState.copyWith(
        isRevenueLoading: false,
        revenueReport: const Nullable<SalesReportModel?>(null),
        reportChartSpots: Nullable<List<FlSpot>?>(<FlSpot>[]),
        reportOrderSpots: Nullable<List<FlSpot>?>(<FlSpot>[]),
        reportXLabels: Nullable<List<String>?>(<String>[]),
      ));
    }
  }

  // ── Chart construction (fixed buckets, mirrors product-performance) ─────────

  /// Range start + analytics interval granularity for each chart period.
  (DateTime, String) _chartRange(RevenuePeriod p, DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day);
    switch (p) {
      case RevenuePeriod.today:
        return (midnight, 'hour');
      case RevenuePeriod.thisWeek:
        return (midnight.subtract(Duration(days: now.weekday - 1)), 'day');
      case RevenuePeriod.thisMonth:
        return (DateTime(now.year, now.month, 1), 'day');
      case RevenuePeriod.thisYear:
        return (DateTime(now.year, 1, 1), 'month');
      case RevenuePeriod.allTime:
        return (DateTime(now.year - 15, 1, 1), 'year');
    }
  }

  double _revenueOf(dynamic interval) {
    final sub = (interval as Map)['subtotals'] as Map? ?? const {};
    return double.tryParse(sub['net_revenue']?.toString() ?? '0') ?? 0.0;
  }

  double _ordersOf(dynamic interval) {
    final sub = (interval as Map)['subtotals'] as Map? ?? const {};
    return (int.tryParse(sub['orders_count']?.toString() ?? '0') ?? 0).toDouble();
  }

  DateTime? _intervalDate(dynamic interval) {
    final raw = (interval as Map)['date_start']?.toString() ?? '';
    // Analytics returns "2026-06-09 14:00:00" — make it ISO-parseable.
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  /// Builds revenue spots, order spots, and shared x-axis labels using fixed
  /// buckets so each period renders its full range even when data is sparse.
  (List<FlSpot>, List<FlSpot>, List<String>) _buildChart(
      RevenuePeriod period, List<dynamic> intervals, DateTime now) {
    switch (period) {
      case RevenuePeriod.today:
        // 8 buckets of 3 hours.
        final rev = List<double>.filled(8, 0);
        final ord = List<double>.filled(8, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          final b = (d.hour ~/ 3).clamp(0, 7);
          rev[b] += _revenueOf(iv);
          ord[b] += _ordersOf(iv);
        }
        return (
          _spots(rev),
          _spots(ord),
          const ['12am', '3am', '6am', '9am', '12pm', '3pm', '6pm', '9pm'],
        );

      case RevenuePeriod.thisWeek:
        final rev = List<double>.filled(7, 0);
        final ord = List<double>.filled(7, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          final b = (d.weekday - 1).clamp(0, 6);
          rev[b] += _revenueOf(iv);
          ord[b] += _ordersOf(iv);
        }
        return (
          _spots(rev),
          _spots(ord),
          const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        );

      case RevenuePeriod.thisMonth:
        // 4 week buckets within the month.
        final rev = List<double>.filled(4, 0);
        final ord = List<double>.filled(4, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          final b = ((d.day - 1) ~/ 7).clamp(0, 3);
          rev[b] += _revenueOf(iv);
          ord[b] += _ordersOf(iv);
        }
        return (
          _spots(rev),
          _spots(ord),
          const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'],
        );

      case RevenuePeriod.thisYear:
        final rev = List<double>.filled(12, 0);
        final ord = List<double>.filled(12, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          final b = (d.month - 1).clamp(0, 11);
          rev[b] += _revenueOf(iv);
          ord[b] += _ordersOf(iv);
        }
        return (
          _spots(rev),
          _spots(ord),
          const [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ],
        );

      case RevenuePeriod.allTime:
        // Aggregate by year, labels driven by the actual data.
        final revByYear = <int, double>{};
        final ordByYear = <int, double>{};
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          revByYear[d.year] = (revByYear[d.year] ?? 0) + _revenueOf(iv);
          ordByYear[d.year] = (ordByYear[d.year] ?? 0) + _ordersOf(iv);
        }
        final years = revByYear.keys.toList()..sort();
        if (years.isEmpty) {
          return (const <FlSpot>[], const <FlSpot>[], const <String>[]);
        }
        final revSpots = years
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), revByYear[e.value] ?? 0))
            .toList();
        final ordSpots = years
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), ordByYear[e.value] ?? 0))
            .toList();
        final labels = years.map((y) => y.toString()).toList();
        // fl_chart needs maxX > minX — pad a single-point series.
        if (revSpots.length == 1) {
          revSpots.add(FlSpot(1, revSpots.first.y));
          ordSpots.add(FlSpot(1, ordSpots.first.y));
          labels.add('');
        }
        return (revSpots, ordSpots, labels);
    }
  }

  List<FlSpot> _spots(List<double> buckets) => buckets
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value))
      .toList();
}