import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
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
  double? _allTimeRevenueCache;
  DateTime? _sharedCacheUpdated;

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
      _allTimeRevenueCache != null;

  String _formatDate(DateTime d) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)}';
  }

  // ── Fetch Global Dashboard Data ───────────────────────────────────────────
  Future<void> _onFetchAnalytics(
      FetchAnalytics event, Emitter<AnalyticsState> emit) async {
    final now = DateTime.now();

    if (_tabDataCache[event.tabIndex] != null &&
        now
                .difference(_tabDataCache[event.tabIndex]!.lastUpdated)
                .inMinutes <
            5 &&
        _sharedCacheValid) {
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
        tabIndex: event.tabIndex,
        tabDataCache: Map.from(_tabDataCache),
        isRevenueLoading: true,
      ));
      // Trigger revenue fetch after cache hit
      add(FetchRevenueReport(RevenuePeriod.thisWeek));
      return;
    }

    emit(AnalyticsLoading(tabIndex: event.tabIndex));

    try {
      DateTime start;
      if (event.tabIndex == 0) {
        start = DateTime(now.year, now.month, now.day);
      } else if (event.tabIndex == 1) {
        start = now.subtract(const Duration(days: 7));
      } else {
        start = DateTime(now.year, now.month - 1, now.day);
      }

      final dateMin = _formatDate(start);
      final dateMax = _formatDate(now);
      final allTimeMin = '${now.year - 15}-01-01';
      final perPage = (event.tabIndex == 0) ? 10 : 20;

      final results = await Future.wait([
        repository.getSalesReport(dateMin: dateMin, dateMax: dateMax),
        repository.getOrders(page: 1, perPage: perPage),
        repository.getProducts(page: 1, perPage: perPage),
        if (_sharedCacheValid)
          Future.value(<dynamic>[])
        else
          repository.getSalesReport(
              dateMin: allTimeMin, dateMax: dateMax, period: 'year'),
        if (_sharedCacheValid)
          Future<dynamic>.value(0)
        else
          repository.getOrdersTotalCount(),
        if (_sharedCacheValid)
          Future<dynamic>.value(0)
        else
          repository.getOrdersTotalCount(
              after:
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-01T00:00:00'),
        if (_sharedCacheValid)
          Future<dynamic>.value(0)
        else
          repository.getProductsTotalCount(),
      ]);

      final tabSalesReport = results[0] as List<dynamic>;
      _ordersCache = results[1] as List<dynamic>;
      final products = results[2] as List<dynamic>;

      if (!_sharedCacheValid) {
        final allTimeSales = results[3] as List<dynamic>;
        _allTimeRevenueCache = allTimeSales.fold<double>(
            0,
            (sum, item) =>
                sum +
                (double.tryParse(item['total_sales']?.toString() ?? '0') ??
                    0));
        _ordersTotalCache = results[4] as int;
        _thisMonthOrdersCache = results[5] as int;
        _totalProductCountCache = results[6] as int;
        _sharedCacheUpdated = now;
      }

      final filteredOrders = _ordersCache!.where((o) {
        final date = DateTime.tryParse(o['date_created'] ?? '') ?? now;
        return date.isAfter(start);
      }).toList();

      final double netSales = tabSalesReport.fold<double>(
          0,
          (sum, item) =>
              sum +
              (double.tryParse(item['net_sales']?.toString() ?? '0') ?? 0));

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
        tabIndex: event.tabIndex,
        tabDataCache: Map.from(_tabDataCache),
        // Mark revenue as loading — bloc will trigger fetch next
        isRevenueLoading: true,
      ));

      // Trigger revenue fetch automatically after initial load
      // so there is no race condition from initState
      add(FetchRevenueReport(RevenuePeriod.thisWeek));
    } catch (e) {
      emit(AnalyticsError('Failed to fetch analytics.',
          tabIndex: event.tabIndex));
    }
  }

  // ── Fetch Specific Revenue Report ─────────────────────────────────────────
  Future<void> _onFetchRevenueReport(
      FetchRevenueReport event, Emitter<AnalyticsState> emit) async {
    final currentState = state;

    // Guard: if state is not loaded yet, silently return.
    // This should not happen since we trigger from within _onFetchAnalytics,
    // but kept as a safety net.
    if (currentState is! AnalyticsLoaded) return;

    // Emit isRevenueLoading=true and clear stale data for the old period
    emit(currentState.copyWith(
      isRevenueLoading: true,
      selectedPeriod: Nullable<RevenuePeriod?>(event.period),
      revenueReport: const Nullable<SalesReportModel?>(null),
      reportChartSpots: const Nullable<List<FlSpot>?>(null),
      reportXLabels: const Nullable<List<String>?>(null),
    ));

    try {
      final now = DateTime.now();
      String? dateMin;
      String? dateMax;
      String? period;

      switch (event.period) {
        case RevenuePeriod.today:
          dateMin = _formatDate(now);
          dateMax = _formatDate(now);
          break;
        case RevenuePeriod.thisWeek:
          dateMin = _formatDate(now.subtract(Duration(days: now.weekday - 1)));
          dateMax = _formatDate(now);
          break;
        case RevenuePeriod.thisMonth:
          dateMin = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
          dateMax = _formatDate(now);
          break;
        case RevenuePeriod.thisYear:
          dateMin = '${now.year}-01-01';
          dateMax = _formatDate(now);
          period = 'month';
          break;
        case RevenuePeriod.allTime:
          dateMin = '2010-01-01';
          dateMax = _formatDate(now);
          period = 'year';
          break;
      }

      final reportData = await repository.getSalesReport(
        dateMin: dateMin,
        dateMax: dateMax,
        period: period,
      );

      if (reportData.isEmpty) {
        emit(currentState.copyWith(
          isRevenueLoading: false,
          revenueReport: const Nullable<SalesReportModel?>(null),
          reportChartSpots: Nullable<List<FlSpot>?>(<FlSpot>[]),
          reportXLabels: Nullable<List<String>?>(<String>[]),
          selectedPeriod: Nullable<RevenuePeriod?>(event.period),
        ));
        return;
      }

      SalesReportModel? combinedReport;
      final spots = <FlSpot>[];
      final labels = <String>[];
      int spotIndex = 0;

      for (final item in reportData) {
        final model = SalesReportModel.fromJson(item as Map<String, dynamic>);

        if (combinedReport == null) {
          combinedReport = model;
        } else {
          // Merge multiple response items into one aggregate model
          combinedReport = SalesReportModel(
            totalSales: combinedReport.totalSales + model.totalSales,
            netSales: combinedReport.netSales + model.netSales,
            averageSales: combinedReport.averageSales,
            totalOrders: combinedReport.totalOrders + model.totalOrders,
            totalItems: combinedReport.totalItems + model.totalItems,
            totalTax: combinedReport.totalTax + model.totalTax,
            totalShipping: combinedReport.totalShipping + model.totalShipping,
            totalRefunds: combinedReport.totalRefunds + model.totalRefunds,
            totalDiscount: combinedReport.totalDiscount + model.totalDiscount,
            totalsGroupedBy: combinedReport.totalsGroupedBy,
            totals: {...combinedReport.totals, ...model.totals},
          );
        }

        final sortedDates = model.totals.keys.toList()..sort();
        for (final dateKey in sortedDates) {
          final data = model.totals[dateKey]!;
          spots.add(FlSpot(spotIndex.toDouble(), data.sales));

          final date = DateTime.tryParse(dateKey);
          if (date != null) {
            switch (event.period) {
              case RevenuePeriod.today:
                labels.add('${date.day}/${date.month}');
                break;
              case RevenuePeriod.thisWeek:
                const weekDays = [
                  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                ];
                labels.add(weekDays[date.weekday - 1]);
                break;
              case RevenuePeriod.thisMonth:
                labels.add(date.day.toString());
                break;
              case RevenuePeriod.thisYear:
                const months = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                labels.add(months[date.month - 1]);
                break;
              case RevenuePeriod.allTime:
                labels.add(date.year.toString());
                break;
            }
          } else {
            labels.add(dateKey.split('-').last);
          }

          spotIndex++;
        }
      }

      // Today fallback: totals map may be empty but top-level netSales exists
      if (event.period == RevenuePeriod.today &&
          spots.isEmpty &&
          combinedReport != null) {
        spots.add(FlSpot(0, combinedReport.netSales));
        labels.add('Today');
      }

      emit(currentState.copyWith(
        isRevenueLoading: false,
        revenueReport: Nullable<SalesReportModel?>(combinedReport),
        reportChartSpots: Nullable<List<FlSpot>?>(spots),
        reportXLabels: Nullable<List<String>?>(labels),
        selectedPeriod: Nullable<RevenuePeriod?>(event.period),
      ));
    } catch (_) {
      // On error, stop spinner and show empty — don't crash to full error screen
      emit(currentState.copyWith(
        isRevenueLoading: false,
        revenueReport: const Nullable<SalesReportModel?>(null),
        reportChartSpots: Nullable<List<FlSpot>?>(<FlSpot>[]),
        reportXLabels: Nullable<List<String>?>(<String>[]),
      ));
    }
  }
}