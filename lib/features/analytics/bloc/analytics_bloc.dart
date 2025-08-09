import 'package:flutter_bloc/flutter_bloc.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';
import '../repository/analytics_repository.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;
  final Map<int, AnalyticsTabData> _tabDataCache = {};

  AnalyticsBloc({required this.repository}) : super(AnalyticsInitial()) {
    on<FetchAnalytics>(_onFetchAnalytics);
  }

  Future<void> _onFetchAnalytics(
    FetchAnalytics event, Emitter<AnalyticsState> emit) async {
    
    // Check if we have cached data for this tab that's less than 5 minutes old
    final cachedData = _tabDataCache[event.tabIndex];
    final now = DateTime.now();
    
    if (cachedData != null && 
        now.difference(cachedData.lastUpdated).inMinutes < 5) {
      // Use cached data
      emit(AnalyticsLoaded(
        cachedData.totalOrders,
        revenue: cachedData.revenue,
        netSales: cachedData.netSales,
        percentageChange: cachedData.percentageChange,
        chartData: cachedData.chartData,
        products: cachedData.products,
        orders: cachedData.orders,
        allOrders: cachedData.orders, // Use same orders for now
        tabIndex: event.tabIndex,
        tabDataCache: Map.from(_tabDataCache),
      ));
      return;
    }
    
    // Only emit loading for the specific tab
    emit(AnalyticsLoading(tabIndex: event.tabIndex));
    
    try {
      // Calculate date range based on tab
      DateTime start;
      if (event.tabIndex == 0) {
        start = DateTime(now.year, now.month, now.day);
      } else if (event.tabIndex == 1) {
        start = now.subtract(const Duration(days: 7));
      } else {
        start = DateTime(now.year, now.month - 1, now.day);
      }
      
      // Format dates for API
      final dateMin = start.toIso8601String().split('T')[0];
      final dateMax = now.toIso8601String().split('T')[0];
      
      print('[AnalyticsBloc] Fetching sales report with dateMin: $dateMin, dateMax: $dateMax');
      
      final salesReport = await repository.getSalesReport(
        dateMin: dateMin,
        dateMax: dateMax,
      );
      final orders = await repository.getOrders(page: 1, perPage: 100);
      final products = await repository.getProducts(page: 1, perPage: 100);
      
      final filteredOrders = orders.where((o) {
        final date = DateTime.tryParse(o['date_created'] ?? '') ?? now;
        return date.isAfter(start);
      }).toList();
      
      // Calculate revenue and net sales from salesReport (first item)
      double revenue = 0;
      double netSales = 0;
      
      print('[AnalyticsBloc] Sales report received: $salesReport');
      
      if (salesReport.isNotEmpty) {
        revenue =
            double.tryParse(salesReport[0]['total_sales']?.toString() ?? '0') ??
                0;
        netSales =
            double.tryParse(salesReport[0]['net_sales']?.toString() ?? '0') ??
                0;
        print('[AnalyticsBloc] Parsed revenue: $revenue, netSales: $netSales');
      }
      
      // Calculate percentage change (vs previous period)
      double percentageChange = 0;
      
      // Calculate total product sales the same way as WooProductPerformancePage
      double totalOrders = products.fold<double>(
        0,
        (sum, p) =>
            sum +
            (double.tryParse(p['total_sales']?.toString() ?? '0') ?? 0),
      );
      
      // Prepare chart data (e.g., revenue per day)
      Map<int, double> revenuePerDay = {for (var i = 1; i <= 7; i++) i: 0};
      for (var o in filteredOrders) {
        final date = DateTime.tryParse(o['date_created'] ?? '') ?? now;
        final weekday = date.weekday;
        revenuePerDay[weekday] = revenuePerDay[weekday]! +
            (double.tryParse(o['total']?.toString() ?? '0') ?? 0);
      }
      
      final chartData = List<FlSpot>.generate(
          7, (i) => FlSpot(i.toDouble(), revenuePerDay[i + 1] ?? 0));
      
      // Cache the data for this tab
      final tabData = AnalyticsTabData(
        revenue: revenue,
        netSales: netSales,
        totalOrders: totalOrders,
        percentageChange: percentageChange,
        chartData: chartData,
        products: products,
        orders: filteredOrders,
        lastUpdated: now,
      );
      
      _tabDataCache[event.tabIndex] = tabData;
      
      emit(AnalyticsLoaded(
        totalOrders,
        revenue: revenue,
        netSales: netSales,
        percentageChange: percentageChange,
        chartData: chartData,
        products: products,
        orders: filteredOrders,
        allOrders: orders, // Include all orders without filtering
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
