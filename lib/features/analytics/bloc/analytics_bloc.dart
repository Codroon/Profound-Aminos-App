import 'package:flutter_bloc/flutter_bloc.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';
import '../repository/analytics_repository.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;
  final Map<int, AnalyticsTabData> _tabDataCache = {};

  // Shared cache — refreshed once per 5-minute window
  List<dynamic>? _ordersCache;      // recent orders
  int? _ordersTotalCache;           // real ALL-time total
  int? _thisMonthOrdersCache;       // real THIS-MONTH total
  int? _totalProductCountCache;     // real ALL-time product total
  double? _allTimeRevenueCache;
  DateTime? _sharedCacheUpdated;

  AnalyticsBloc({required this.repository}) : super(AnalyticsInitial()) {
    on<FetchAnalytics>(_onFetchAnalytics);
  }

  bool get _sharedCacheValid =>
      _sharedCacheUpdated != null &&
      DateTime.now().difference(_sharedCacheUpdated!).inMinutes < 5 &&
      _ordersCache != null &&
      _ordersTotalCache != null &&
      _thisMonthOrdersCache != null &&
      _totalProductCountCache != null &&
      _allTimeRevenueCache != null;

  String _getMonthStartIso() {
    final now = DateTime.now();
    final pad = (int v) => v.toString().padLeft(2, '0');
    return "${now.year}-${pad(now.month)}-01T00:00:00";
  }

  Future<void> _onFetchAnalytics(
      FetchAnalytics event, Emitter<AnalyticsState> emit) async {
    final now = DateTime.now();

    // ── Tab-level cache (5 min TTL) ──────────────────────────────────────────
    final cachedTab = _tabDataCache[event.tabIndex];
    if (cachedTab != null &&
        now.difference(cachedTab.lastUpdated).inMinutes < 5 &&
        _sharedCacheValid) {
      emit(AnalyticsLoaded(
        cachedTab.totalOrders,
        revenue: _allTimeRevenueCache!,
        netSales: cachedTab.netSales,
        percentageChange: cachedTab.percentageChange,
        chartData: cachedTab.chartData,
        products: cachedTab.products,
        orders: cachedTab.orders,
        allOrders: _ordersCache!,
        totalOrderCount: _ordersTotalCache!,
        thisMonthOrderCount: _thisMonthOrdersCache!,
        totalProductCount: _totalProductCountCache!,
        tabIndex: event.tabIndex,
        tabDataCache: Map.from(_tabDataCache),
      ));
      return;
    }

    emit(AnalyticsLoading(tabIndex: event.tabIndex));

    try {
      // ── Date range for selected tab ───────────────────────────────────────
      DateTime start;
      if (event.tabIndex == 0) {
        start = DateTime(now.year, now.month, now.day);
      } else if (event.tabIndex == 1) {
        start = now.subtract(const Duration(days: 7));
      } else {
        start = DateTime(now.year, now.month - 1, now.day);
      }
      final dateMin = start.toIso8601String().split('T')[0];
      final dateMax = now.toIso8601String().split('T')[0];
      final allTimeMin = '${now.year - 15}-01-01'; // 15 years to be sure

      final perPage = (event.tabIndex == 0) ? 10 : 20;

      print('[AnalyticsBloc] Firing parallel requests...');
      final results = await Future.wait([
        // [0] Tab-specific sales report (Daily grouping)
        repository.getSalesReport(dateMin: dateMin, dateMax: dateMax),
        
        // [1] Recent orders
        repository.getOrders(page: 1, perPage: perPage),
        
        // [2] Products
        repository.getProducts(page: 1, perPage: perPage),
        
        // [3] All-time revenue (Yearly grouping to avoid pagination limits)
        if (_sharedCacheValid)
          Future.value(<dynamic>[])
        else
          repository.getSalesReport(dateMin: allTimeMin, dateMax: dateMax, period: 'year'),
        
        // [4] ALL-TIME total count
        if (_sharedCacheValid)
          Future.value(0)
        else
          repository.getOrdersTotalCount(),
        
        // [5] THIS MONTH total count
        if (_sharedCacheValid)
          Future.value(0)
        else
          repository.getOrdersTotalCount(after: _getMonthStartIso()),
        
        // [6] ALL-TIME product total count
        if (_sharedCacheValid)
          Future.value(0)
        else
          repository.getProductsTotalCount(),
      ]);

      final tabSalesReport = results[0] as List<dynamic>;
      _ordersCache = results[1] as List<dynamic>;
      final products = results[2] as List<dynamic>;

      // ── All Time Logic ──────────────────────────────────────────────────
      if (!_sharedCacheValid) {
        final allTimeSalesEntries = results[3] as List<dynamic>;
        
        // SUM all years to get the true total revenue
        _allTimeRevenueCache = 0;
        for (var entry in allTimeSalesEntries) {
          _allTimeRevenueCache = _allTimeRevenueCache! + 
            (double.tryParse(entry['total_sales']?.toString() ?? '0') ?? 0);
        }

        _ordersTotalCache = results[4] as int;
        _thisMonthOrdersCache = results[5] as int;
        _totalProductCountCache = results[6] as int;
        _sharedCacheUpdated = now;
      }

      // ── Tab Logic ───────────────────────────────────────────────────────
      final filteredOrders = _ordersCache!.where((o) {
        final date = DateTime.tryParse(o['date_created'] ?? '') ?? now;
        return date.isAfter(start);
      }).toList();

      double tabRevenue = 0;
      double netSales = 0;
      for (var entry in tabSalesReport) {
        tabRevenue += double.tryParse(entry['total_sales']?.toString() ?? '0') ?? 0;
        netSales += double.tryParse(entry['net_sales']?.toString() ?? '0') ?? 0;
      }

      double sumProductSales = products.fold<double>(
        0,
        (sum, p) => sum + (double.tryParse(p['total_sales']?.toString() ?? '0') ?? 0),
      );

      Map<int, double> revenuePerDay = {for (var i = 1; i <= 7; i++) i: 0};
      for (var o in filteredOrders) {
        final date = DateTime.tryParse(o['date_created'] ?? '') ?? now;
        revenuePerDay[date.weekday] = revenuePerDay[date.weekday]! +
            (double.tryParse(o['total']?.toString() ?? '0') ?? 0);
      }
      final chartData = List<FlSpot>.generate(
          7, (i) => FlSpot(i.toDouble(), revenuePerDay[i + 1] ?? 0));

      _tabDataCache[event.tabIndex] = AnalyticsTabData(
        revenue: tabRevenue,
        netSales: netSales,
        totalOrders: sumProductSales,
        percentageChange: 0,
        chartData: chartData,
        products: products,
        orders: filteredOrders,
        lastUpdated: now,
      );

      emit(AnalyticsLoaded(
        sumProductSales,
        revenue: _allTimeRevenueCache ?? tabRevenue,
        netSales: netSales,
        percentageChange: 0,
        chartData: chartData,
        products: products,
        orders: filteredOrders,
        allOrders: _ordersCache!,
        totalOrderCount: _ordersTotalCache!,
        thisMonthOrderCount: _thisMonthOrdersCache!,
        totalProductCount: _totalProductCountCache!,
        tabIndex: event.tabIndex,
        tabDataCache: Map.from(_tabDataCache),
      ));
    } catch (e, stack) {
      print('[AnalyticsBloc] Error: $e');
      print('[AnalyticsBloc] Stack: $stack');
      emit(AnalyticsError('Failed to fetch analytics.', tabIndex: event.tabIndex));
    }
  }
}
