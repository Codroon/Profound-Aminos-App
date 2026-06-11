import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/models/top_product_model.dart';
import 'product_performance_event.dart';

/// Holds the independent state of both cards on the product-performance page:
/// the chart (top) and the top-products ranking (bottom). Each has its own
/// period selector and loading flag so one can refresh without blanking the
/// other.
class ProductPerformanceState extends Equatable {
  // ── Chart card ────────────────────────────────────────────────────────────
  final ProductPeriod chartPeriod;
  final bool chartLoading;
  final int soldCount;
  final List<FlSpot> chartSpots;
  final List<String> chartLabels;
  final String? chartError;

  // ── Top-products card ─────────────────────────────────────────────────────
  final TopProductsPeriod topPeriod;
  final bool topLoading;
  final List<TopProductModel> topProducts;
  final String? topError;

  /// How many of [topProducts] are currently revealed. Grows by [topPageSize]
  /// each time the user taps "Load More".
  final int topVisibleCount;

  /// Page size for the "Load More" reveal.
  static const int topPageSize = 10;

  const ProductPerformanceState({
    this.chartPeriod = ProductPeriod.today,
    this.chartLoading = true,
    this.soldCount = 0,
    this.chartSpots = const [],
    this.chartLabels = const [],
    this.chartError,
    this.topPeriod = TopProductsPeriod.today,
    this.topLoading = true,
    this.topProducts = const [],
    this.topError,
    this.topVisibleCount = topPageSize,
  });

  ProductPerformanceState copyWith({
    ProductPeriod? chartPeriod,
    bool? chartLoading,
    int? soldCount,
    List<FlSpot>? chartSpots,
    List<String>? chartLabels,
    String? chartError,
    bool clearChartError = false,
    TopProductsPeriod? topPeriod,
    bool? topLoading,
    List<TopProductModel>? topProducts,
    String? topError,
    bool clearTopError = false,
    int? topVisibleCount,
  }) {
    return ProductPerformanceState(
      chartPeriod: chartPeriod ?? this.chartPeriod,
      chartLoading: chartLoading ?? this.chartLoading,
      soldCount: soldCount ?? this.soldCount,
      chartSpots: chartSpots ?? this.chartSpots,
      chartLabels: chartLabels ?? this.chartLabels,
      chartError: clearChartError ? null : (chartError ?? this.chartError),
      topPeriod: topPeriod ?? this.topPeriod,
      topLoading: topLoading ?? this.topLoading,
      topProducts: topProducts ?? this.topProducts,
      topError: clearTopError ? null : (topError ?? this.topError),
      topVisibleCount: topVisibleCount ?? this.topVisibleCount,
    );
  }

  @override
  List<Object?> get props => [
        chartPeriod,
        chartLoading,
        soldCount,
        chartSpots,
        chartLabels,
        chartError,
        topPeriod,
        topLoading,
        topProducts,
        topError,
        topVisibleCount,
      ];
}
