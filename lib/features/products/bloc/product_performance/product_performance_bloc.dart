import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:woo_management_app/core/utils/app_logger.dart';
import 'package:woo_management_app/core/utils/store_time.dart';
import 'package:woo_management_app/features/analytics/repository/analytics_repository.dart';
import 'package:woo_management_app/features/products/data/models/top_product_model.dart';

import 'product_performance_event.dart';
import 'product_performance_state.dart';

/// Drives the product-performance page. Both cards source their numbers from
/// the WooCommerce **analytics** endpoints (aggregated server-side over a date
/// range) instead of a single page of recent orders — so every period filter
/// returns correct, range-specific data even on stores with 50k+ orders.
///
/// * Chart "Sold" total + time series → `reports/revenue/stats`
///   (`num_items_sold` totals + per-interval subtotals).
/// * Top-products ranking → `reports/products` ordered by `items_sold`.
class ProductPerformanceBloc
    extends Bloc<ProductPerformanceEvent, ProductPerformanceState> {
  final AnalyticsRepository repository;

  // In-memory cache so toggling periods back and forth is instant within the
  // page session. Repository layer still enforces a 5-minute network TTL.
  final Map<ProductPeriod, _ChartData> _chartCache = {};
  final Map<TopProductsPeriod, List<TopProductModel>> _topCache = {};

  ProductPerformanceBloc({required this.repository})
      : super(const ProductPerformanceState()) {
    on<LoadProductChart>(_onLoadChart);
    on<LoadTopProducts>(_onLoadTopProducts);
    on<ShowMoreTopProducts>(_onShowMoreTopProducts);
  }

  // Reveal the next page of the already-loaded ranking.
  void _onShowMoreTopProducts(
      ShowMoreTopProducts event, Emitter<ProductPerformanceState> emit) {
    final next = (state.topVisibleCount + ProductPerformanceState.topPageSize)
        .clamp(0, state.topProducts.length);
    if (next == state.topVisibleCount) return;
    emit(state.copyWith(topVisibleCount: next));
  }

  // ── Chart ───────────────────────────────────────────────────────────────
  Future<void> _onLoadChart(
      LoadProductChart event, Emitter<ProductPerformanceState> emit) async {
    final period = event.period;

    final cached = _chartCache[period];
    if (cached != null) {
      emit(state.copyWith(
        chartPeriod: period,
        chartLoading: false,
        soldCount: cached.soldCount,
        chartSpots: cached.spots,
        chartLabels: cached.labels,
        clearChartError: true,
      ));
      return;
    }

    emit(state.copyWith(
        chartPeriod: period, chartLoading: true, clearChartError: true));

    try {
      await StoreTime.ensureLoaded();
      // Store wall-clock "now" so chart buckets and the query window align with
      // the store's calendar day (analytics intervals come back in store time).
      final now = StoreTime.now();
      final tz = StoreTime.offsetSuffix;
      final (start, interval) = _chartRange(period, now);

      final stats = await repository.getRevenueStats(
        after: '${_fmt(start)}T00:00:00$tz',
        before: '${_fmt(now)}T23:59:59$tz',
        interval: interval,
        // Cover the full window: 24 hours / 31 days / 12 months — the stats
        // intervals array defaults to only 10 rows otherwise (max is 100).
        perPage: 100,
      );

      final totals = stats['totals'] as Map<String, dynamic>? ?? const {};
      final soldCount =
          int.tryParse(totals['num_items_sold']?.toString() ?? '0') ?? 0;

      final intervals = stats['intervals'] as List<dynamic>? ?? const [];
      final (spots, labels) = _buildChart(period, intervals, now);

      _chartCache[period] = _ChartData(soldCount, spots, labels);

      emit(state.copyWith(
        chartPeriod: period,
        chartLoading: false,
        soldCount: soldCount,
        chartSpots: spots,
        chartLabels: labels,
        clearChartError: true,
      ));
    } catch (e) {
      AppLog.error('ProductPerformance', 'chart load failed: $e');
      emit(state.copyWith(
        chartPeriod: period,
        chartLoading: false,
        soldCount: 0,
        chartSpots: const [],
        chartLabels: const [],
        chartError: 'Failed to load chart.',
      ));
    }
  }

  // ── Top products ──────────────────────────────────────────────────────────
  Future<void> _onLoadTopProducts(
      LoadTopProducts event, Emitter<ProductPerformanceState> emit) async {
    final period = event.period;

    final cached = _topCache[period];
    if (cached != null) {
      emit(state.copyWith(
        topPeriod: period,
        topLoading: false,
        topProducts: cached,
        topVisibleCount: ProductPerformanceState.topPageSize,
        clearTopError: true,
      ));
      return;
    }

    emit(state.copyWith(
        topPeriod: period, topLoading: true, clearTopError: true));

    try {
      await StoreTime.ensureLoaded();
      final now = StoreTime.now();
      final tz = StoreTime.offsetSuffix;
      final start = _topRangeStart(period, now);
      final after = '${_fmt(start)}T00:00:00$tz';
      final before = '${_fmt(now)}T23:59:59$tz';

      // The report is ordered by items_sold desc, so every product that sold in
      // the range comes before the zero-sales ones. Page through (100 at a time)
      // and stop as soon as a zero appears — that gives us *all* sold products
      // without ever walking the full catalogue. Capped for safety.
      const perPage = 100;
      const maxPages = 20;
      final list = <TopProductModel>[];

      for (var page = 1; page <= maxPages; page++) {
        final raw = await repository.getProductsReport(
          after: after,
          before: before,
          orderBy: 'items_sold',
          order: 'desc',
          page: page,
          perPage: perPage,
          extendedInfo: true,
        );

        final parsed = raw
            .whereType<Map>()
            .map((e) =>
                TopProductModel.fromReportJson(Map<String, dynamic>.from(e)))
            .toList();

        final sold = parsed.where((p) => p.itemsSold > 0).toList();
        list.addAll(sold);

        // Reached the unsold tail or the last page → done.
        if (sold.length < parsed.length || parsed.length < perPage) break;
      }

      // Guarantee highest-selling first regardless of how the paged report
      // came back ordered.
      list.sort((a, b) => b.itemsSold.compareTo(a.itemsSold));

      // The analytics report frequently omits `extended_info.image`, leaving
      // rows with the placeholder icon. Backfill thumbnails from the products
      // endpoint — the same source the All Products screen uses (`images[0]`).
      final missing = [
        for (final p in list)
          if (p.imageUrl == null && p.productId > 0) p.productId
      ];
      if (missing.isNotEmpty) {
        try {
          final images = await repository.getProductImages(missing);
          if (images.isNotEmpty) {
            for (var i = 0; i < list.length; i++) {
              final url = images[list[i].productId];
              if (list[i].imageUrl == null && url != null) {
                list[i] = list[i].copyWith(imageUrl: url);
              }
            }
          }
        } catch (e) {
          // Thumbnails are non-critical; keep the ranking even if this fails.
          AppLog.error('ProductPerformance', 'image backfill failed: $e');
        }
      }

      _topCache[period] = list;

      emit(state.copyWith(
        topPeriod: period,
        topLoading: false,
        topProducts: list,
        topVisibleCount: ProductPerformanceState.topPageSize,
        clearTopError: true,
      ));
    } catch (e) {
      AppLog.error('ProductPerformance', 'top products load failed: $e');
      emit(state.copyWith(
        topPeriod: period,
        topLoading: false,
        topProducts: const [],
        topError: 'Failed to load products.',
      ));
    }
  }

  // ── Date-range helpers ────────────────────────────────────────────────────

  /// Range start + analytics interval for each chart period.
  (DateTime, String) _chartRange(ProductPeriod p, DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day);
    switch (p) {
      case ProductPeriod.today:
        return (midnight, 'hour');
      case ProductPeriod.thisWeek:
        return (midnight.subtract(Duration(days: now.weekday - 1)), 'day');
      case ProductPeriod.thisMonth:
        return (DateTime(now.year, now.month, 1), 'day');
      case ProductPeriod.thisYear:
        return (DateTime(now.year, 1, 1), 'month');
      case ProductPeriod.allTime:
        return (DateTime(now.year - 15, 1, 1), 'year');
    }
  }

  DateTime _topRangeStart(TopProductsPeriod p, DateTime now) {
    switch (p) {
      case TopProductsPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case TopProductsPeriod.lastWeek:
        return now.subtract(const Duration(days: 7));
      case TopProductsPeriod.lastMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case TopProductsPeriod.lastYear:
        return DateTime(now.year - 1, now.month, now.day);
    }
  }

  // ── Chart construction ────────────────────────────────────────────────────

  int _items(dynamic interval) {
    final sub = (interval as Map)['subtotals'] as Map? ?? const {};
    return int.tryParse(sub['num_items_sold']?.toString() ?? '0') ?? 0;
  }

  DateTime? _intervalDate(dynamic interval) {
    final raw = (interval as Map)['date_start']?.toString() ?? '';
    // Analytics returns "2026-06-09 14:00:00" — make it ISO-parseable.
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  (List<FlSpot>, List<String>) _buildChart(
      ProductPeriod period, List<dynamic> intervals, DateTime now) {
    switch (period) {
      case ProductPeriod.today:
        // 8 buckets of 3 hours.
        final buckets = List<int>.filled(8, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          buckets[(d.hour ~/ 3).clamp(0, 7)] += _items(iv);
        }
        return (
          _spots(buckets),
          const ['12am', '3am', '6am', '9am', '12pm', '3pm', '6pm', '9pm'],
        );

      case ProductPeriod.thisWeek:
        final buckets = List<int>.filled(7, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          buckets[(d.weekday - 1).clamp(0, 6)] += _items(iv);
        }
        return (
          _spots(buckets),
          const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        );

      case ProductPeriod.thisMonth:
        // 4 week buckets within the month.
        final buckets = List<int>.filled(4, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          buckets[((d.day - 1) ~/ 7).clamp(0, 3)] += _items(iv);
        }
        return (_spots(buckets), const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4']);

      case ProductPeriod.thisYear:
        final buckets = List<int>.filled(12, 0);
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          buckets[(d.month - 1).clamp(0, 11)] += _items(iv);
        }
        return (
          _spots(buckets),
          const [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ],
        );

      case ProductPeriod.allTime:
        // Aggregate by year, labels driven by the actual data.
        final byYear = <int, int>{};
        for (final iv in intervals) {
          final d = _intervalDate(iv);
          if (d == null) continue;
          byYear[d.year] = (byYear[d.year] ?? 0) + _items(iv);
        }
        final years = byYear.keys.toList()..sort();
        if (years.isEmpty) return (const <FlSpot>[], const <String>[]);
        final spots = years
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), (byYear[e.value] ?? 0).toDouble()))
            .toList();
        final labels = years.map((y) => y.toString()).toList();
        // fl_chart needs maxX > minX — pad a single-point series.
        if (spots.length == 1) {
          spots.add(FlSpot(1, spots.first.y));
          labels.add('');
        }
        return (spots, labels);
    }
  }

  List<FlSpot> _spots(List<int> buckets) => buckets
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
      .toList();

  String _fmt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

/// Cached chart payload for one period.
class _ChartData {
  final int soldCount;
  final List<FlSpot> spots;
  final List<String> labels;
  const _ChartData(this.soldCount, this.spots, this.labels);
}
