import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sales_report_model.dart';
import '../models/revenue_period.dart';
import '../utils/nullable.dart'; // adjust path to wherever you put nullable.dart

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {
  final int tabIndex;
  final bool isRevenueOnly;
  const AnalyticsLoading({required this.tabIndex, this.isRevenueOnly = false});

  @override
  List<Object?> get props => [tabIndex, isRevenueOnly];
}

class AnalyticsLoaded extends AnalyticsState {
  final double revenue;
  final double netSales;
  final double totalOrders;
  final double percentageChange;
  final List<FlSpot> chartData;
  final List<dynamic> products;
  final List<dynamic> orders;
  final List<dynamic> allOrders;
  final int totalOrderCount;
  final int thisMonthOrderCount;
  // Total products in the catalog (shown on the profile stats row).
  final int totalProductCount;
  // Number of items sold today (store-local day), shown on the dashboard
  // "Products Sold" card.
  final int itemsSoldToday;
  final int tabIndex;
  final Map<int, AnalyticsTabData> tabDataCache;

  // Revenue report fields
  final SalesReportModel? revenueReport;
  final List<FlSpot>? reportChartSpots;
  final List<FlSpot>? reportOrderSpots;
  final List<String>? reportXLabels;
  final RevenuePeriod? selectedPeriod;

  // Dedicated flag so UI stays visible during revenue-only refresh
  final bool isRevenueLoading;

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
    required this.itemsSoldToday,
    required this.tabIndex,
    required this.tabDataCache,
    this.revenueReport,
    this.reportChartSpots,
    this.reportOrderSpots,
    this.reportXLabels,
    this.selectedPeriod,
    this.isRevenueLoading = false,
  });

  AnalyticsLoaded copyWith({
    double? revenue,
    double? netSales,
    double? totalOrders,
    double? percentageChange,
    List<FlSpot>? chartData,
    List<dynamic>? products,
    List<dynamic>? orders,
    List<dynamic>? allOrders,
    int? totalOrderCount,
    int? thisMonthOrderCount,
    int? totalProductCount,
    int? itemsSoldToday,
    int? tabIndex,
    Map<int, AnalyticsTabData>? tabDataCache,
    // Nullable<T> wrappers allow explicitly passing null to clear these fields
    Nullable<SalesReportModel?>? revenueReport,
    Nullable<List<FlSpot>?>? reportChartSpots,
    Nullable<List<FlSpot>?>? reportOrderSpots,
    Nullable<List<String>?>? reportXLabels,
    Nullable<RevenuePeriod?>? selectedPeriod,
    bool? isRevenueLoading,
  }) {
    return AnalyticsLoaded(
      totalOrders ?? this.totalOrders,
      revenue: revenue ?? this.revenue,
      netSales: netSales ?? this.netSales,
      percentageChange: percentageChange ?? this.percentageChange,
      chartData: chartData ?? this.chartData,
      products: products ?? this.products,
      orders: orders ?? this.orders,
      allOrders: allOrders ?? this.allOrders,
      totalOrderCount: totalOrderCount ?? this.totalOrderCount,
      thisMonthOrderCount: thisMonthOrderCount ?? this.thisMonthOrderCount,
      totalProductCount: totalProductCount ?? this.totalProductCount,
      itemsSoldToday: itemsSoldToday ?? this.itemsSoldToday,
      tabIndex: tabIndex ?? this.tabIndex,
      tabDataCache: tabDataCache ?? this.tabDataCache,
      revenueReport:
          revenueReport != null ? revenueReport.value : this.revenueReport,
      reportChartSpots:
          reportChartSpots != null
              ? reportChartSpots.value
              : this.reportChartSpots,
      reportOrderSpots:
          reportOrderSpots != null
              ? reportOrderSpots.value
              : this.reportOrderSpots,
      reportXLabels:
          reportXLabels != null ? reportXLabels.value : this.reportXLabels,
      selectedPeriod:
          selectedPeriod != null ? selectedPeriod.value : this.selectedPeriod,
      isRevenueLoading: isRevenueLoading ?? this.isRevenueLoading,
    );
  }

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
    itemsSoldToday,
    tabIndex,
    totalOrders,
    tabDataCache,
    revenueReport,
    reportChartSpots,
    reportOrderSpots,
    reportXLabels,
    selectedPeriod,
    isRevenueLoading,
  ];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  final int? tabIndex;
  const AnalyticsError(this.message, {this.tabIndex});
  @override
  List<Object?> get props => [message, tabIndex];
}

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
