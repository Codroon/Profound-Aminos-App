import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {
  final int tabIndex;
  const AnalyticsLoading({required this.tabIndex});
  
  @override
  List<Object?> get props => [tabIndex];
}

class AnalyticsLoaded extends AnalyticsState {
  final double revenue;
  final double netSales;
  final double totalOrders;
  final double percentageChange;
  final List<FlSpot> chartData;
  final List<dynamic> products;
  final List<dynamic> orders;
  final List<dynamic> allOrders; // Recently fetched orders for display
  final int totalOrderCount;    // Real ALL-TIME total from X-WP-Total header
  final int thisMonthOrderCount; // Real THIS-MONTH total from X-WP-Total header
  final int totalProductCount;   // Real ALL-TIME product count
  final int tabIndex;
  final Map<int, AnalyticsTabData> tabDataCache; // Cache data for each tab
  
  const AnalyticsLoaded(
    this.totalOrders, {
    required this.revenue,
    required this.netSales,
    required this.percentageChange,
    required this.chartData,
    required this.products,
    required this.orders,
    required this.allOrders,
    required this.totalOrderCount,
    required this.thisMonthOrderCount,
    required this.totalProductCount,
    required this.tabIndex,
    required this.tabDataCache,
  });
  
  @override
  List<Object?> get props => [
    revenue,
    netSales,
    percentageChange,
    chartData,
    products,
    orders,
    allOrders,
    totalOrderCount,
    thisMonthOrderCount,
    totalProductCount,
    tabIndex,
    totalOrders,
    tabDataCache,
  ];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  final int? tabIndex;
  const AnalyticsError(this.message, {this.tabIndex});
  @override
  List<Object?> get props => [message, tabIndex];
}

// Data structure to cache tab-specific data
class AnalyticsTabData extends Equatable {
  final double revenue;
  final double netSales;
  final double totalOrders;
  final double percentageChange;
  final List<FlSpot> chartData;
  final List<dynamic> products;
  final List<dynamic> orders;
  final DateTime lastUpdated;
  
  const AnalyticsTabData({
    required this.revenue,
    required this.netSales,
    required this.totalOrders,
    required this.percentageChange,
    required this.chartData,
    required this.products,
    required this.orders,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [
    revenue,
    netSales,
    totalOrders,
    percentageChange,
    chartData,
    products,
    orders,
    lastUpdated,
  ];
}
